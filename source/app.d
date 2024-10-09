module main;

import std.stdio;
import parser;
import statements;

/*
class Parser {
	Lexer lexer;
	this(Lexer lex) {
		lexer = lex;
	}
	bool match(TokType type) {
		if(lexer.front.type == type) {
			lexer.popFront;
			return true;
		}
		return false;
	}
	void advance() {
		lexer.popFront();
	}
	Tok consume() {
		Tok t = lexer.front;
		lexer.popFront();
		return t;
	}

	Statement parse() {
		Statement s = parseStatement();
		writeln(s.to_s);
		return s;
	}
	Statement parseStatement() {
		Tok t = lexer.front;
		if(match(TokType.Identifier)) {
			return parseDeclaration(t);
		}
		else {
			return new ErrorStatement("expected identifier", lexer.front);
		}
	}
	Statement parseDeclaration(Tok name) {
		Tok t = consume();
		switch(t.type) {
			case TokType.Colon: return parseVar(name, false); break;
			case TokType.Hash: return parseVar(name, true); break;
			case TokType.LBrace: return parsePod(name); break;
			case TokType.LessThan: return parseFunction(name); break;
			default: return parseError("unexpected token", lexer.front); break;
		}
	}
	Statement parseVar(Tok name, bool isConst) {
		Tok type = consume();
		if(!match(TokType.Assign)) return new ErrorStatement("expected assign", name);
		Tok value = consume();
		Statement s;
		s = cast(Statement)(isConst ? new ConstStatement(name, type, value) : new VarStatement(name, type, value));
		return s;
	}
	Statement parsePod(Tok name) {
		version(trace) { writeln("parsePod"); }
		// Tok value = lexer.front; lexer.popFront();
		while(!match(TokType.RBrace)) {
			if(lexer.front.type == TokType.EoF) return new ErrorStatement("reached EoF", lexer.front);
			if(lexer.front.type == TokType.Error) return new ErrorStatement("unknown token", lexer.front);
		}
		return new PodStatement(name);
	}
	Statement parseFunction(Tok name) {
		return new FunctionStatement(name);
	}
	Statement parseError(string msg, Tok name) {
		return new ErrorStatement(msg, name);
	}
}
*/

/*
Statements:
Statement = TypeDeclaration | VariableDeclaration | ExpressionStatement | PodDeclaration | FunctionDeclaration | HeapAllocation
ExpressionStatement = Expression
HeapAllocation = "@" TypeSpecifier

Declaration:
ConstantDeclaration = Identifier "#" TypeSpecifier "=" Expression
VariableDeclaration = Identifier ":" TypeSpecifier "=" AssignmentExpression
FunctionDeclaration = Identifier "<" "(" [Parameters] ")" ">" TypeSpecifier "{" { Statement } "}"
PodDeclaration =      Identifier "{" { VariableDeclaration } "}"

Expressions:
Expression = AssignmentExpression
AssignmentExpression = Identifier "=" Expression | ComparisonExpression
ComparisonExpression = ArithmeticExpression { ("==" | "!=") ArithmeticExpression }
ArithmeticExpression = Term { ("+" | "-") Term }
Term = Factor { ("*" | "/") Factor }
Factor = "(" Expression ")" | Identifier | Number | String
*/

string test_program = `x:int = 12
A # int = 1  
Person { age: int }
Vehicle { wheels: int }
`;

version(unittest) {
	// test runner
} else {
	void main() {
		auto parser = new Parser();
		Statement[] statements = parser.parse(test_program);

		foreach(s; statements) {
			writeln(s);
		}
	}
}


// vim: ts=4 sw=4
