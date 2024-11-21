module parser;

import lexer;
import ast_nodes;

struct ParseError {
    string message;
    Tok token;
    string curline;
    uint line;
    uint col;
}

// TODO: write a propper grammar !

class Parser {
	Lexer lexer;
    bool has_errored;
    ParseError[] errors;
    int block_level;
    Tok curTok;

	this(string program) {
		lexer = new Lexer();
        lexer.tokenize(program);
        curTok = lexer.front;
	}

    ASTNode[] parse() {
        return parseDeclarations();
    }

    ASTNode[] parseDeclarations() {
        ASTNode[] declarations;
        for(;;) {
            if(this.has_errored) break;
            if(isToken(TokType.EoF)) break;
            if(isToken(TokType.EoL)) { consume(TokType.EoL); continue; }
            ASTNode decl = parseDeclaration();
            if(decl is null) break;
            declarations ~= decl;
        }
        return declarations;
    }

    ASTNode parseDeclaration() {
        if(!isToken(TokType.Keyword)) {
            parseError("only declarations are allowed at top level");
            return null;
        }
        switch(curTok.k) {
            case Keyword.Fun: return parseFunctionDeclaration();
            case Keyword.Pod: return parsePodDeclaration();
            case Keyword.Var: return parseVarDeclaration();
            default: parseError("invalid keyword"); return null;
        }
        assert(0);
    }

    ASTNode parseFunctionDeclaration() {
        consume(TokType.Keyword);
        string name = consume(TokType.Identifier).s;
        consume(TokType.LParen);
        Parameter[] params;
        while(curTok.type != TokType.RParen) {
            if(curTok.type == TokType.EoF) break;
            Tok paramName = consume(TokType.Identifier);
            consume(TokType.Colon);
            Tok type = consume(TokType.Identifier);
            ASTNode value = null;
            if(maybe(curTok, TokType.Assign)) {
                value = parseExpression();
            }
            params ~= new Parameter(paramName.s, type.s, value);
        }
        consume(TokType.RParen);

        consume(TokType.Colon);
        auto funType = consume(TokType.Identifier).s;

        auto body = parseBlock();

        return new FunctionDeclarationNode(name, funType, params, body);
    }

    BlockNode parseBlock() {
        ASTNode[] statements;
        consume(TokType.LBrace);
        while(curTok.type != TokType.RBrace) {
            if(curTok.type == TokType.EoF) break;
            auto stmt = parseStatement();
            if(stmt is null) break;
            statements ~= stmt; 
        }
        consume(TokType.RBrace);
        return new BlockNode(statements);
    }

    ASTNode parseStatement() {
        ASTNode stmt;
        switch(curTok.type) {
            case TokType.Identifier: stmt = parseAssignment(); break;
            case TokType.Keyword: stmt = parseInstruction(); break;
            default: parseError("expected assignment or instruction"); 
        }
        maybe(curTok, TokType.Semi); // optional ;
        return stmt;
    }

    ASTNode parseInstruction() {
        with(Keyword) {
            switch(curTok.k) {
                case Var:    return parseVarDeclaration(); 
                case Pod:    return parsePodDeclaration(); 
                case Fun:    return parseFunctionDeclaration();
                case Return: return parseReturn();
                case If:     return parseIf();
                case While:  return parseWhile();
                default: parseError("unknown keyword"); return null;
            }
        }
    }

    ASTNode parseReturn() {
        consume(TokType.Keyword);
        ASTNode expr = null;
        if(!isTerminator(curTok)) {
            expr = parseExpression();
        }
        return new ReturnNode(expr);
    }

    ASTNode parseCondition() {
        consume(TokType.LParen);
        ASTNode expr = parseExpression();
        consume(TokType.RParen);
        return expr;
    }

    ASTNode parseIf() {
        ASTNode condition = parseCondition();
        BlockNode thenBlock = parseBlock();
        BlockNode elseBlock = null;
        
        if(curTok.isKeyword(Keyword.Else)) {
            consume(TokType.Keyword);
            elseBlock = parseBlock();
        }
        return new IfNode(condition, thenBlock, elseBlock);
    }

    ASTNode parseWhile() {
        consume(TokType.Keyword);
        ASTNode condition = parseExpression();
        ASTNode body = parseBlock();
        return new WhileNode(condition, body);
    }

    ASTNode parsePodDeclaration() {
        consume(TokType.Keyword);
        auto name = consume(TokType.Identifier);
        consume(TokType.LBrace);
        Parameter[] members;
        while(curTok.isNot(TokType.RBrace)) {
            members ~= parseParameter();
        }
        consume(TokType.RBrace);
        return new PodDeclaration(name.s, members);
    }

    ASTNode parseVarDeclaration() {
        consume(TokType.Keyword);
        auto id = consume(TokType.Identifier);
        if(curTok.isA(TokType.Assign)) {
            parseError("missing type !");
            return null;
        }
        consume(TokType.Colon);
        auto typeTok = consume(TokType.Identifier);
        ASTNode value;
        if(maybe(curTok, TokType.Assign)) {
            value = parseExpression();
        }
        maybe(curTok, TokType.Semi);
        return new VariableDeclarationNode(id.s, typeTok.s, value);
    }

    Parameter parseParameter() {
        auto id = consume(TokType.Identifier);
        consume(TokType.Colon);
        auto typeTok = consume(TokType.Identifier);
        ASTNode value;
        if(maybe(curTok, TokType.Assign)) {
            value = parseExpression();
        }
        return new Parameter(id.s, typeTok.s, value);
    }

