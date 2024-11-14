import lexer;

@("basic tokens")
unittest {
    auto lex = new Lexer();

    lex.tokenize("12");
    assert(lex.frontIs(TokType.Integer));

    lex.tokenize("var");
    assert(lex.front.type == TokType.Keyword && lex.front.k == Keyword.Var);
}

@("lex a few tokens") unittest {
    auto lex = new Lexer();
    lex.tokenize("var a = 12");
    assert(lex.frontIs(TokType.Keyword));
    lex.popFront;
    assert(lex.frontIs(TokType.Identifier));
    lex.popFront;
    assert(lex.frontIs(TokType.Assign));
    lex.popFront;
    assert(lex.frontIs(TokType.Integer));
}

@("lex identifier") unittest {
	auto lex = new Lexer();
	lex.tokenize("abc");
	assert(lex.frontIs(TokType.Identifier));
	assert(lex.front.s == "abc");
}

@("lex not equal") unittest {
	auto lex = new Lexer();
	lex.tokenize("!=");
	assert(lex.frontIs(TokType.NEqual));
}
