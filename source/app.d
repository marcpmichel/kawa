module main;

import std.stdio;
import parser;
import std.file;

string test_program = `
var r:float = 144

pod Vector {
	x: float = 0
	y: float = 0
}

fun square(x: int) :int {
	return x * x
}

fun main() : int {
	var v:Vector;

	var x:int = square(12);
	if(x == r) {
		print("all right !");
	}
	else {
		print("meh :(");
	}

	return 0;
}

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
		import ast_nodes;
		ASTNode[] nodes = parser.parse();
		if(parser.has_errored) {
			writeln("--- parse error ! ---");
			foreach(err; parser.formatErrors()) {
				writeln(err);
			}
			writeln("---------------------");
			return 2;
		}
		else {
			writeln("--- parsed statements ---");

			import clang_builder;
			auto v = new ClangVisitor();
			/* import sexpression_builder; */
			/* auto v = new SExpressionVisitor(); */
			foreach(n; nodes) { 
				n.accept(v); 
				writeln(v.stack.pop());
			}
		}
	
		writeln("---------------------");

		return 0;
	}
}


// vim: ts=4 sw=4
