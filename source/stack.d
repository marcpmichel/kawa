

class StackException : Error {
	this(string message) {
		super(message);
	}
}

struct Stack(T) {
	import std.range;
	T[] container;

	T pop() {
		if(container.empty) throw new StackException("stack underflow");
		T element = container.back;
		container.popBack;
		return element;
	}
	void push(T el) {
		container ~= el;
	}
	size_t size() {
		return container.length;
	}

}

/+
unittest {
	auto s = Stack!string();
	s.push("hello");
	s.push("world");
	assert(s.size == 2);
}

unittest {
	auto s = Stack!string();
	s.push("azerty");
	string e = s.pop();
	assert(e == "azerty");
}

unittest {
	auto s = Stack!string();
	s.push("one");
	s.push("two");
	auto el = s.pop();
	assert(el == "two");
	assert(s.size == 1);
}

unittest {
	auto s = Stack!string();
	try {
		auto el = s.pop();
		assert(false, "nope");
	}
	catch(StackException e) {
		assert(true);
	}
}

+/

