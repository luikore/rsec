#include <stdlib.h>
#include <ruby.h>
#include <stdio.h>

#ifndef _WIN32
#	include <errno.h>
#endif

// -----------------------------------------------------------------------------
// globals


static VALUE invalid;
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

// stubs for unified macro
#define int_stub strtol
#define float_stub strtod

DEFINE_PARSER(parse_double, double, strtod, int_stub, DBL2NUM, 1);
// XXX it is hard for pure ruby to determine single precision
DEFINE_PARSER(parse_int32, long,                        float_stub, strtol,   INT2NUM,  0);
DEFINE_PARSER(parse_unsigned_int32, unsigned long,      float_stub, strtoul,  UINT2NUM, 0);
// XXX VC has no strtoll / strtoull

#undef int_stub
#undef float_stub

#undef DEFINE_PARSER


// -----------------------------------------------------------------------------
// change most used combinators _parse methods to C


static VALUE parse_seq(VALUE self, VALUE ctx) {
	VALUE arr = RSTRUCT_PTR(self)[0];
	VALUE* parsers = RARRAY_PTR(arr);
	int len = RARRAY_LEN(arr);
	volatile VALUE ret = rb_ary_new2(len);
	int i;
	volatile VALUE res = 0;

	// We can't benefit from loop unwinding -_-
	for (i = 0; i < len; i++) {
		res = call_parse(parsers[i], ctx);
		if (res == invalid) return invalid;
		rb_ary_push(ret, res);
	}
	return ret;
}

static VALUE parse_seq_one(VALUE self, VALUE ctx) {
	VALUE arr = RSTRUCT_PTR(self)[0];
	int idx = NUM2INT(RSTRUCT_PTR(self)[1]);
	VALUE* parsers = RARRAY_PTR(arr);
	int len = RARRAY_LEN(arr);
	VALUE ret = invalid;
	volatile VALUE res = 0;
	int i;

	// We can't benefit from loop unwinding -_-
	for (i = 0; i < len; i++) {
		res = call_parse(parsers[i], ctx);
		if (res == invalid) return invalid;
		if (i == idx) ret = res;
	}
	return ret;
}

static VALUE parse_seq_(VALUE self, VALUE ctx) {
	VALUE* struct_ptr = RSTRUCT_PTR(self);
	VALUE first = struct_ptr[0];
	volatile VALUE res = call_parse(first, ctx);
	if (res == invalid) {
		return invalid;
	} else {
		VALUE* rest = RARRAY_PTR(struct_ptr[1]);
		VALUE skipper = struct_ptr[2];
		int len = RARRAY_LEN(struct_ptr[1]);
		volatile VALUE ret = rb_ary_new2(len + 1);
		int i;

		rb_ary_push(ret, res);
		for (i = 0; i < len; i++) {
			res = call_parse(skipper, ctx);
			if (res == invalid) return invalid;
			res = call_parse(rest[i], ctx);
			if (res == invalid) return invalid;
			rb_ary_push(ret, res);
		}
		return ret;
	}
}

static VALUE parse_seq_one_(VALUE self, VALUE ctx) {
	VALUE* struct_ptr = RSTRUCT_PTR(self);
	VALUE first = struct_ptr[0];
	volatile VALUE res = call_parse(first, ctx);
	volatile VALUE ret = 0;
	if (res == invalid) {
		return invalid;
	} else {
		VALUE* rest = RARRAY_PTR(struct_ptr[1]);
		VALUE skipper = struct_ptr[2];
		int idx = NUM2INT(struct_ptr[3]);
		int len = RARRAY_LEN(struct_ptr[1]);
		int i;

		if (0 == idx) ret = res;
		idx--;
		for (i = 0; i < len; i++) {
			res = call_parse(skipper, ctx);
			if (res == invalid) return invalid;
			res = call_parse(rest[i], ctx);
			if (res == invalid) return invalid;
			if (i == idx) ret = res;
		}
		return ret;
	}
}