    ASTNode parseAssignment() {
        if(curTok.isNot(TokType.Identifier)) {
            parseError("expected an identifier");
            return null;
        }
        auto id = consume(TokType.Identifier);
        ASTNode e = new IdentifierNode(id.s);

        if(curTok.isNot(TokType.Assign)) {
            parseError("expected assignment");
            return null;
        }
        consume(TokType.Assign);
        ASTNode e2 = parseExpression();
        return new BinaryOpNode("=", e, e2);
    }

    ASTNode parseExpression() {
        ASTNode e = parseComparison();
        return e;
    }

    ASTNode parseComparison() {
        ASTNode e = parseTerm();
        if(isComparison(curTok)) {
            Tok op = consume();
            ASTNode e2 = parseTerm();
            e = new BinaryOpNode(op.s, e, e2);
        }
        return e;
    }

    ASTNode parseTerm() {
        ASTNode e = parseFactor();
        while(isToken(TokType.Add) || isToken(TokType.Sub)) {
            if(curTok.type == TokType.EoF) break;
            Tok op = consume();
            ASTNode e2 = parseFactor();
            e = new BinaryOpNode(op.s, e, e2);
        }
        return e;
    }

    ASTNode parseFactor() {
        ASTNode e = parseUnary();
        while(isToken(TokType.Mul) || isToken(TokType.Div)) {
            if(curTok.type == TokType.EoF) break;
            Tok op = consume();
            ASTNode e2 = parseUnary();
            e = new BinaryOpNode(op.s, e, e2);
        }
        return e;
    }

    ASTNode parseUnary() {
        if(curTok.type == TokType.Sub || curTok.type == TokType.Not) {
            Tok op = consume();
            ASTNode e = parsePrimary();
            return new BinaryOpNode(op.s, e, null);
        }
        else {
            return parsePrimary();
        }
    }

    ASTNode parsePrimary() {
        switch(curTok.type) {
            case TokType.LParen:          return parseParenExpression();
            case TokType.Identifier:      return parseIdentifier();
            case TokType.String:          return parseStringLiteral();
            case TokType.LiteralConstant: return parseConstLiteral();
            case TokType.Float:           return parseFloatLiteral();
            case TokType.Integer:         return parseIntegerLiteral();
            default: parseError("cannot parse primary expression"); return null;
        }
        assert(0);
    }

    ASTNode parseParenExpression() {
        consume(TokType.LParen); // (
        ASTNode e = parseExpression();
        consume(TokType.RParen);
        return e;
    }
    
    ASTNode parseIdentifier() {
        Tok id = consume(TokType.Identifier);
        if(isToken(TokType.LParen)) {
            return new FunctionCallNode(id.s, parseExpressionList());
        }
        else 
            return new IdentifierNode(id.s);
    }

    ASTNode[] parseExpressionList() {
        ASTNode[] list;
        consume(TokType.LParen);
        if(isToken(TokType.RParen)) return list;
        for(;;) {
            list ~= (parseExpression());
            if(isToken(TokType.RParen)) break;
            consume(TokType.Comma);
        }
        consume(TokType.RParen);
        return list;
    }

    ASTNode parseStringLiteral() {
        return new StringLiteralNode(consume(TokType.String).s);
    }
    ASTNode parseIntegerLiteral() {
        return new IntegerLiteralNode(consume(TokType.Integer).i);
    }
    ASTNode parseFloatLiteral() {
        return new FloatLiteralNode(consume(TokType.Float).f);
    }
    ASTNode parseConstLiteral() {
        return new ConstLiteralNode(consume(TokType.LiteralConstant).l);
    }

    // ========== utility methods

    void parseError(string msg, Tok token=Tok(TokType.Error)) {
        Tok t = token.type == TokType.Error ? lexer.front : token;
        this.has_errored = true;
        this.errors ~= ParseError(msg, t, lexer.curline);
    }

    string[] formatErrors() {
        import std.string : rightJustify;
        import std.format : format;

        string[] formattedErrors;

        foreach(err; this.errors) {
            string context;
            if(err.curline.length > 0) { context = "\n" ~ err.curline ~ "\n" ~ rightJustify("^", err.token.col+1, '.'); }
		    formattedErrors ~= format("ParseError: (%d:%d) : %s, got %s %s", 
		        err.token.line, err.token.col, err.message, err.token.type, context);
        }
        return formattedErrors;
    }

    bool isToken(TokType type) {
        return curTok.type == type;
    }

    bool isKeyword(Keyword k) {
        return curTok.type == TokType.Keyword && curTok.k == k;
    }

    bool isComparison(Tok t) {
        import std.algorithm: canFind;
        with(TokType) {
            return [Equal, NEqual, LessThan, GreaterThan ].canFind(t.type);
        }
    }

    bool maybe(Tok tok, TokType type) {
        if(tok.type != type) return false;
        consume(type);
        return true;
    }


    Tok consume(TokType t, string msg="") {
        import std.format: format;
        if(curTok.type != t) {
            parseError(format("Expected %s%s", t, msg));
            return Tok(TokType.Error);
        }
        return consume();
    }
    Tok consume() {
        Tok tok = curTok;
        curTok = lexer.nextToken();
        return tok;
    }
}

