module main;

import std.stdio;
import parser;
import statements;

string test_program = r"var x = 12
x = x + 1
var y:int = (1 + 2) * 3
";

version(unittest) {
	// test runner
} else {
	void main() {
		writeln("--- test program ---");
		writeln(test_program);

		writeln("--- parsing ---");
		auto parser = new Parser();
		Statement[] statements = parser.parse(test_program);
		if(parser.has_errored) {
			writeln("--- parse error ! ---");
			writeln(parser.error);
			writeln("---------------------");
		}
		else {
			writeln("--- parsed statements ---");
			foreach(s; statements) { writeln(s); }
		}

	}
}


// vim: ts=4 sw=4