static VALUE parse_branch(VALUE self, VALUE ctx) {
	VALUE arr = RSTRUCT_PTR(self)[0];
	VALUE* parsers = RARRAY_PTR(arr);
	if (parsers) {
		int len = RARRAY_LEN(arr);
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


static VALUE parse_fix_string(VALUE self, VALUE ctx) {
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

static VALUE parse_one_of_byte(VALUE self, VALUE ctx) {
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

static VALUE parse_one_of_byte_(VALUE self, VALUE ctx) {
	VALUE bytes = RSTRUCT_PTR(self)[0];
	char* bytes_ptr = RSTRING_PTR(bytes);
	int len = RSTRING_LEN(bytes);
	struct strscanner* ss;
	int limit, i;
	char chr;
	char* ptr;

	Data_Get_Struct(ctx, struct strscanner, ss);
	limit = RSTRING_LEN(ss->str);
	ptr = RSTRING_PTR(ss->str);

	// skip space
	for(;;) {
		// it is sure invalid because char cannot be epsilon
		if (ss->curr >= limit) return invalid;
		if (! isspace(ptr[ss->curr])) break;
		ss->curr ++;
	}
	chr = ptr[ss->curr];
	for (i = 0; i < len; i++) {
		if (chr == bytes_ptr[i]) {
			ss->curr ++;
			// skip space
			for (;;) {
				if (ss->curr >= limit) break; // still valid
				if (! isspace(ptr[ss->curr])) break;
				ss->curr ++;
			}
			char ret[1] = { chr };
			return rb_str_new(ret, 1);
		}
	}
	return invalid;
}


// -----------------------------------------------------------------------------
// other


// keep =
//   1: keep inter only
//   2: keep token only
//   3: keep both
static VALUE proto_parse_join(VALUE self, VALUE ctx, int keep) {
	VALUE token = RSTRUCT_PTR(self)[0];
	VALUE inter = RSTRUCT_PTR(self)[1];
	struct strscanner* ss;
	volatile VALUE i = 0;
	volatile VALUE t = 0;
	volatile VALUE node = 0; // result
	int save_point;

	// pure translation of ruby code
	t = call_parse(token, ctx);
	if (t == invalid) return t;
	node = rb_ary_new();
	if (keep & 2)
		rb_ary_push(node, t);

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
		if (keep & 1) rb_ary_push(node, i);
		if (keep & 2) rb_ary_push(node, t);
	}
	return node;
}

static VALUE parse_join(VALUE self, VALUE ctx) {
	return proto_parse_join(self, ctx, 3);
}

static VALUE parse_join_even(VALUE self, VALUE ctx) {
	return proto_parse_join(self, ctx, 2);
}

static VALUE parse_join_odd(VALUE self, VALUE ctx) {
	return proto_parse_join(self, ctx, 1);
}

static VALUE parse_map(VALUE self, VALUE ctx) {
	VALUE* data = RSTRUCT_PTR(self);
	VALUE res = call_parse(data[0], ctx);
	if (res == invalid) return res;
	return rb_proc_call(data[1], rb_ary_new3(1, res));
}

// function like ParseContext.on_fail, but don't re-define it
static VALUE parse_context_on_fail(VALUE self, VALUE mask) {
	struct strscanner* ss = 0;
	Data_Get_Struct(self, struct strscanner, ss);
	if (ss) {
		int pos = ss->curr;
		int last_fail_pos = NUM2INT(rb_ivar_get(self, rb_intern("@last_fail_pos")));
		if (pos > last_fail_pos) {
			volatile VALUE new_fail_pos = INT2NUM(pos);
			rb_ivar_set(self, rb_intern("@last_fail_pos"), INT2NUM(pos));
			rb_ivar_set(self, rb_intern("@last_fail_mask"), mask);
		} else if (pos == last_fail_pos) {
			volatile VALUE last_fail_mask = rb_ivar_get(self, rb_intern("@last_fail_mask"));
			last_fail_mask = rb_funcall(last_fail_mask, rb_intern("|"), 1, mask);
			rb_ivar_set(self, rb_intern("@last_fail_mask"), last_fail_mask);
		}
	}
	return Qnil;
}

static VALUE parse_fail(VALUE self, VALUE ctx) {
	VALUE left = RSTRUCT_PTR(self)[0];
	VALUE right = RSTRUCT_PTR(self)[1];
	volatile VALUE res = call_parse(left, ctx);
	if (res == invalid) {
		parse_context_on_fail(ctx, right);
	}
	return res;
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
	ID_parse = rb_intern("_parse");
	rb_include_module(predef, rsec);

	// -----------------------------------------------------------------------------
	// redefine parse methods

#	define REDEFINE(klass_name, method) \
	rb_define_method(rb_const_get(rsec, rb_intern(klass_name)), "_parse", method, 1)

	REDEFINE("PDouble", parse_double);
	// REDEFINE("PFloat", parse_float);
	REDEFINE("PInt32", parse_int32);
	// REDEFINE("PInt64", parse_int64);
	REDEFINE("PUnsignedInt32", parse_unsigned_int32);
	// REDEFINE("PUnsignedInt64", parse_unsigned_int64);

	REDEFINE("Seq", parse_seq);
	REDEFINE("Seq_", parse_seq_);
	REDEFINE("SeqOne", parse_seq_one);
	REDEFINE("SeqOne_", parse_seq_one_);
	REDEFINE("Branch", parse_branch);

	REDEFINE("FixString", parse_fix_string);
	REDEFINE("OneOfByte", parse_one_of_byte);
	REDEFINE("OneOfByte_", parse_one_of_byte_);

	REDEFINE("Join", parse_join);
	REDEFINE("JoinEven", parse_join_even);
	REDEFINE("JoinOdd", parse_join_odd);
	REDEFINE("Map", parse_map);
	REDEFINE("Fail", parse_fail);

#	undef REDEFINE
}

