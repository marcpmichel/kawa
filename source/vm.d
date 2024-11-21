import opcodes;
import value;
import statements;


class RuntimeError : Error {
  this(string msg) {
    super(msg);
  }
}

class VM {

  enum StackSize = 1024;

  ubyte[] code;
  ubyte* ip;
  Value* sp;
  Value[StackSize] stack;
  
  void runtimeError(string errmsg) {
    throw new RuntimeError(errmsg);
  }

  ubyte read_byte() {
    return *ip++;
  }

  void push(Value value) {
    if(sp == stack.ptr + StackSize) runtimeError("stack overflow");
    *sp++ = value;
  }

  Value pop() {
    if(sp == stack.ptr) runtimeError("stack underflow");
    sp--;
    return *sp;
  } 

  void run(ubyte[] code) {
    this.code = code;
    this.ip = code.ptr;
    this.sp = stack.ptr;

    for(;;) {
      ubyte op = read_byte();
      switch(op) {
        case Op.Halt: goto end; break;
        default: runtimeError("Unknown opcode");
      }
    }
    end:
  }

}
