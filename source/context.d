import value;

struct Var {
  string name;
  string type;
  Value value;
}

class Context {
  Var[] vars;
  Context parent;

  this(Context parent) {
    this.parent = parent;
  }

  void addVar(string name, string type, Value value) {
    vars ~= Var(name, type, value);
  }

  bool exists(string name) {
    import std.algorithm: canFind;
    return vars.canFind!(v => v.name == name);
  }
}
