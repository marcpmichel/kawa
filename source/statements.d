module statements;

import tokens;
import std.conv : to;
import std.format: format;

enum TypeKind { Error, Auto, Decl }
struct Type {
    TypeKind kind;
    string literal;
}

alias ArgumentList = Argument[];
alias StatementList = Statement[];

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
		string block = "{ ";
		foreach(s; statements) {
			block ~= s.to_c();
		}
		block ~= " }";
		return block;
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
		return otherwise is null ? format("[IfStatement] if (%s) %s", cond, then) : format("[IfStatement] if(%s) %s else %s", cond, then, otherwise);
	}
	override string to_c() {
		return otherwise is null ? 
			format("if(%s) %s", cond, then) : 
			format("if(%s) %s else %s", cond, then, otherwise);
	}
}

class WhileStatement: Statement {
	Expression cond;
	Statement block;
	this(Expression cond, Statement block) {
		this.cond = cond;
		this.block = block;
	}
	override string toString() {
		return format("[whileStatement] while(%s) { %s}", cond, block);
	}
	override string to_c() {
		return format("while(%s) %s", cond, block);
	}
}

class Argument: Statement {
	Tok id;
	Type type;
	this(Tok id, Type type) {
		this.id = id;
		this.type = type;
	}
	override string toString() {
		return format("%s : %s", id.s, type);
	}
	override string to_c() {
		return format("%s %s", type, id.s);
	}
}


class FunctionDeclaration: Statement {
	Tok name;
	Type type;
	ArgumentList list;
	Statement block;
	this(Tok name, Type type, ArgumentList list, Statement block) {
		this.name = name;
		this.type = type;
		this.list = list;
		this.block = block;
	}
	override string toString() {
		return format("[FunctionDeclaration] fun %s (%s) : %s { %s }", name.s, list, type, block);
	}
	override string to_c() {
		return format("%s %s(%s) %s", type, name, list, block);
	}
}

class ReturnStatement : Statement {
	Expression e;
	this(Expression exp) {
		this.e = exp;
	}
	override string toString() {
		return format("return %s", e);
	}
	override string to_c() {
		return toString();
	}
}

class PodStatement: Statement {
	Tok name;
	Statement[] declarations;
	this(Tok name, Statement[] declarations) {
		this.name = name;
		this.declarations = declarations;
	}
	override string toString() {
		string decl;
		foreach(d; declarations) { decl ~= d.toString(); }
		return "pod "~ name.s ~"{ " ~ decl ~ " }";
	}
	string to_c() {
		return "typedef struct { ... } " ~ name.s;
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
    override string toString() {
        return "<empty expression>";
    }
    override string to_c() {
        return "/*empty exp*/";
    }
}

class CallExpression: Expression {
	string id;
	ExpressionList list;
	this(Tok tok, ExpressionList list) {
		id = tok.s;
		this.list = list;
	}
	override string toString() {  return format("%s(%s)", id, list); }
	override string to_c() { return format("%s(%s)", id, list); }
}

class ExpressionList : Expression {
	Expression[] expressions;
	void add(Expression e) {
		expressions ~= e;
	}
	override string toString() { 
		import std.algorithm;
		import std.array;
		return expressions.map!(a => a.toString).join(", ");
	}
	override string to_c() {
		import std.algorithm;
		import std.array;
		return expressions.map!(a => a.to_c).join(", ");
	}
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
  override string to_c() {
		return "/* literal expression */";
  }
}

class IntegerLiteral: Expression {
	int value;
	this(Tok t) {
		value = t.i;
	}
	override string toString() { return format("%d", value); }
	override string to_c() { return format("%d", value); }
}

class FloatLiteral: Expression {
	float value;
	this(Tok t) {
		value = t.f;
	}
	override string toString() { return format("%f", value); }
	override string to_c() { return format("%f", value); }
}

class StringLiteral: Expression {
	string value;
	this(Tok t) {
		value = t.s;
	}
	override string toString() { return format("%s", value); }
	override string to_c() { return format("%s", value); }
}

class ConstantLiteral: Expression {
	// LiteralConstant lit;
	Tok lit;
	this(Tok t) {
		lit = t;
	}
	override string toString() { return format("%s", lit.s); }
	override string to_c() { return format("%s", lit.s); }
}

class IdentifierExpression: Expression {
    Tok id;
    this(Tok ident) {
        this.id = ident;
    }
    override string toString() { return id.s; }
    override string to_c() { return id.s; }
}

class UnaryExpression : Expression {
	Tok op;
	Expression e;
	this(Tok operator, Expression expression) {
		op = operator;
		e = expression;
	}
	override string toString() { return format("[UnExp] %s(%s)", op.s, e); }
	override string to_c() { return format("%s%s", op.s, e); }
}

class BinaryExpression: Expression {
    Tok op;
    Expression left, right;
    this(Tok operator, Expression e, Expression e2) {
        op = operator;
        left = e;
        right = e2;
    }
    override string toString() { return format("[BinExp] (%s) %s (%s)", left, op.s, right); }
    override string to_c() { return format("%s %s %s", left, op.s, right); }
}

class AssignmentExpression: Expression {
    Tok op;
    Expression left, right;
    this(Tok operator, Expression e, Expression e2) {
        op = operator;
        left = e;
        right = e2;
    }
    override string toString() { return format("[AssignmentExp] %s %s %s", left, op.s, right); }
    override string to_c() { return format("%s %s %s", left, op.s, right); }
}

class ConditionExpression: Expression {
	Tok op;
	Expression left, right;
	this(Tok operator, Expression e, Expression e2) {
		op = operator;
		left = e;
		right = e2;
	}
	override string toString() { return format("[ConditionExpression] (%s) %s (%s)", left, op.s, right); }
	override string to_c() { return format("(%s) %s (%s)", left, op.s, right); }
}

