module tokens;


enum TokType { NoOp, EoF, Error, EoL, 
	Blank, Comment, // ignored
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
		float f;
		Keyword k;
		LiteralConstant l;
	}
    uint line;
    uint col;
}

enum Keyword { None, Auto, Const, Var, Fun, Return, If, Else, While, Pod }

Keyword[string] keywordDict = [
  "auto":   Keyword.Auto,
	"const":  Keyword.Const,
	"var":    Keyword.Var,
	"fun":    Keyword.Fun,
	"return": Keyword.Return,
	"if":     Keyword.If,
	"else":   Keyword.Else,
	"while":  Keyword.While,
	"pod":    Keyword.Pod
];

enum LiteralConstant { Null, False, True, NaN, Infinity, Undefined }

LiteralConstant[string] literalConstantDict = [
	"null":      LiteralConstant.Null, 
	"false":     LiteralConstant.False, 
	"true":      LiteralConstant.True,
	"NaN":       LiteralConstant.NaN,
	"infinity":  LiteralConstant.Infinity, 
	"undefined": LiteralConstant.Undefined
];

enum TokTrue =     Tok(type: TokType.LiteralConstant, s: "true", l: LiteralConstant.True);
enum TokFalse =    Tok(type: TokType.LiteralConstant, s: "false", l: LiteralConstant.False);
enum TokNull =     Tok(type: TokType.LiteralConstant, s: "null", l: LiteralConstant.Null);
enum TokNaN =      Tok(type: TokType.LiteralConstant, s: "NaN", l: LiteralConstant.NaN);
enum TokInfinity = Tok(type: TokType.LiteralConstant, s: "infinity", l: LiteralConstant.Infinity);


bool isA(Tok tok, TokType type) {
 	return tok.type == type;   
}

bool isNot(Tok tok, TokType type) {
	return tok.type != type;
}

bool isKeyword(Tok t, Keyword k=Keyword.None) {
    return t.type == TokType.Keyword && (k==Keyword.None || (t.k == k));
}

bool isTerminator(Tok t) {
    return t.type == TokType.EoL || t.type == TokType.Semi;
}

