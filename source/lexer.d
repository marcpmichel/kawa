module lexer;

public import tokens;
import std.range;
import std.conv;

class Lexer {
	string program;
	Tok cur;
    uint line = 1;
    uint col = 1;
    string curline;

    this() {
    }

    void tokenize(string source) {
        this.program = source.dup;
        popFront();
    }

	Tok front() {
		return cur;	
	}
	void popFront() {
        import std.format;
		if(program.empty) { cur = Tok(TokType.EoF); return; }
		// if(program.front == ' ' || program.front == '\t') consumeBlank();
		// if(program.empty) { cur = Tok(TokType.EoF); return; }

		dchar c = program.front;
        curline ~= c;

		switch(c) {
            case ' ', '\t': cur = lexBlank(); break; 
			case 'a': .. case 'z':
			case 'A': .. case 'Z': cur = lexIdentifier(); break;
			case '0': .. case '9': cur = lexNumber(); break;
			case ':': cur = lexSingle(TokType.Colon, ':'); break;
			case '=': cur = lexSingle(TokType.Assign, '='); break;
			case '+': cur = lexSingle(TokType.Add, '+'); break;
			case '-': cur = lexSingle(TokType.Sub, '-'); break;
			case '*': cur = lexSingle(TokType.Mul, '*'); break;
			case '/': cur = lexSingle(TokType.Div, '/'); break;
			case '(': cur = lexSingle(TokType.LParen, '('); break;
			case ')': cur = lexSingle(TokType.RParen, ')'); break;
			case '{': cur = lexSingle(TokType.LBrace, '('); break;
			case '}': cur = lexSingle(TokType.RBrace, ')'); break;
			case '<': cur = lexSingle(TokType.LessThan, '<'); break;
			case '#': cur = lexSingle(TokType.Hash, '#'); break;
			case '\n': cur = lexSingle(TokType.EoL, '\n'); break;
			default: cur = lexError(format("invalid character: '%c' (%x)", c, c)); 
            break;
		}

        if(cur.type == TokType.Blank) popFront(); // consume blanks
	}

	Tok consume() {
		Tok t = this.front;
		this.popFront;
		return t;
	}

	Tok lexBlank() {
		for(;;) {
			program.popFront(); col++;
			if(program.empty) break;
			if(program.front != ' ') break;
			if(program.front != '\t') break;
		}
        return Tok(type: TokType.Blank, line: line, col: col);
	}

    Tok lexError(string msg) {
        return Tok(type: TokType.Error, s: msg, line: line, col: col);
    }

	Tok lexIdentifier() {
		string s;
		for(;;) {
			s ~= program.front;
			program.popFront(); col++;
			if(program.empty) break;
			if(program.front < 'a' || program.front > 'z') break;
		}
		return Tok(TokType.Identifier, s: s, line: line, col: col);
		if(s in keywordDict) {
			Keyword kw = keywordDict[s];
			return Tok(TokType.Keyword, k: kw, line: line, col: col);
		}
		else {
			return Tok(TokType.Identifier, s: s, line: line, col: col);
		}
	}

	Tok lexNumber() {
		string s;
		for(;;) {
			s ~= program.front;
			program.popFront(); col++;
			if(program.empty) break;
			if(program.front < '0' || program.front > '9') break;
		}
		return Tok(TokType.Integer, s: s, line: line, col: col);
	}

	Tok lexSingle(TokType type, dchar c) {
		string s = c.to!string; 
		program.popFront();
        if(c == '\n') { col=0; line++; curline=""; } else col++;
		return Tok(type, s: s, line: line, col: col);
	}
}


unittest {
    auto lex = new Lexer();
    lex.tokenize("this");
    assert(lex.front.type == TokType.Identifier && lex.front.s == "this");

    lex.tokenize("var a = 12");
    assert(lex.front.type == TokType.Identifier);
    lex.popFront;
    assert(lex.front.type == TokType.Identifier);
    lex.popFront;
    assert(lex.front.type == TokType.Assign);
    lex.popFront;
    assert(lex.front.type == TokType.Integer);

}