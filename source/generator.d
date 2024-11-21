import statements;
import std.stdio: writeln;

class Generator {

  this() {

  }

  void generate(StatementList statements) {
    foreach(stmt; statements) {
      writeln(stmt.to_c());
    }
  }

}
