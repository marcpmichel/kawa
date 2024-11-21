module main;

import std.stdio;
import parser;
import statements;
import std.file;
import generator;

// string test_program = `var x = 12
// x = x + 1
// z = "ola"
// var y:int = (1 + 2) * 3
// x = -12
// b = !a
// `;

// string test_program = `fun agla(x : int) {
// 	return x * x
// }`;

/*
string test_program = `
# testing functions

fun wazoo(x: int) {
    return x * x
}

var first = 1

if(first) {
	return "hello"
}

fun excellent(x:int, y:int) :int {
    return x * y
}
`;
*/

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

	return x;
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
			/* import sexpression_builder; */
			/* auto v = new SExpressionVisitor(); */
			import clang_builder;
			auto v = new ClangVisitor();
			foreach(n; nodes) { 
				n.accept(v); 
				writeln(v.stack.pop());
			}
			// return 0;
		}
	
		// lexical analysis

		// evaluation
		// auto context = new Context('x');
		
		writeln("---------------------");
		/* auto generator = new Generator(); */
		/* generator.generate(statements); */

		return 0;
	}
}


// vim: ts=4 sw=4
