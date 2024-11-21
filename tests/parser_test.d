import parser;
// import statements; 
import ast_nodes;

version(unittest) {
    string errorList(Parser parser) {
        import std.array: join;
        return parser.formatErrors.join('\n');
    }

    ASTNode parseOne(string code) {
       auto parser = new Parser(code);
       ASTNode[] res = parser.parse();
	   assert(parser.has_errored == false, errorList(parser));
       return res[0];
    }

    BlockNode parseBlock(string code) {
       auto parser = new Parser(code);
       BlockNode res = parser.parseBlock();
	   assert(parser.has_errored == false, errorList(parser));
       return res;
    }
}

@("parsing var decl") unittest {
    ASTNode res = parseOne("var x:int = 12");
    assert(res.type == NodeType.VariableDeclaration);
}

@("parsing block") unittest {
    auto block = parseBlock(`{ x = x + 1; return x; }`);
    assert(block.statements.length == 2);
}

@("parsing fun") unittest {
    auto stmt = parseOne(`fun double(x:int):int { return x*2; }`);
    assert(stmt.type == NodeType.FunctionDeclaration);
}

@("parsing pod") unittest {
    auto stmt = parseOne(`
    pod Pouet { 
        x: int = 1 
        y: float = 2
        s: string
    }
    `);
    assert(stmt.type == NodeType.PodDeclaration);
}
    
/+
@("parsing fun decl") unittest {
    auto parser = new Parser(`
    fun square(x: int):int { 
        return x * x;
    }`);
    ASTNode[] declarations = parser.parse();
    assert(declarations[0].type == NodeType.FunctionDeclaration);
}
+/

/+
@("parsing var = 12") unittest {
	auto parser = new Parser("var x = 12;");
	ASTNode[] statements = parser.parse();
	assert(statements.length == 1, "expected one statement");
    assert(cast(VariableDeclarationNode)statements[0] !is null);
    auto stmt = cast(VariableDeclarationNode)statements[0];
    assert(cast(IntegerLiteralNode)stmt.exp !is null, "not a Integer exp");
    /* auto exp = cast(LiteralExpression)stmt.exp; */
    // assert(typeid(exp.value) == typeid(Tok));
    // import std.stdio: writeln; writeln(exp.value.type);
    // assert(exp.value.type == TokType.Integer);
}

@("parsing var x : auto = 1 + 2") unittest {
    auto parser = new Parser("var x : auto = 1 + 2");
    Statement[] ss = parser.parse();
    assert(ss.length == 1);
}

@("parsing var x : int = 12") unittest {
	auto parser = new Parser("var x : int = 12");
	Statement[] statements = parser.parse();
	assert(statements.length == 1, "expected one statement");
}

@("assignment: x=12+2") unittest {
    auto sl = new Parser("x = 12 + 2").parse();
    import std.format: format;
    assert(sl.length == 1, format("expected one statement, got %d", sl.length));
}

@("multiple var statements") unittest {
    auto sl = new Parser("var x = 2 + 3\n\n\nvar y = 3").parse();
    assert(sl.length == 2, "expected two statements");
}


@("parse unary") unittest {
    StatementList sl = new Parser("x = !y").parse();
    assert(sl.length == 1, "cannot parse unary expression");
}

@("parse condition") unittest {
    auto s = new Parser("(x == y)").parseCondition();
    assert(cast(ConditionExpression)s !is null, "not a condition expression !");
}


@("parse block") unittest {
    auto s = new Parser("{ var x = 1 }").parseBlock();
    assert(cast(BlockStatement)s !is null, "not a block statement !");
    auto s2 = new Parser("{var a=2\nvar b = 12}").parseBlock();
    assert((cast(BlockStatement)s2).statements.length == 2, "expected 2 statements");
}

@("parse error") unittest {
    auto p = new Parser("var \n");
    auto s = p.parseVar();
    assert(p.has_errored, "should have errored");
    // assert((cast(ErrorStatement)s !is null));
}

@("parse while") unittest {
    auto p = new Parser("while(x == 1) { ola = ola + 1 }");
    auto s = p.parseStatement();
    assert(!p.has_errored, p.errorList);
    assert(cast(WhileStatement)s !is null, "not a while statement");
}

@("parse fun decl") unittest {
    auto p = new Parser("fun kaboo(x:int) { x = x + 1 }");
    auto s = p.parseStatement();
    assert(!p.has_errored, p.errorList);
}

@("parse pod decl") unittest {
    auto p = new Parser("pod Vector { x: int  y: int = 0 }");
    auto s = p.parseStatement();
    assert(!p.has_errored, p.errorList);
}

@("parse if") unittest {
    auto p = new Parser("if(x == 1) { ola = true }");
    auto s = p.parseStatement();
    assert(cast(IfStatement)s !is null, "not an if statement");
    assert(!p.has_errored, p.errorList);
}

+/
