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
    import std.algorithm: find, count;
    return vars.find!(v => v.name == name) !is null;
  }
}
