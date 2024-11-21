import ast_visitor;
import tokens: LiteralConstant;

enum NodeType {
    Error, 
    IntegerLiteral, FloatLiteral, StringLiteral, ConstantLiteral,
    Identifier, BinaryOp, Parameter,
    VariableDeclaration, FunctionDeclaration, PodDeclaration, 
    If, While, Return, FunctionCall, Block, Program,
}

class ASTNode {
    NodeType type;
    this(NodeType type) { this.type = type; }
    abstract void accept(ASTVisitor visitor);
}

class IntegerLiteralNode : ASTNode {
    int value;
    this(int value) { super(NodeType.IntegerLiteral); this.value = value; }
    override void accept(ASTVisitor visitor) { visitor.visit(this); }
}

class FloatLiteralNode : ASTNode {
    float value;
    this(float value) { super(NodeType.FloatLiteral); this.value = value; }
    override void accept(ASTVisitor visitor) { visitor.visit(this); }
}

class StringLiteralNode : ASTNode {
    string value;
    this(string value) { super(NodeType.StringLiteral); this.value = value; }
    override void accept(ASTVisitor visitor) { visitor.visit(this); }
}

class ConstLiteralNode : ASTNode {
    LiteralConstant value;
    this(LiteralConstant value) { super(NodeType.ConstantLiteral); this.value = value; }
    override void accept(ASTVisitor visitor) { visitor.visit(this); }
}

class IdentifierNode : ASTNode {
    string name;
    this(string name) { super(NodeType.Identifier); this.name = name; }
    override void accept(ASTVisitor visitor) { visitor.visit(this); }
}

class BinaryOpNode : ASTNode {
    string operator;
    ASTNode left;
    ASTNode right;
    this(string op, ASTNode left, ASTNode right) {
        super(NodeType.BinaryOp);
        this.operator = op;
        this.left = left;
        this.right = right;
    }
    override void accept(ASTVisitor visitor) { visitor.visit(this); }
}

class VariableDeclarationNode : ASTNode {
    string name;
    string type;
    ASTNode value;
    this(string name, string type, ASTNode value) {
        super(NodeType.VariableDeclaration);
        this.name = name;
        this.type = type;
        this.value = value;
    }
    override void accept(ASTVisitor visitor) { visitor.visit(this); }
}

class IfNode : ASTNode {
    ASTNode condition;
    ASTNode thenBranch;
    ASTNode elseBranch;
    this(ASTNode condition, ASTNode thenBranch, ASTNode elseBranch = null) {
        super(NodeType.If);
        this.condition = condition;
        this.thenBranch = thenBranch;
        this.elseBranch = elseBranch;
    }
    override void accept(ASTVisitor visitor) { visitor.visit(this); }
}

class WhileNode : ASTNode {
    ASTNode condition;
    ASTNode body;
    this(ASTNode condition, ASTNode body) {
        super(NodeType.While);
        this.condition = condition;
        this.body = body;
    }
    override void accept(ASTVisitor visitor) { visitor.visit(this); }
}

class ReturnNode : ASTNode {
    ASTNode value;
    this(ASTNode value) { super(NodeType.Return); this.value = value; }
    override void accept(ASTVisitor visitor) { visitor.visit(this); }
}

class FunctionDeclarationNode : ASTNode {
    string name;
    Parameter[] parameters;
    BlockNode body;
    string type;
    this(string name, string type, Parameter[] parameters, BlockNode body) {
        super(NodeType.FunctionDeclaration);
        this.name = name;
        this.type = type;
        this.parameters = parameters;
        this.body = body;
    }
    override void accept(ASTVisitor visitor) { visitor.visit(this); }
}

class FunctionCallNode : ASTNode {
    string functionName;
    ASTNode[] arguments;
    this(string functionName, ASTNode[] arguments) {
        super(NodeType.FunctionCall);
        this.functionName = functionName;
        this.arguments = arguments;
    }
    override void accept(ASTVisitor visitor) { visitor.visit(this); }
}


class BlockNode : ASTNode {
    ASTNode[] statements;
    this(ASTNode[] statements) {
        super(NodeType.Block);
        this.statements = statements;
    }
    override void accept(ASTVisitor visitor) { visitor.visit(this); }
}

class ProgramNode : ASTNode {
    ASTNode[] nodes;
    this(ASTNode[] nodes) {
        super(NodeType.Program);
        this.nodes = nodes;
    }
    override void accept(ASTVisitor visitor) { visitor.visit(this); }
}

class Parameter : ASTNode {
    string name;
    string type;
    ASTNode value;
    this(string name, string type, ASTNode value) {
        super(NodeType.Parameter);
        this.name = name;
        this.type = type;
        this.value = value;
    }
    override void accept(ASTVisitor visitor) { visitor.visit(this); }
}

class PodDeclaration: ASTNode {
    string name;
    Parameter[] parameters;
    this(string name, Parameter[] params) {
        super(NodeType.PodDeclaration);
        this.name = name;
        this.parameters = params;
    }
    override void accept(ASTVisitor visitor) { visitor.visit(this); }
}
