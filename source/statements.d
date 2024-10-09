module statements;

import tokens;
import std.conv;

interface Statement {
	string to_s();
	string to_c();
}

class VoidStatement: Statement {
	string to_s() {
		return "void";
	}
	string to_c() {
		return "void";
	}
}
class ErrorStatement: Statement {
    import std.format : format;
    import std.string : rightJustify;
	Tok tok;
	string msg;
	this(string msg, Tok t, string curline="") {
        string context;
        if(curline.length > 0) { context = "\n" ~ curline ~ "\n" ~ rightJustify("^", t.col, ' '); }
		this.msg = format("ParseError: (%d:%d) : %s, got %s %s", t.line, t.col, msg, t.type, context);
		this.tok = t;
	}
	string to_s() {
		return msg;
	}
	string to_c() {
		return "parse error";
	}
}

class VarStatement: Statement {
	Tok name, type, value;
	this(Tok name, Tok type, Tok value) {
		this.name = name;
		this.type = type;
		this.value = value;
	}
	string to_s() {
		return "var " ~ name.s ~ " = " ~ value.s;
	}
	string to_c() {
		return "type " ~ name.s ~ " = " ~ value.s;
	}
}
class ConstStatement: Statement {
	Tok name, type, value;
	this(Tok name, Tok type, Tok value) {
		this.name = name;
		this.type = type;
		this.value = value;
	}
	string to_s() {
		return "const " ~ name.s ~ " = " ~ value.s;
	}
	string to_c() {
		return "type " ~ name.s ~ " = " ~ value.s;
	}
}
class PodStatement: Statement {
	Tok name;
	this(Tok name) {
		this.name = name;
	}
	string to_s() {
		return "pod "~ name.s ~"{ ... }";
	}
	string to_c() {
		return "typedef struct { ... } " ~ name.s;
	}
}
class FunctionStatement: Statement {
	Tok name;
	this(Tok name) {
		this.name = name;
	}
	string to_s() {
		return "fun " ~ name.s ~ "() {}";
	}
	string to_c() {
		return "type " ~ name.s ~ "() {}";
	}
}

