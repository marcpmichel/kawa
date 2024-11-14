module parser;

import statements;
import lexer;

struct ParseError {
    string message;
    Tok token;
    string curline;
    uint line;
    uint col;
}


// TODO: write a propper grammar
// like C : only declarations at top level !


class Parser {
	Lexer lexer;
    bool has_errored;
    ParseError error;
    int block_level;
    Tok curTok;

	this(string program) {
		lexer = new Lexer();
        lexer.tokenize(program);
        curTok = lexer.front;
	}

    Statement[] parse() {
        return parseStatementList();
    }

    ErrorStatement parseError(string msg, Tok token=Tok(TokType.Error)) {
        Tok t = token.type == TokType.Error ? lexer.front : token;
        this.has_errored = true;
        this.error = ParseError(msg, t, lexer.curline);
        return null;
    }

    string formatError() {
        import std.string : rightJustify;
        import std.format : format;
        ParseError err = this.error;
        string context;
        if(err.curline.length > 0) { context = "\n" ~ err.curline ~ "\n" ~ rightJustify("^", err.token.col+1, '.'); }
		return format("ParseError: (%d:%d) : %s, got %s %s", 
		    err.token.line, err.token.col, err.message, err.token.type, context);
    }

    void printError() {
        import std.stdio: writeln;
        writeln(formatError());
    }


    bool isToken(TokType type) {
        return curTok.type == type;
    }

    bool isKeyword(Keyword k) {
        return curTok.type == TokType.Keyword && curTok.k == k;
    }

    Tok consume(TokType t, string msg="") {
        import std.format: format;
        if(curTok.type != t) parseError(format("Unexpected token %s %s", curTok.type, msg));
        return consume();
    }
    Tok consume() {
        Tok tok = curTok;
        curTok = lexer.nextToken();
        return tok;
    }

    Statement[] parseStatementList() {
        Statement[] statements;
        for(;;) {
            if(isToken(TokType.EoF)) break; // end of program
            if(isToken(TokType.EoL)) { consume(TokType.EoL); continue; }// end of statement
            if(block_level>0 && isToken(TokType.RBrace)) break; // end of block

            Statement stmt = parseStatement();
            if(stmt is null) break;  // EoF
            // if(cast(ErrorStatement)stmt !is null) { printError(cast(ErrorStatement)stmt); return []; }
            if(this.has_errored) { printError(); return statements; }
            statements ~= stmt;

            // parseError("expected EoL, EoF or } (end of statement)");
            // return null;
        }
        return statements;
    }

	Statement parseStatement() {
        if(isToken(TokType.EoF)) return null;
        Statement stmt;

        switch(curTok.type) {
            case TokType.Keyword: return parseKeyword();
            case TokType.Identifier: return parseAssignment();
            default: parseError("syntax error (unknown statement)"); return null;
        }

        /* a statement ends with: EoL, EoF (if last line), '}' (last statement in a block) */
        // if(isToken(TokType.EoL) || isToken(TokType.EoF)) return stmt;
        // if(block_level > 0 && isToken(TokType.RBrace)) return stmt; // end of block

        // return parseError("expected EoL, EoF or } (end of statement)"); 
        assert(false, "unreachable");
	}

    Statement parseKeyword() {
        Tok t = consume(TokType.Keyword);

        switch(t.k) {
            case Keyword.Var: return parseVar(); break;
            case Keyword.If: return parseIf(); break;
            case Keyword.While: return parseWhile(); break;
            case Keyword.Fun: return parseFunctionDeclaration(); break;
            case Keyword.Return: return parseReturn(); break;
            case Keyword.Pod: return parsePod(); break;
            default: parseError("unexpected keyword");
        }
        assert(0);
    }

    Type parseType() {
        switch(curTok.type) {
            case TokType.Keyword: 
                if(!isKeyword(Keyword.Auto)) return Type(TypeKind.Error, "type bug");
                consume(TokType.Keyword);
                return Type(TypeKind.Auto);
            break;
            case TokType.Identifier:
                Tok tok = consume(TokType.Identifier);
                return Type(TypeKind.Decl, tok.s);
            break;
            default: 
                return Type(TypeKind.Error, "bad type");
        }
    }

    Statement parseVar() {
        Tok name = consume(TokType.Identifier, "expected identifier");

        Type type;
        if(isToken(TokType.Colon)) {
            Tok colon = consume(TokType.Colon);
            type = parseType();
            if(type.kind == TypeKind.Error) parseError("bad type qualifier", colon);
        }
        else {
            type = Type(TypeKind.Auto, "auto");
        }

        if(isToken(TokType.Assign)) {
            consume(TokType.Assign);
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
            consume(TokType.Keyword); // else
            Statement otherwise = parseBlock();
            return new IfStatement(cond, then, otherwise);
        }
        return new IfStatement(cond, then, null);
    }
    
