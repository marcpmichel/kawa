module main;

import std.stdio;
import parser;
import statements;
import std.file;

string test_program = `var x = 12
x = x + 1
z = "ola"
var y:int = (1 + 2) * 3
x = -12
b = !a
`;

version(unittest) {
	// test runner
} else {
	int main(string[] args) {
		writeln(args);
		string code;

		if(args.length > 1) {
			// auto file = File("example.txt", "r"); and std.utf.byChar() for range
			code = readText(args[1]);
		}
		else {
			code = test_program;
		}

		writeln("--- program ---");
		writeln(code);

		writeln("--- parsing ---");
		auto parser = new Parser(code);
		Statement[] statements = parser.parse();
		if(parser.has_errored) {
			writeln("--- parse error ! ---");
			writeln(parser.error);
			writeln("---------------------");
			return 2;
		}
		else {
			writeln("--- parsed statements ---");
			foreach(s; statements) { writeln(s); }
			return 0;
		}

	}
}


// vim: ts=4 sw=4
