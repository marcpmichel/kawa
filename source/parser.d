module parser;

import statements;
import lexer;

struct ParseError {
    string message;
    Tok token;
}

class Parser {
	Lexer lexer;
    bool has_errored;
    ParseError error;

	this() {
		lexer = new Lexer();
	}

    Statement[] parse(string program) {
        lexer.tokenize(program);
        Statement[] statements;
        for(;;) {
            Statement stmt = parseStatement();
            if(stmt is null) break;
            if(cast(ErrorStatement)stmt !is null) { printError(cast(ErrorStatement)stmt); return []; }
            statements ~= stmt;
            if(lexer.frontIs(TokType.EoF)) break;
            if(!expect(TokType.EoL)) { printError(parseError("expected EoL")); return []; }
        }
        return statements;
    }

    ErrorStatement parseError(string msg, Tok token=Tok(TokType.Error)) {
        Tok t = token.type == TokType.Error ? lexer.front : token;
        this.has_errored = true;
        this.error = ParseError(msg, t);
        return new ErrorStatement(msg, t, lexer.curline);
    }

    void printError(ErrorStatement stmt) {
        import std.stdio : writeln;
        writeln(stmt);
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
        if(t.type == TokType.EoF) return null;

        switch(lexer.front.type) {
            case TokType.Keyword:
                lexer.consume(); // var
                switch(t.k) {
                    case Keyword.Var: return parseVar();
                    default: return parseError("unexpected keyword");
                }
            break;
            case TokType.Identifier:
                return parseAssignment();
            break;
            default:
                return parseError("syntax error");
            break;
        }

        return new VoidStatement();
	}

    Type parseType() {
        Tok t = lexer.consume();
        switch(t.type) {
            case TokType.Keyword: 
                if(t.k != Keyword.Auto) return Type(TypeKind.Error, "type bug");
                return Type(TypeKind.Auto);
            break;
            case TokType.Identifier:
                return Type(TypeKind.Decl, t.s);
            break;
            default: 
                return Type(TypeKind.Error, "bad type");
        }
    }

    Statement parseVar() {
        Tok name = lexer.consume();
        if(!check(name, TokType.Identifier)) return parseError("expected identifier", name);

        Type type;
        if(lexer.frontIs(TokType.Colon)) {
            Tok colon = lexer.consume();
            type = parseType(); // lexer.consume();
            if(type.kind == TypeKind.Error) return parseError("bad type qualifier", colon);
        }
        else {
            type = Type(TypeKind.Auto, "auto");
        }

        if(lexer.frontIs(TokType.Assign)) {
            lexer.popFront();
            // parse Expression;
            Expression e = parseExpression();
            // Tok value = lexer.consume();
            return new VarStatement(name, type, e);
        }
        else {
            return new VarStatement(name, type, new EmptyExpression());
        }
    }

    Expression parseAssignment() {
        Expression e = parseIdentifier();
        if(typeid(e) != typeid(IdentifierExpression)) {
            return cast(Expression)parseError("invalid left-hand size for assignment");
        }
        Tok op = lexer.consume(); // TODO: add +=, -=, *=, /=, %=, ++, -- 
        // Note: x++ => x += 1 => x = x + 1
        if(op.type != TokType.Assign) return cast(Expression)parseError("expected assignment operator");

        Expression e2 = parseExpression();
        // import std.stdio: writeln; writeln(e2);
        return new AssignmentExpression(op, e, e2);
    }

    Expression parseExpression() {
        Expression e = parseTerm();
        return e;
    }

    Expression parseTerm() {
        Expression e = parseFactor();
        while(lexer.frontIs(TokType.Add) || lexer.frontIs(TokType.Sub)) {
            Tok op = lexer.consume();
            Expression e2 = parseFactor();
            e = new BinaryExpression(op, e, e2);
        }
        return e;
    }

    Expression parseFactor() {
        Expression e = parsePrimary();
        while(lexer.frontIs(TokType.Mul) || lexer.frontIs(TokType.Div)) {
            Tok op = lexer.consume();
            Expression e2 = parsePrimary();
            e = new BinaryExpression(op, e, e2);
        }
        return e;
    }


    Expression parsePrimary() {
        switch(lexer.front.type) {
            case TokType.LParen: return parseParenExpression();
            case TokType.Identifier: return parseIdentifier();
            case TokType.String:
            case TokType.Integer: return parseLiteral();
            default: return cast(Expression)parseError("cannot parse primary expression");
        }
        assert(0);
    }

    Expression parseParenExpression() {
        lexer.consume(); // (
        Expression e = parseExpression();
        if(!expect(TokType.RParen)) return cast(Expression)parseError("expected ')'");
        return e;
    }
    
    Expression parseIdentifier() {
        Tok id = lexer.consume();
        return new IdentifierExpression(id);
    }

    Expression parseLiteral() {
        Tok lit = lexer.consume();
        return new LiteralExpression(lit);
    }

    /*
	Statement parseDecl(Tok name, bool isVar) {
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
    */

	Statement parsePod(Tok name) {
		for(;;) {
			if(lexer.front.type == TokType.EoF) break;
			if(lexer.front.type == TokType.RBrace) { lexer.popFront; break; }
			lexer.popFront();
		}
		return new PodStatement(name);
	}

}

@("simple expression") unittest {
    auto parser = new Parser();
    Statement[] ss = parser.parse("var x : auto = 1 + 2");
    assert(ss.length == 1);
}

@("var statement") unittest {
	auto parser = new Parser();
	Statement[] statements = parser.parse("var x = 12");
	assert(statements.length == 1, "expected one statement");
    assert(cast(VarStatement)statements[0] !is null);
    auto stmt = cast(VarStatement)statements[0];
    assert(cast(LiteralExpression)stmt.exp !is null, "not a literal exp");
    auto exp = cast(LiteralExpression)stmt.exp;
    // assert(typeid(exp.value) == typeid(Tok));
    // import std.stdio: writeln; writeln(exp.value.type);
    // assert(exp.value.type == TokType.Integer);
}

@("var statement with type") unittest {
	auto parser = new Parser();
	Statement[] statements = parser.parse("var x : int = 12");
	assert(statements.length == 1, "expected one statement");
}

@("multiple var statements") unittest {
    auto parser = new Parser();
    Statement[] ss = parser.parse("var x = 2 + 3\n\n\nvar y = 3");
    assert(ss.length == 2, "expected two statements");
}

@("assignment: x=12+2") unittest {
    auto parser = new Parser();
    Statement[] ss = parser.parse("x = 12 + 2");
    import std.format: format;
    assert(ss.length == 1, format("expected one statement, got %d", ss.length));
}