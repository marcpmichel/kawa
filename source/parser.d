module parser;

import statements;
import lexer;

class Parser {
	Lexer lexer;
	this() {
		lexer = new Lexer();
	}

    Statement[] parse(string program) {
        import std.stdio : writeln;
        lexer.tokenize(program);
        Statement[] statements;
        for(;;) {
            Statement stmt = parseStatement();
            if(stmt is null) break;
            if(cast(ErrorStatement)stmt !is null) { writeln(stmt.to_s); return []; }
            statements ~= stmt;
        }
        return statements;
    }

	bool expect(TokType type) {
		if(lexer.front.type == type) {
			lexer.popFront;
			return true;
		}
		return false;
	}
	
	bool check(Tok t, TokType type) {
		return t.type == type;
	}

	Statement parseStatement() {
		Tok t = lexer.front;

		while(t.type == TokType.EoL) { t = lexer.consume; }
        if(t.type == TokType.EoF) return null;

		if(t.type == TokType.Identifier) {
			Tok name = lexer.consume;
			Tok decl = lexer.consume;
			switch(decl.type) {
				case TokType.Colon: return parseVar(name, true);
				case TokType.Hash: return parseVar(name, false);
				case TokType.LBrace: return parsePod(name);
				default: return new ErrorStatement("expected var or const decl", lexer.front, lexer.curline);
			}
		}
		else {
            import std.stdio : writeln;
            writeln("got ", lexer.front.type );
			return new ErrorStatement("unknown statement", lexer.front, lexer.curline);
		}
	}

	Statement parseVar(Tok name, bool isVar) {
		Tok type = lexer.consume;
		//if(!check(type, TokType.Identifier)) return new ErrorStatement("expected type", lexer.front);
		if(!expect(TokType.Assign)) return new ErrorStatement("expected '='", lexer.front, lexer.curline);
		Tok value = lexer.consume;
		if(!check(value, TokType.Integer)) return new ErrorStatement("expected value", lexer.front, lexer.curline);
		if(isVar) {
			return new VarStatement(name, type, value);
		}
		else {
			return new ConstStatement(name, type, value);
		}
	}

	Statement parsePod(Tok name) {
		for(;;) {
			if(lexer.front.type == TokType.EoF) break;
			if(lexer.front.type == TokType.RBrace) { lexer.popFront; break; }
			lexer.popFront();
		}
		return new PodStatement(name);
	}

}

unittest {
	auto parser = new Parser();
	Statement[] statements = parser.parse("var x = 12");
	assert(statements.length == 1, "expected one statement");
}