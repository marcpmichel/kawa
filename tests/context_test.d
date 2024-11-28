import context;
import value;

@("new context") unittest {
  auto c = new Context();
  c.addVar("x", Value(ValType.Integer, i:10));
  assert(c.exists("x"), "entrry not found");
}

@("chained contexts") unittest {
  auto c1 = new Context();
  c1.addVar("z", Value(ValType.Float, f:1.23));
  auto c2 = new Context(c1);
  assert(c2.exists("z"));
}

@("get") unittest {
  auto c = new Context();
  auto v = Value(ValType.String, s: "hello");
  c.addVar("str", v);
  assert(c.get("str") == v);
}

@("get chained") unittest {
  auto c1 = new Context();
  auto v = Value(ValType.Integer, 1);
  c1.addVar("x", v);
  auto c2 = new Context(c1);
  assert(c2.get("x") == v);
}

