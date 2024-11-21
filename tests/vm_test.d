import opcodes;
import vm;
import value;

@("test halt") unittest {
  auto vm = new VM();
  ubyte[] prog = [Op.Halt];
  vm.run(prog);
  assert(vm.ip == (prog.ptr + 1));
}

/+
@("test stack push/pop") unittest {
  auto vm = new VM();
  vm.run([Op.Halt]);
  vm.push(Value(type: ValType.Integer, i: 12));
  assert(vm.sp != vm.stack.ptr);
  Value v = vm.pop();
  assert(v.type == ValType.Integer, "not an integer");
  assert(v.i == 12, "expected 12");
  assert(vm.sp == vm.stack.ptr);
}

@("test stack underflow") unittest {
  auto vm = new VM();
  vm.run([Op.Halt]);
  try { vm.pop(); assert(false, "should not succeed"); } 
  catch(RuntimeError e) { assert(true); }
}

@("test stack overflow") unittest {
  auto vm = new VM();
  vm.run([Op.Halt]);
  try {
    foreach(n; 0..VM.StackSize+1) {
      vm.push(Value(ValType.Integer, i:1));
    }
    assert(false, "shoud fail");
  }
  catch(RuntimeError e) { assert(true); }
}

@("test push constant") unittest {
  auto vm = new VM();
  vm.run([Op.Const]);
}
+/
