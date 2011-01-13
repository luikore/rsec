#include <stdlib.h>
#include <ruby.h>
#include <stdio.h>


// -----------------------------------------------------------------------------
// globals


static VALUE invalid;
static VALUE skip;
static ID ID_parse;

struct strscanner {
	unsigned long flags;
	VALUE str;
	long prev;
	long curr;
};

static VALUE call_parse(VALUE parser, VALUE ctx) {
	return rb_funcall2(parser, ID_parse, 1, &ctx);
}


// -----------------------------------------------------------------------------
// predefined number parser


static int is_hex(char* pointer) {
	if (pointer[0] == '0')
		if (pointer[1] == 'x' || pointer[1] == 'X')
			return 1;
	return 0;
}

#define DEFINE_PARSER(parser_name, res_type, float_parse_function, int_parse_function, convert_macro, is_floating) \
	static VALUE parser_name(VALUE self, VALUE ctx) {\
		char* pointer;\
		char* tail;\
		struct strscanner* ss;\
		char first_char;\
		VALUE* data = RSTRUCT_PTR(self);\
		int limit;\
		res_type res;\
		Data_Get_Struct(ctx, struct strscanner, ss);\
		limit = RSTRING_LEN(ss->str);\
		if (ss->curr >= limit) return invalid;\
		pointer = RSTRING_PTR(ss->str) + ss->curr;\
		first_char = pointer[0];\
		if (isspace(first_char)) return invalid;\
		switch(data[0]) {\
			case INT2FIX(0):\
				if (first_char == '+' || first_char == '-') return invalid;\
				break;\
			case INT2FIX(1):\
				if (first_char == '+') return invalid;\
				break;\
			case INT2FIX(2):\
				if (first_char == '-') return invalid;\
				break;\
		}\
		if (is_floating) {\
			char* hex_check_ptr = pointer;\
			if (first_char == '+' || first_char == '-') hex_check_ptr++;\
			if (data[1] == Qtrue) /* true: hex */ \
				if (! is_hex(hex_check_ptr))\
					return invalid;\
			if (data[1] == Qfalse) /* false: decimal */ \
				if (is_hex(hex_check_ptr))\
					return invalid;\
			res = float_parse_function(pointer, &tail);\
		} else {\
			res = int_parse_function(pointer, &tail, FIX2INT(data[1]));\
		}\
		if (tail == pointer) {\
			return invalid;\
		} else {\
			int distance = tail - pointer; /* tail points to the next char of the last char of the number */ \
			if (ss->curr + distance > limit) {\
				return invalid;\
			} else if (errno == ERANGE) { /* out of range error */ \
				return invalid;\
			} else {\
				ss->prev = ss->curr;\
				ss->curr += distance;\
				return convert_macro(res);\
			}\
		}\
	}

#define int_stub strtol
#define float_stub strtod

DEFINE_PARSER(parse_double, double, strtod, int_stub, DBL2NUM, 1);
DEFINE_PARSER(parse_float,  float,  strtof, int_stub, DBL2NUM, 1);
DEFINE_PARSER(parse_int32, long,                        float_stub, strtol,   INT2NUM,  0);
DEFINE_PARSER(parse_unsigned_int32, unsigned long,      float_stub, strtoul,  UINT2NUM, 0);
// VC has no strtoll / strtoull
// DEFINE_PARSER(parse_int64, long long,                   float_stub, strtoll,  LL2NUM,   0);
// DEFINE_PARSER(parse_unsigned_int64, unsigned long long, float_stub, strtoull, ULL2NUM,  0);

#undef int_stub
#undef float_stub

#undef DEFINE_PARSER


// -----------------------------------------------------------------------------
// change most used combinators _parse methods to C


static VALUE parse_seq(VALUE self, VALUE ctx) {
	VALUE* parsers = RARRAY_PTR(self);
	if (parsers) {
		int len = RARRAY_LEN(self);
		VALUE ret = rb_ary_new2(len);
		// VALUE args[] = {Qnil, ctx};
		int i;
		VALUE res;
		// We can't get benefit from loop unwinding -_-
		for (i = 0; i < len; i++) {
			// int error;
			// args[0] = parsers[i];
			// res = rb_protect(_wrap_parse, (VALUE)args, &error);
			// if (error) return Qnil; // let ruby handle error
			res = call_parse(parsers[i], ctx);
			if (res == invalid) return invalid;
			if (res != skip) rb_ary_push(ret, res);
		}
		return ret;
	} else {
		rb_raise(rb_eRuntimeError, "seq is not an array!");
	}
}

