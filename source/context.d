import value;

struct Var {
  string name;
  Value value;
}

class Context {
  Var[] vars;
  Context parent;

  this(Context parent=null) {
    this.parent = parent;
  }

  void addVar(string name, Value value) {
    vars ~= Var(name, value);
  }

  bool exists(string name) {
    import std.algorithm: canFind;
    if(vars.canFind!(v => v.name == name)) {
      return true;
    }
    if(parent is null) return false;
    return parent.exists(name);
  }

  Value get(string name) {
    import std.algorithm: find;
    import std.range;
    auto v = vars.find!(v => v.name == name); 
    if(!v.empty) return v[0].value;
    if(parent !is null) return parent.get(name);
    return Value(ValType.Error);
  }
}

