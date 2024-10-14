module statements;

import tokens;
import std.conv : to;
import std.format: format;

enum TypeKind { Error, Auto, Decl }
struct Type {
    TypeKind kind;
    string literal;
}

interface Statement {
	string toString();
	string to_c();
}

class VoidStatement: Statement {
	override string toString() {
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
        if(curline.length > 0) { context = "\n" ~ curline ~ "\n" ~ rightJustify("^", t.col+1, '.'); }
		this.msg = format("ParseError: (%d:%d) : %s, got %s %s", t.line, t.col, msg, t.type, context);
		this.tok = t;
	}
	override string toString() {
		return msg;
	}
	string to_c() {
		return msg;
	}
}

class VarStatement: Statement {
	Tok name;
    Type type;
    Expression exp;
	this(Tok name, Type type, Expression exp) {
		this.name = name;
		this.type = type;
		this.exp = exp;
	}
	override string toString() {
		return format("[VarStatement] var %s : %s = %s", name.s, type.literal, exp);
	}
	string to_c() {
		return format("%s %s = %s ", type.literal, name.s, exp);
	}
}
class ConstStatement: Statement {
	Tok name, type, value;
	this(Tok name, Tok type, Tok value) {
		this.name = name;
		this.type = type;
		this.value = value;
	}
	override string toString() {
		return "const " ~ name.s ~ " = " ~ value.s;
	}
	string to_c() {
		return "type " ~ name.s ~ " = " ~ value.s;
	}
}

class BlockStatement: Statement {
	Statement[] statements;
	this(Statement[] statements) {
		this.statements = statements;
	}
	override string toString() {
		string block = "[BlockStatement] { ";
		foreach(s; statements) {
			block ~= s.toString();
		}
		block ~= " }";
		return block;
	}
	override string to_c() {
		return toString();
	}
}

class IfStatement: Statement {
	Expression cond;
	Statement then;
	Statement otherwise;
	this(Expression cond, Statement then, Statement otherwise) {
		this.cond = cond;
		this.then = then;
		this.otherwise = otherwise;
	}
	override string toString() {
		return otherwise is null ? format("[IfStatement] if (%s) %s", cond, then) : format("if(%s) %s else %s", cond, then, otherwise);
	}
	override string to_c() {
		return toString();
	}
}

class PodStatement: Statement {
	Tok name;
	this(Tok name) {
		this.name = name;
	}
	override string toString() {
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
	override string toString() {
		return "fun " ~ name.s ~ "() {}";
	}
	string to_c() {
		return "type " ~ name.s ~ "() {}";
	}
}

class Expression: Statement {
    override string toString() {
        return "<expression>";
    }
    string to_c() {
        return "<expression>";
    }
}

class EmptyExpression : Expression {
}

class LiteralExpression: Expression {
    Tok value;
    this(Tok value) {
        this.value = value;
    }
    override string toString() {
        switch(value.type) {
            case TokType.Integer: return value.s;
            case TokType.String: return format("\"%s\"", value.s);
            default: return format("<%s>", value.s);
        }
    }
}

class IdentifierExpression: Expression {
    Tok id;
    this(Tok ident) {
        this.id = ident;
    }
    override string toString() {
        return id.s;
    }
}

class UnaryExpression : Expression {
	Tok op;
	Expression e;
	this(Tok operator, Expression expression) {
		op = operator;
		e = expression;
	}
	override string toString() {
		return format("[UnExp] %s(%s)", op.s, e);
	}
}

class BinaryExpression: Expression {
    Tok op;
    Expression left, right;
    this(Tok operator, Expression e, Expression e2) {
        op = operator;
        left = e;
        right = e2;
    }
    override string toString() {
        return format("[BinExp] (%s) %s (%s)", left, op.s, right);
    }
}

class AssignmentExpression: Expression {
    Tok op;
    Expression left, right;
    this(Tok operator, Expression e, Expression e2) {
        op = operator;
        left = e;
        right = e2;
    }
    override string toString() {
        return format("[AssignmentExp] %s %s %s", left, op.s, right);
    }
}

class ConditionExpression: Expression {
	Tok op;
	Expression left, right;
	this(Tok operator, Expression e, Expression e2) {
		op = operator;
		left = e;
		right = e2;
	}
	override string toString() {
		return format("[ConditionExpression] (%s) %s (%s)", left, op.s, right);
	}
}