    Statement parseWhile() {
        Expression cond = parseCondition();
        Statement block = parseBlock();
        return new WhileStatement(cond, block);
    }

    Statement parseFunctionDeclaration() {
        Tok name = consume(TokType.Identifier);

        consume(TokType.LParen);
        ArgumentList list = parseArgumentList();
        consume(TokType.RParen);

        Type type;
        if(isToken(TokType.Colon)) {
            consume();
            type = parseType();
        }
        Statement block = parseBlock();
        return new FunctionDeclaration(name,  type, list, block);
    }

    Statement parseReturn() {
        Expression e = parseExpression();
        return new ReturnStatement(e);
    }

    ArgumentList parseArgumentList() {
       ArgumentList list;
       if(isToken(TokType.RParen)) return list; // empty list

       for(;;) {
            if(isToken(TokType.EoF)) { parseError("EoF in argument list"); break; }
            Argument arg = parseArgument();
            if(arg is null) { parseError("wrong argument declaration"); break; }
            list ~= arg;
            if(isToken(TokType.RParen)) break; // end of list
            consume(TokType.Comma);
       }
       return list;
    }

    Argument parseArgument() {
       Tok id = consume(TokType.Identifier);
       consume(TokType.Colon, "expected type declaration");
       Type type = parseType();
       return new Argument(id, type);
    }
    
    Expression parseCondition() {
        bool in_parens;
        if(isToken(TokType.LParen)) { 
            consume(TokType.LParen); in_parens = true;
        }
        Expression e = parseExpression();

        if(isToken(TokType.Equal) || isToken(TokType.NEqual)) {
            Tok op = consume();
            Expression e2 = parseExpression();
            if (in_parens) consume(TokType.RParen);
            return new ConditionExpression(op, e, e2);
        }
        else {
            Tok eq = Tok(TokType.Equal, "==");
            if(in_parens) consume(TokType.RParen);
            Expression e2 = new LiteralExpression(TokTrue);
            return new ConditionExpression(eq, e, e2);
        }
    }

    Statement parseBlock() {
        Statement[] statements;
        consume(TokType.LBrace);
        block_level++;
        statements = parseStatementList();
        consume(TokType.RBrace);
        block_level--;
        return new BlockStatement(statements);
    }

	Statement parsePod() {
        Tok name = consume(TokType.Identifier);
        consume(TokType.LBrace);
        Statement[] declarations;
        for(;;) {
            declarations ~= parseVar();
            if(isToken(TokType.RBrace)) break;
        }
        consume(TokType.RBrace);
		return new PodStatement(name, declarations);
	}

    Expression parseAssignment() {
        Expression e = parseIdentifier();
        if(typeid(e) != typeid(IdentifierExpression)) {
            return cast(Expression)parseError("invalid left-hand side for assignment");
        }
        Tok op = consume(TokType.Assign); // TODO: add +=, -=, *=, /=, %=, ++, -- 
        // Note: x++ => x += 1 => x = x + 1
        /* if(op.type != TokType.Assign) parseError("expected assignment operator"); */

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
            Tok op = consume();
            Expression e2 = parseFactor();
            e = new BinaryExpression(op, e, e2);
        }
        return e;
    }

    Expression parseFactor() {
        Expression e = parseUnary();
        while(isToken(TokType.Mul) || isToken(TokType.Div)) {
            Tok op = consume();
            Expression e2 = parseUnary();
            e = new BinaryExpression(op, e, e2);
        }
        return e;
    }

    Expression parseUnary() {
        if(curTok.type == TokType.Sub || curTok.type == TokType.Not) {
            Tok op = consume();
            Expression e = parsePrimary();
            return new UnaryExpression(op, e);
        }
        else {
            return parsePrimary();
        }
    }

    Expression parsePrimary() {
        switch(curTok.type) {
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
        consume(TokType.LParen); // (
        Expression e = parseExpression();
        consume(TokType.RParen);
        return e;
    }
    
    Expression parseIdentifier() {
        Tok id = consume(TokType.Identifier);
        if(isToken(TokType.LParen)) {
            return new CallExpression(id, parseExpressionList());
        }
        else 
            return new IdentifierExpression(id);
    }

    ExpressionList parseExpressionList() {
        ExpressionList list = new ExpressionList();
        consume(TokType.LParen);
        if(isToken(TokType.RParen)) return list;
        for(;;) {
            list.add(parseExpression());
            if(isToken(TokType.RParen)) break;
            consume(TokType.Comma);
        }
        consume(TokType.RParen);
        return list;
    }

    Expression parseLiteral() {
        with(TokType) {
            switch(curTok.type) {
                case Integer: return new IntegerLiteral(consume(Integer));
                case Float: return new FloatLiteral(consume(Float));
                case String: return new StringLiteral(consume(String));
                default: parseError("unknown literal");
            }
        }
        assert(false, "impossible");
    }

}

