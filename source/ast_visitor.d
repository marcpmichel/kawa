import ast_nodes;

interface ASTVisitor {
    void visit(IntegerLiteralNode node);
    void visit(FloatLiteralNode node);
    void visit(StringLiteralNode node);
    void visit(ConstLiteralNode node);
    void visit(IdentifierNode node);
    void visit(BinaryOpNode node);
    void visit(VariableDeclarationNode node);
    void visit(IfNode node);
    void visit(WhileNode node);
    void visit(ReturnNode node);
    void visit(FunctionDeclarationNode node);
    void visit(FunctionCallNode node);
    void visit(BlockNode node);
    void visit(ProgramNode node);
    void visit(PodDeclaration node);
    void visit(Parameter node);
}