static VALUE parse_or(VALUE self, VALUE ctx) {
	VALUE* parsers = RARRAY_PTR(self);
	if (parsers) {
		int len = RARRAY_LEN(self);
		int i, curr, prev;
		struct strscanner* ss;
		Data_Get_Struct(ctx, struct strscanner, ss);
		curr = ss->curr;
		prev = ss->prev;
		for (i = 0; i < len; i++) {
			VALUE res = call_parse(parsers[i], ctx);
			if (res != invalid) return res;
			ss->curr = curr;
			ss->prev = prev;
		}
		return invalid;
	} else {
		rb_raise(rb_eRuntimeError, "or is not an array!");
	}
}


// -----------------------------------------------------------------------------
// fast string parser


static VALUE parse_string(VALUE self, VALUE ctx) {
	struct strscanner* ss;
	int i, len;
	char* s1; // pattern
	char* s2;
	Data_Get_Struct(ctx, struct strscanner, ss);
	VALUE pattern = RSTRUCT_PTR(self)[0]; // hack for self.some()
	len = RSTRING_LEN(pattern);
	if (ss->curr + len > RSTRING_LEN(ss->str))
		return invalid;
	s1 = RSTRING_PTR(pattern);
	s2 = RSTRING_PTR(ss->str) + ss->curr;
	for (i = 0; i < len; i++) {
		if (s1[i] != s2[i])
			return invalid;
	}
	ss->prev = ss->curr;
	ss->curr += len;
	return pattern; // self.some() is already frozen
}

static VALUE parse_skip_string(VALUE self, VALUE ctx) {
	struct strscanner* ss;
	int i, len;
	char* s1; // pattern
	char* s2;
	Data_Get_Struct(ctx, struct strscanner, ss);
	VALUE pattern = RSTRUCT_PTR(self)[0]; // hack for self.some()
	s1 = RSTRING_PTR(pattern);
	len = RSTRING_LEN(pattern);
	if (ss->curr + len > RSTRING_LEN(ss->str))
		return invalid;
	s2 = RSTRING_PTR(ss->str) + ss->curr;
	for (i = 0; i < len; i++) {
		if (s1[i] != s2[i])
			return invalid;
	}
	ss->prev = ss->curr;
	ss->curr += len;
	return skip;
}


// -----------------------------------------------------------------------------
// fast byte parsers


static VALUE parse_byte(VALUE self, VALUE ctx) {
	struct strscanner* ss;
	int i, len;
	VALUE chr;
	Data_Get_Struct(ctx, struct strscanner, ss);
	if (ss->curr >= RSTRING_LEN(ss->str))
		return invalid;
	chr = RSTRUCT_PTR(self)[0]; // hack for self.some(), chr is already frozen
	if (RSTRING_PTR(ss->str)[ss->curr] != RSTRING_PTR(chr)[0])
		return invalid;
	ss->prev = ss->curr;
	ss->curr ++;
	return chr;
}

static VALUE parse_skip_byte(VALUE self, VALUE ctx) {
	struct strscanner* ss;
	int i, len;
	VALUE chr;
	Data_Get_Struct(ctx, struct strscanner, ss);
	if (ss->curr >= RSTRING_LEN(ss->str))
		return invalid;
	chr = RSTRUCT_PTR(self)[0]; // hack for self.some(), chr is already frozen
	if (RSTRING_PTR(ss->str)[ss->curr] != RSTRING_PTR(chr)[0])
		return invalid;
	ss->prev = ss->curr;
	ss->curr ++;
	return skip;
}


// -----------------------------------------------------------------------------
// fast fall parsers


static VALUE parse_fall_left(VALUE self, VALUE ctx) {
	VALUE* data = RSTRUCT_PTR(self);
	VALUE ret = data[0]; // left
	ret = call_parse(ret, ctx);
	if (ret == invalid) return invalid;
	if (call_parse(data[1], ctx) == invalid) return invalid;
	return ret;
}

