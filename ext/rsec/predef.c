#include <stdlib.h>
#include <ruby.h>
#include <stdio.h>


// -----------------------------------------------------------------------------
// globals


static VALUE invalid;
static VALUE skip;
static ID ID_parse;

// -----------------------------------------------------------------------------
// predefined number parser


struct strscanner {
	unsigned long flags;
	VALUE str;
	long prev;
	long curr;
};

static int is_oct_or_hex(char* pointer) {
	if (pointer[0] == '0')\
		if (isdigit(pointer[1]) || pointer[1] == 'x' || pointer[1] == 'X')\
			return 1;
	return 0;
}

static VALUE call_parse(VALUE parser, VALUE ctx) {
	return rb_funcall2(parser, ID_parse, 1, &ctx);
}

// unsigned decimal / oct / hex
#define unsigned_default_filter \
	if (! isdigit(pointer[0])) return invalid;

// unsigned decimal
#define unsigned_decimal_filter \
	if (! isdigit(pointer[0])) return invalid;\
	if (is_oct_or_hex(pointer)) return invalid;

// signed decimal / oct /hex
#define default_filter \
	if (pointer[0] == '+' || pointer[0] == '-') {\
		if (!(isdigit(pointer[1]))) return invalid;\
	} else {\
		if (! isdigit(pointer[0])) return invalid;\
	}

// signed decimal
#define decimal_filter \
	if (pointer[0] == '+' || pointer[0] == '-') {\
		if (is_oct_or_hex(pointer + 1)) return invalid;\
	} else {\
		if (is_oct_or_hex(pointer)) return invalid;\
	}

// not start with space
#define minimal_filter \
	if (isspace(pointer[0])) return invalid;

#define DEFINE_PARSER(parser_name, res_type, parse_function, convert_macro, filter) \
	static VALUE parser_name(VALUE self, VALUE ctx) {\
		char* pointer;\
		char* tail;\
		struct strscanner* ss;\
		res_type res;\
		Data_Get_Struct(ctx, struct strscanner, ss);\
		pointer = RSTRING_PTR(ss->str) + ss->curr;\
		filter;\
		res = parse_function(pointer, &tail);\
		if (tail == pointer) {\
			return invalid;\
		} else {\
			ss->prev = ss->curr;\
			ss->curr += (tail - pointer);\
			return convert_macro(res);\
		}\
	}

// batch operations
#define DEFINE_PARSERS(name, res_type, parse_function, convert_macro) \
	DEFINE_PARSER(parse_##name, res_type, parse_function, convert_macro, default_filter)\
	DEFINE_PARSER(parse_decimal_##name, res_type, parse_function, convert_macro, decimal_filter)\
	DEFINE_PARSER(parse_unsigned_##name, res_type, parse_function, convert_macro, unsigned_default_filter)\
	DEFINE_PARSER(parse_unsigned_decimal_##name, res_type, parse_function, convert_macro, unsigned_decimal_filter)

// DEFINE_PARSERS(long_double, long double, strtold, DBL2NUM);
DEFINE_PARSERS(double, double, strtod, DBL2NUM);
DEFINE_PARSERS(float, float, strtof, DBL2NUM);

#undef DEFINE_PARSER
#undef DEFINE_PARSERS

#define DEFINE_PARSER(parser_name, res_type, parse_function, convert_macro, filter, base) \
	static VALUE parser_name(VALUE self, VALUE ctx) {\
		char* pointer;\
		char* tail;\
		struct strscanner* ss;\
		res_type res;\
		Data_Get_Struct(ctx, struct strscanner, ss);\
		pointer = RSTRING_PTR(ss->str) + ss->curr;\
		filter;\
		res = parse_function(pointer, &tail, base);\
		if (tail == pointer) {\
			return invalid;\
		} else {\
			ss->prev = ss->curr;\
			ss->curr += (tail - pointer);\
			return convert_macro(res);\
		}\
	}

DEFINE_PARSER(parse_int32, long,                        strtol,   INT2NUM,  minimal_filter, 10);
DEFINE_PARSER(parse_unsigned_int32, unsigned long,      strtoul,  UINT2NUM, minimal_filter, 10);
DEFINE_PARSER(parse_int64, long long,                   strtoll,  LL2NUM,   minimal_filter, 10);
DEFINE_PARSER(parse_unsigned_int64, unsigned long long, strtoull, ULL2NUM,  minimal_filter, 10);

#undef DEFINE_PARSER
#undef unsigned_default_filter
#undef unsigned_decimal_filter
#undef default_filter
#undef decimal_filter
#undef minimal_filter


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
	chr = RSTRING_PTR(ss->str)[0];
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


void Init_predef() {
	VALUE rsec = rb_define_module("Rsec");
	VALUE predef = rb_define_class_under(rsec, "Predef", rb_cObject);
	invalid = rb_const_get(rsec, rb_intern("INVALID"));
	skip = rb_const_get(rsec, rb_intern("SKIP"));
	ID_parse = rb_intern("_parse");
	rb_include_module(predef, rsec);

#	define DEFINE_PARSE_CLASSES(name, type_name) \
		rb_define_method(rb_define_class_under(rsec, name, predef), "_parse", parse_##type_name, 1);\
		rb_define_method(rb_define_class_under(rsec, "DECIMAL_" name, predef), "_parse", parse_decimal_##type_name, 1);\
		rb_define_method(rb_define_class_under(rsec, "UNSIGNED_" name, predef), "_parse", parse_unsigned_##type_name, 1);\
		rb_define_method(rb_define_class_under(rsec, "UNSIGNED_DECIMAL_" name, predef), "_parse", parse_unsigned_decimal_##type_name, 1);
	DEFINE_PARSE_CLASSES("DOUBLE", double);
	DEFINE_PARSE_CLASSES("FLOAT", float);
#	undef DEFINE_PARSE_CLASSES

#	define DEFINE_PARSE_CLASSES(name, type_name) \
		rb_define_method(rb_define_class_under(rsec, name, predef), "_parse", parse_##type_name, 1);\
		rb_define_method(rb_define_class_under(rsec, "UNSIGNED_" name, predef), "_parse", parse_unsigned_##type_name, 1);
	DEFINE_PARSE_CLASSES("INT32", int32);
	DEFINE_PARSE_CLASSES("INT64", int64);
#	undef DEFINE_PARSE_CLASSES

	// -----------------------------------------------------------------------------
	// redefine some parse methods

#	define REDEFINE(klass_name, method) \
	rb_define_method(rb_const_get(rsec, rb_intern(klass_name)), "_parse", method, 1)
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

