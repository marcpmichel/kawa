
enum ValType {
  Error, Integer, Float, String
}

struct Value {
  ValType type;

  union {
    int i;
    string s;
    float f;
  }
}