static VALUE parse_fall_right(VALUE self, VALUE ctx) {
	VALUE* data = RSTRUCT_PTR(self);
	VALUE left = data[0];
	if (call_parse(left, ctx) == invalid) return invalid;
	return call_parse(data[1], ctx);
}


// -----------------------------------------------------------------------------
// fast value parser


static VALUE parse_value(VALUE self, VALUE ctx) {
	return RSTRUCT_PTR(self)[0];
}


// -----------------------------------------------------------------------------
// mixing fall and value


static VALUE parse_fall_value(VALUE self, VALUE ctx) {
	VALUE* data = RSTRUCT_PTR(self);
	if (call_parse(data[0], ctx) != invalid)
		return data[1];
	return invalid;
}


// -----------------------------------------------------------------------------
// parens enchance


#define SKIP_SPACE(ptr) \
	for(;;) {\
		if (ss->curr >= limit) goto return_invalid;\
		if (! isspace(ptr[ss->curr])) break;\
		ss->curr ++;\
	}


static VALUE parse_wrap(VALUE self, VALUE ctx) {
	VALUE* data = RSTRUCT_PTR(self);
	struct strscanner* ss;
	char start = RSTRING_PTR(data[1])[0];
	char end = RSTRING_PTR(data[1])[1];
	VALUE res;
	char* ptr;
	int limit;
	int save_point;

	// prepare
	Data_Get_Struct(ctx, struct strscanner, ss);
	limit = RSTRING_LEN(ss->str);
	ptr = RSTRING_PTR(ss->str);
	save_point = ss->curr;

	// start
	if (ss->curr >= limit || ptr[ss->curr++] != start)
		goto return_invalid;
	// term
	res = call_parse(data[0], ctx);
	// end
	if (res == invalid || ptr[ss->curr++] != end)
		goto return_invalid;
	return res;

return_invalid:
	ss->curr = save_point;
	return invalid;
}

static VALUE parse_wrap_space(VALUE self, VALUE ctx) {
	VALUE* data = RSTRUCT_PTR(self);
	struct strscanner* ss;
	char start = RSTRING_PTR(data[1])[0];
	char end = RSTRING_PTR(data[1])[1];
	VALUE res;
	char* ptr;
	int limit;
	int save_point;

	// prepare
	Data_Get_Struct(ctx, struct strscanner, ss);
	limit = RSTRING_LEN(ss->str);
	ptr = RSTRING_PTR(ss->str);
	save_point = ss->curr;

	// start
	if (ss->curr >= limit || ptr[ss->curr++] != start)
		goto return_invalid;
	SKIP_SPACE(ptr);
	// term
	res = call_parse(data[0], ctx);
	if (res == invalid)
		goto return_invalid;
	SKIP_SPACE(ptr);
	// end
	if (ptr[ss->curr++] != end)
		goto return_invalid;
	return res;

return_invalid:
	ss->curr = save_point;
	return invalid;
}


// -----------------------------------------------------------------------------
// one of byte parser


static VALUE parse_one_of(VALUE self, VALUE ctx) {
	VALUE bytes = RSTRUCT_PTR(self)[0];
	char* ptr = RSTRING_PTR(bytes);
	int len = RSTRING_LEN(bytes);
	struct strscanner* ss;
	int limit, i;
	char chr;

	Data_Get_Struct(ctx, struct strscanner, ss);
	limit = RSTRING_LEN(ss->str);
	if (ss->curr >= limit) return invalid;
	chr = RSTRING_PTR(ss->str)[ss->curr];
	for (i = 0; i < len; i++) {
		if (chr == ptr[i]) {
			ss->curr ++;
			char ret[1] = { chr };
			return rb_str_new(ret, 1);
		}
	}
	return invalid;
}

