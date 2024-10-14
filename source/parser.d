module parser;

import statements;
import lexer;

struct ParseError {
    string message;
    Tok token;
}

alias StatementList = Statement[];

class Parser {
	Lexer lexer;
    bool has_errored;
    ParseError error;
    int block_level;

	this(string program) {
		lexer = new Lexer();
        lexer.tokenize(program);
	}

    Statement[] parse() {
        return parseStatementList();
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
            version(Debug) { import std.stdio: writeln; writeln("expect: true for ", type); }
			lexer.popFront;
			return true;
		}
		return false;
	}
	
	bool check(Tok t, TokType type) {
		return t.type == type;
	}

    bool isToken(TokType type) {
        return lexer.front.type == type;
    }

    bool isKeyword(Keyword k) {
        return lexer.front.type == TokType.Keyword && lexer.front.k == k;
    }

    Statement[] parseStatementList() {
        Statement[] statements;
        for(;;) {
            if(isToken(TokType.EoL)) { lexer.popFront(); } // ignoring leading EoL
            if(block_level > 0 && isToken(TokType.RBrace)) break; // end of block = end of list

            Statement stmt = parseStatement();
            if(stmt is null) break;  // EoF
            if(cast(ErrorStatement)stmt !is null) { printError(cast(ErrorStatement)stmt); return []; }

            statements ~= stmt;

        }
        return statements;
    }

	Statement parseStatement() {
        version(Debug) { import std.stdio:writeln; writeln("parseStatement"); }
		Tok t = lexer.front;
        if(t.type == TokType.EoF) return null;
        Statement stmt;

        switch(lexer.front.type) {
            case TokType.Keyword: stmt = parseKeyword(); break;
            case TokType.Identifier: stmt = parseAssignment(); break;
            case TokType.EoF: return null;
            default: return parseError("syntax error");
        }

        /* a statement ends with: EoL, EoF (if last line), '}' (last statement in a block) */
        if(isToken(TokType.EoL) || isToken(TokType.EoF)) return stmt;
        if(block_level > 0 && isToken(TokType.RBrace)) return stmt; // end of block

        return parseError("expected EoL, EoF or }"); 
	}

    Statement parseKeyword() {
        Tok t = lexer.consume(); // consume keyword
        switch(t.k) {
            case Keyword.Var: return parseVar(); break;
            case Keyword.If: return parseIf(); break;
            default: return parseError("unexpected keyword");
        }
        assert(0);
    }

    // bool isEndOfStatement() {
    //     if(isToken(TokType.EoL)) return true;
    //     if(block_level > 0 && isToken(TokType.RBrace)) return true;
    //     return false;
    // }

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
        if(isToken(TokType.Colon)) {
            Tok colon = lexer.consume();
            type = parseType();
            if(type.kind == TypeKind.Error) return parseError("bad type qualifier", colon);
        }
        else {
            type = Type(TypeKind.Auto, "auto");
        }

        if(isToken(TokType.Assign)) {
            lexer.consume();
            Expression e = parseExpression();
            return new VarStatement(name, type, e);
        }
        else {
            return new VarStatement(name, type, new EmptyExpression());
        }
    }

    Statement parseIf() {
        Expression cond = parseCondition();
        Statement then = parseBlock();
        if(isKeyword(Keyword.Else)) {
            lexer.consume(); // else
            Statement otherwise = parseBlock();
            return new IfStatement(cond, then, otherwise);
        }
        return new IfStatement(cond, then, null);
    }
    
    Expression parseCondition() {
        bool in_parens;
        if(isToken(TokType.LParen)) { lexer.consume(); in_parens = true; }
        Expression e = parseExpression();

        if(isToken(TokType.Equal) || isToken(TokType.NEqual)) {
            Tok op = lexer.consume();
            Expression e2 = parseExpression();
            if (in_parens && !expect(TokType.RParen)) return cast(Expression) parseError("expecting )");
            return new ConditionExpression(op, e, e2);
        }
        else {
            Tok eq = Tok(TokType.Equal, s:"==");
            if(in_parens && !expect(TokType.RParen)) return cast(Expression)parseError("expecting )");
            Expression e2 = new LiteralExpression(TokTrue);
            return new ConditionExpression(eq, e, e2);
        }
    }

    Statement parseBlock() {
        version(Debug) { import std.stdio: writeln; writeln("# parseBlock()"); }
        if(!expect(TokType.LBrace)) return parseError("expecting {");
        block_level++;
        Statement[] statements = parseStatementList();
        if(!expect(TokType.RBrace)) return parseError("expecting }");
        block_level--;
        return new BlockStatement(statements);
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
        while(isToken(TokType.Add) || isToken(TokType.Sub)) {
            Tok op = lexer.consume();
            Expression e2 = parseFactor();
            e = new BinaryExpression(op, e, e2);
        }
        return e;
    }

    Expression parseFactor() {
        Expression e = parseUnary();
        while(isToken(TokType.Mul) || isToken(TokType.Div)) {
            Tok op = lexer.consume();
            Expression e2 = parseUnary();
            e = new BinaryExpression(op, e, e2);
        }
        return e;
    }

    Expression parseUnary() {
        if(lexer.front.type == TokType.Sub || lexer.front.type == TokType.Not) {
            Tok op = lexer.consume();
            Expression e = parsePrimary();
            return new UnaryExpression(op, e);
        }
        else {
            return parsePrimary();
        }
    }

    Expression parsePrimary() {
        switch(lexer.front.type) {
            case TokType.LParen: return parseParenExpression();
            case TokType.Identifier: return parseIdentifier();
            case TokType.String:
            case TokType.LiteralConstant:
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

@("parsing var x : auto = 1 + 2") unittest {
    auto parser = new Parser("var x : auto = 1 + 2");
    Statement[] ss = parser.parse();
    assert(ss.length == 1);
}

@("parsing var = 12") unittest {
	auto parser = new Parser("var x = 12");
	Statement[] statements = parser.parse();
	assert(statements.length == 1, "expected one statement");
    assert(cast(VarStatement)statements[0] !is null);
    auto stmt = cast(VarStatement)statements[0];
    assert(cast(LiteralExpression)stmt.exp !is null, "not a literal exp");
    auto exp = cast(LiteralExpression)stmt.exp;
    // assert(typeid(exp.value) == typeid(Tok));
    // import std.stdio: writeln; writeln(exp.value.type);
    // assert(exp.value.type == TokType.Integer);
}

@("parsing var x : int = 12") unittest {
	auto parser = new Parser("var x : int = 12");
	Statement[] statements = parser.parse();
	assert(statements.length == 1, "expected one statement");
}

@("multiple var statements") unittest {
    auto sl = new Parser("var x = 2 + 3\n\n\nvar y = 3").parse();
    assert(sl.length == 2, "expected two statements");
}

@("assignment: x=12+2") unittest {
    auto sl = new Parser("x = 12 + 2").parse();
    import std.format: format;
    assert(sl.length == 1, format("expected one statement, got %d", sl.length));
}

@("parse unary") unittest {
    StatementList sl = new Parser("x = !y").parse();
    assert(sl.length == 1, "cannot parse unary expression");
}

@("parse condition") unittest {
    auto s = new Parser("(x == y)").parseCondition();
    assert(cast(ConditionExpression)s !is null, "not a condition expression !");
}

// @("parse two conditions") unittest {
//     auto p = new Parser("(x == y)\nola == true");
//     auto s = p.parseCondition();
//     assert(cast(ConditionExpression)s !is null, "not a condition expression !");
//     auto s2 = p.parseCondition();
//     assert(cast(ConditionExpression)s2 !is null, "not a condition expression !");
//     auto ss = cast(ConditionExpression)s2;
//     assert(cast(IdentifierExpression)(ss.left) !is null, "not an identifier expression");
// }

@("parse block") unittest {
    auto s = new Parser("{ var x = 1 }").parseBlock();
    assert(cast(BlockStatement)s !is null, "not a block statement !");
    auto s2 = new Parser("{var a=2\nvar b = 12}").parseBlock();
    assert((cast(BlockStatement)s2).statements.length == 2, "expected 2 statements");
}

@("parse error") unittest {
    auto s = new Parser("var \n").parseVar();
    assert((cast(ErrorStatement)s !is null));
}

@("parse if") unittest {
    auto s = new Parser("if(x == 1) { ola = true }").parseIf();
    assert(cast(IfStatement)s !is null, "not an if statement");
    assert(cast(ErrorStatement)s is null);
}