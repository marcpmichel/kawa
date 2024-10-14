module tokens;


enum TokType { NoOp, EoF, Error, EoL, 
	Blank,
    Integer, Float, String, Identifier, Keyword, LiteralConstant, // primary
    Assign, 
	LParen, RParen, LBrace, RBrace, 
    Add, Sub, Mul, Div, Neg, 
	Not,
	Equal, NEqual, LessThan, GreaterThan, // Comparsion
    Colon, Semi, Comma, Hash 
}


struct Tok {
	TokType type;
    string s;
	union {
		int i;
		Keyword k;
		LiteralConstant l;
	}
    uint line;
    uint col;
}

enum Keyword { Auto, Undefined, Const, Var, Fun, Return, If, Else }

Keyword[string] keywordDict = [
    "auto": Keyword.Auto,
    "undefined": Keyword.Undefined,
	"const": Keyword.Const,
	"var": Keyword.Var,
	"fun": Keyword.Fun,
	"return": Keyword.Return,
	"if": Keyword.If,
	"else": Keyword.Else,
	// "true": Keyword.True,
	// "false": Keyword.False
];

enum LiteralConstant { Null, False, True, NaN, Infinity, Undefined }

LiteralConstant[string] literalConstantDict = [
	"null": LiteralConstant.Null, 
	"false": LiteralConstant.False, 
	"true": LiteralConstant.True,
	"NaN": LiteralConstant.NaN,
	"infinity": LiteralConstant.Infinity, 
	"undefined": LiteralConstant.Undefined
];

enum TokTrue = Tok(type: TokType.LiteralConstant, s: "true", l: LiteralConstant.True);
enum TokFalse = Tok(type: TokType.LiteralConstant, s: "false", l: LiteralConstant.False);
enum TokNull = Tok(type: TokType.LiteralConstant, s: "null", l: LiteralConstant.Null);

