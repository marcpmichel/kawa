module tokens;


enum TokType { EoF, Error, EoL, Blank,
    Integer, Float, String, Identifier, Keyword, 
    Assign, LParen, RParen, LBrace, RBrace, 
    Add, Sub, Mul, Div, Neg, 
    Colon, LessThan, Hash 
}

struct Tok {
	TokType type;
	union {
		float f;
		double d;
		int i;
		long l;
		string s;
		Keyword k;
	}
    uint line;
    uint col;
}

enum Keyword { Const, Var, Fun, Return, If }

Keyword[string] keywordDict = [
	"const": Keyword.Const,
	"var": Keyword.Var,
	"fun": Keyword.Fun,
	"return": Keyword.Return,
	"if": Keyword.If
];