static VALUE parse_spaced_one_of(VALUE self, VALUE ctx) {
	VALUE bytes = RSTRUCT_PTR(self)[0];
	char* bytes_ptr = RSTRING_PTR(bytes);
	int len = RSTRING_LEN(bytes);
	struct strscanner* ss;
	int limit, i;
	char chr;
	int save_point;
	char* ptr;

	Data_Get_Struct(ctx, struct strscanner, ss);
	limit = RSTRING_LEN(ss->str);
	ptr = RSTRING_PTR(ss->str);
	save_point = ss->curr;

	SKIP_SPACE(ptr);
	chr = ptr[ss->curr];
	for (i = 0; i < len; i++) {
		if (chr == bytes_ptr[i]) {
			ss->curr ++;
			// space
			for (;;) {
				if (ss->curr >= limit) break; // still valid
				if (! isspace(ptr[ss->curr])) break;
				ss->curr ++;
			}
			char ret[1] = { chr };
			return rb_str_new(ret, 1);
		}
	}

return_invalid:
	ss->curr = save_point;
	return invalid;
}


#undef SKIP_SPACE


// -----------------------------------------------------------------------------
// faster join parser


VALUE parse_join(VALUE self, VALUE ctx) {
	VALUE token = rb_iv_get(self, "@token");
	VALUE inter = rb_iv_get(self, "@inter");
	struct strscanner* ss;
	VALUE i, t, node;
	int save_point;

	// pure translation of ruby code
	t = call_parse(token, ctx);
	if (t == invalid) return t;
	node = rb_ary_new();
	if (t != skip) rb_ary_push(node, t);

	Data_Get_Struct(ctx, struct strscanner, ss);
	for(;;) {
		save_point = ss->curr;
		i = call_parse(inter, ctx);
		if (i == invalid) {
			ss->curr = save_point;
			break;
		}
		t = call_parse(token, ctx);
		if (t == invalid) {
			ss->curr = save_point;
			break;
		}
		if (save_point == ss->curr) break;
		if (i != skip) rb_ary_push(node, i);
		if (t != skip) rb_ary_push(node, t);
	}
	return node;
}


// -----------------------------------------------------------------------------
// faster map parser


VALUE parse_map(VALUE self, VALUE ctx) {
	VALUE* data = RSTRUCT_PTR(self);
	VALUE res = call_parse(data[0], ctx);
	if (res == invalid) return res;
	return rb_proc_call(data[1], rb_ary_new3(1, res));
}


// -----------------------------------------------------------------------------
// init

#ifdef __cplusplus
extern "C"
#endif
void
#ifdef _WIN32
__declspec(dllexport)
#endif
Init_predef() {
	VALUE rsec = rb_define_module("Rsec");
	VALUE predef = rb_define_class_under(rsec, "Predef", rb_cObject);
	invalid = rb_const_get(rsec, rb_intern("INVALID"));
	skip = rb_const_get(rsec, rb_intern("SKIP"));
	ID_parse = rb_intern("_parse");
	rb_include_module(predef, rsec);

	// -----------------------------------------------------------------------------
	// redefine parse methods

#	define REDEFINE(klass_name, method) \
	rb_define_method(rb_const_get(rsec, rb_intern(klass_name)), "_parse", method, 1)

	REDEFINE("PDouble", parse_double);
	REDEFINE("PFloat", parse_float);
	REDEFINE("PInt32", parse_int32);
	// REDEFINE("PInt64", parse_int64);
	REDEFINE("PUnsignedInt32", parse_unsigned_int32);
	// REDEFINE("PUnsignedInt64", parse_unsigned_int64);

	REDEFINE("Seq", parse_seq);
	REDEFINE("Or", parse_or);
	REDEFINE("FixString", parse_string);
	REDEFINE("Byte", parse_byte);
	REDEFINE("SkipFixString", parse_skip_string);
	REDEFINE("SkipByte", parse_skip_byte);
	REDEFINE("FallLeft", parse_fall_left);
	REDEFINE("FallRight", parse_fall_right);
	REDEFINE("Value", parse_value);
	REDEFINE("FallValue", parse_fall_value);
	REDEFINE("Wrap", parse_wrap);
	REDEFINE("WrapSpace", parse_wrap_space);
	REDEFINE("OneOf", parse_one_of);
	REDEFINE("SpacedOneOf", parse_spaced_one_of);
	REDEFINE("Join", parse_join);
	REDEFINE("Map", parse_map);

#	undef REDEFINE
}

