module tokens;


enum TokType { EoF, Error, EoL, Blank,
    Integer, Float, String, Identifier, Keyword, 
    Assign, LParen, RParen, LBrace, RBrace, 
    Add, Sub, Mul, Div, Neg, 
    Colon, LessThan, GreaterThan, Semi, Comma, Hash 
}


struct Tok {
	TokType type;
    string s;
	union {
		int i;
		Keyword k;
	}
    uint line;
    uint col;
}

enum Keyword { Auto, Undefined, Const, Var, Fun, Return, If }

Keyword[string] keywordDict = [
    "auto": Keyword.Auto,
    "undefined": Keyword.Undefined,
	"const": Keyword.Const,
	"var": Keyword.Var,
	"fun": Keyword.Fun,
	"return": Keyword.Return,
	"if": Keyword.If
];
