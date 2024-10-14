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
        this.popFront();
    }

    void tokenize(string source) {
        line = 1; col = 1;
        this.program = source.dup;
        popFront();
    }

    bool frontIs(TokType type) {
        return cur.type == type;
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

		switch(c) {
            case ' ', '\t': cur = lexBlank(); break; 
			case '\r', '\n': cur = lexEOL(); break;
			case 'a': .. case 'z':
			case 'A': .. case 'Z': cur = lexIdentifier(); break;
			case '0': .. case '9': cur = lexNumber(); break;
			case ':': cur = lexSingle(TokType.Colon, ':'); break;
			case '"': cur = lexString(); break;
			case '=': cur = lexAssignOrEq(); break;
			case '+': cur = lexSingle(TokType.Add, '+'); break;
			case '-': cur = lexSingle(TokType.Sub, '-'); break;
			case '*': cur = lexSingle(TokType.Mul, '*'); break;
			case '/': cur = lexSingle(TokType.Div, '/'); break;
			case '(': cur = lexSingle(TokType.LParen, '('); break;
			case ')': cur = lexSingle(TokType.RParen, ')'); break;
			case '{': cur = lexSingle(TokType.LBrace, '{'); break;
			case '}': cur = lexSingle(TokType.RBrace, '}'); break;
			case '<': cur = lexSingle(TokType.LessThan, '<'); break;
			case '#': cur = lexSingle(TokType.Hash, '#'); break;
			case ';': cur = lexSingle(TokType.Semi, '#'); break;
			case ',': cur = lexSingle(TokType.Comma, '#'); break;
			case '!': cur = lexNotOrNeq(); break;
			default: cur = lexError(format("invalid character: '%c' (%x)", c, c)); 
            break;
		}

        curline ~= cur.s;
		// version(Debug) { import std.stdio: writeln; writeln(cur); }
        if(cur.type == TokType.Blank) popFront(); // ignore blanks

	}

	Tok consume() {
		Tok t = this.front;
		version(Debug) { import std.stdio:writeln; writeln("consume ", t); }
		this.popFront;
		return t;
	}

	Tok lexBlank() {
		string s;
		for(;;) {
			s ~= program.front; 
			program.popFront(); col++;
			if(program.empty) break;
			if(program.front != ' ') break;
			if(program.front != '\t') break;
		}
        return Tok(type: TokType.Blank, s:s, line: line, col: col);
	}

    Tok lexEOL() {
        for(;;) {
            program.popFront(); col=1; line++;
            if(program.empty) return Tok(TokType.EoF);
            if(program.front != '\n' && program.front != '\r') break;
        }
		curline = "";
        return Tok(type: TokType.EoL, line: line, col: col);
    }

    Tok lexError(string msg) {
        return Tok(type: TokType.Error, s: msg, line: line, col: col);
    }

	Tok lexIdentifier() {
		import std.ascii : isAlphaNum;
		string s;
		for(;;) {
			s ~= program.front;
			program.popFront(); col++;
			if(program.empty) break;
			if(!program.front.isAlphaNum) break;
		}
		if(s in keywordDict) {
			Keyword kw = keywordDict[s];
			return Tok(TokType.Keyword, s:s, k: kw, line: line, col: col);
		}
		if(s in literalConstantDict) {
			LiteralConstant lit = literalConstantDict[s];
			return Tok(TokType.LiteralConstant, s:s, l:lit, line: line, col: col);
		}
		return Tok(TokType.Identifier, s:s, line: line, col: col);
	}

	Tok lexNumber() {
		string s;
		for(;;) {
			s ~= program.front;
			program.popFront(); col++;
			if(program.empty) break;
			if(program.front < '0' || program.front > '9') break;  // use std.ascii.isDigit ?
		}
		return Tok(TokType.Integer, s: s, line: line, col: col);
	}
	
	Tok lexString() {
		string s;
		program.popFront(); // consume '"'
		for(;;) {
			s ~= program.front;
			program.popFront(); col++;
			if(program.empty) return lexError("unterminated string");
			if(program.front == '"') {
				program.popFront();
				return Tok(type: TokType.String, s: s, line: line, col: col);
			}
		}
		return lexError("internal error");
	}

	Tok lexSingle(TokType type, dchar c) {
		string s = c.to!string; 
		program.popFront();
        if(c == '\n') { col=0; line++; curline=""; } else col++;
		return Tok(type, s: s, line: line, col: col);
	}

	Tok lexAssignOrEq() {
		program.popFront();
		Tok t;
		t.line = line; t.col = col;
		if(program.front == '=') {
			program.popFront();
			t.type = TokType.Equal; t.s = "==";
		}
		else {
			t.type = TokType.Assign; t.s = "=";
		}
		return t;
	}

	Tok lexNotOrNeq() {
		program.popFront();
		Tok t; t.line = line; t.col = col;
		if(program.front == '=') {
			program.popFront();
			t.type = TokType.NEqual; t.s = "!=";
		}
		else {
			t.type = TokType.Not; t.s = "!";
		}
		return t;
	}
}


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