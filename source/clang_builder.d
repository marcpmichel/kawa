import ast_nodes;
import ast_visitor;
import stack;
import std.format: format;
import tokens: LiteralConstant;

class ClangVisitor : ASTVisitor {
    Stack!string stack;

    override void visit(IntegerLiteralNode node) {
        import std.conv : to;
        stack.push(node.value.to!string);
    }

    override void visit(FloatLiteralNode node) {
        import std.conv : to;
        stack.push(node.value.to!string);
    }

    override void visit(StringLiteralNode node) {
        import std.conv : to;
        stack.push(format("\"%s\"", node.value));
    }

    override void visit(ConstLiteralNode node) {
        import std.conv : to;
        stack.push(node.value.to!string);
    }

    override void visit(IdentifierNode node) {
        stack.push(node.name);
    }

    override void visit(BinaryOpNode node) {
        node.left.accept(this);
        node.right.accept(this);
        auto rightResult = stack.pop();
        auto leftResult = stack.pop();
        stack.push(format("(%s %s %s)", leftResult, node.operator, rightResult));
    }

    override void visit(VariableDeclarationNode node) {
        if(node.value !is null) {
            node.value.accept(this);
            string valueResult = stack.pop();
            stack.push(format("%s %s = %s;", node.type, node.name, valueResult));
        }
        else {
            stack.push(format("%s %s;", node.type, node.name));
        }
    }

    override void visit(IfNode node) {
        node.condition.accept(this);
        node.thenBranch.accept(this);
        string thenResult = stack.pop();
        string conditionResult = stack.pop();
        if(node.elseBranch is null) {
            stack.push(format("if(%s) %s;", conditionResult, thenResult));
        }
        else {
            node.elseBranch.accept(this);
            string elseResult = stack.pop();
            stack.push(format("if(%s) %s; else %s;", conditionResult, thenResult, elseResult));
        }
    }

    override void visit(WhileNode node) {
        node.condition.accept(this);
        node.body.accept(this);
        string bodyResult = stack.pop();
        string conditionResult = stack.pop();
        stack.push(format("while(%s) %s;", conditionResult, bodyResult));
    }

    override void visit(ReturnNode node) {
        if(node.value is null) {
            stack.push("return;");
        }
        else {
            node.value.accept(this);
            string valueResult = stack.pop();
            stack.push(format("return %s;", valueResult));
        }
    }

    override void visit(FunctionDeclarationNode node) {
        import std.array: join;
        string[] params;
        foreach(n; node.parameters) { n.accept(this); params~= stack.pop(); }
        string paramsResult = params.join(" ");
        node.body.accept(this);
        string bodyResult = stack.pop();
        stack.push(format("%s %s(%s) %s", node.type, node.name, paramsResult, bodyResult));
    }

    override void visit(FunctionCallNode node) {
        import std.array: join;
        string[] args;
        foreach(arg; node.arguments) { arg.accept(this); args ~= stack.pop(); }
        string argsResult = args.join(", ");
        stack.push(format("%s(%s)", node.functionName, argsResult));
    }

    override void visit(BlockNode node) {
        import std.array: join;
        string[] stmts;
        foreach (statement; node.statements) {
            statement.accept(this);
            stmts ~= stack.pop();
        }
        string stmtsResult = stmts.join(" "); 

        stack.push(format("{ %s }", stmtsResult));
    }

    override void visit(ProgramNode node) {
        import std.array: join;
        string[] result;

        foreach (n; node.nodes) {
            n.accept(this);
            result ~= stack.pop();
        }
        string resultProgram = result.join(" ");
        stack.push(format("/* program %s */)", resultProgram));
    }

    override void visit(PodDeclaration node)  {
        string[] params;
        foreach(p; node.parameters) {
            p.accept(this);
            params ~= stack.pop();
        }
        import std.array: join;
        string paramsResult = params.join("; "); 
        stack.push(format("typedef struct %s { %s; } %s;", node.name, paramsResult, node.name)); 
    }

    override void visit(Parameter node) {
        /* stack.push("[function parameter]"); */
        stack.push(format("%s %s", node.type, node.name));
    }
}
