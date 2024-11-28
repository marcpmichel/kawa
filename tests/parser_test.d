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

    IfNode parseIf(string code) {
        auto parser = new Parser(code);
        IfNode res = parser.parseIf();
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
    
@("parsing fun decl") unittest {
    auto stmt = parseOne(`
    fun square(x: int):int { 
        return x * x;
    }`);
    assert(stmt.type == NodeType.FunctionDeclaration);
    auto fdecl = cast(FunctionDeclarationNode)stmt;
    assert(fdecl !is null);
    assert(fdecl.name == "square");
}

@("parsing simple expr") unittest {
    auto stmt = parseOne("var res:int = x + 12");
    assert(stmt.type == NodeType.VariableDeclaration);
    auto vardecl = cast(VariableDeclarationNode)stmt;
    assert(vardecl !is null);
    assert(vardecl.name == "res");
}

@("parse if") unittest {
    auto stmt = parseIf(`
    if(x == 144) {
        print("hello")
    }
    else {
        print("meh")
    }
    `);
    assert(stmt.type == NodeType.If);
}

