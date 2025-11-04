// cppcheck_tricky_errors.cpp
// Real-world subtle C++ bugs meant to test deep static analysis.
// Build: g++ -std=c++17 -O2 cppcheck_tricky_errors.cpp -o tricky_cpp

#include <iostream>
#include <string>
#include <vector>
#include <memory>
#include <cstring>
#include <stdexcept>


// 1) Class without virtual destructor — classic polymorphic leak
class Base {
public:
    virtual void greet() { std::cout << "Base\n"; }
};
class Derived : public Base {
    std::string *data;
public:
    Derived() { data = new std::string("Derived data"); }
    ~Derived() { delete data; }
};

// 2) Uninitialized member usage
struct Foo {
    int x;
    Foo() { } // forgot to initialize x
    int value() const { return x + 1; }
};

// 3) Double delete via manual pointer handling
void double_free_example() {
    int* p = new int(42);
    delete p;
    delete p; // Oops: double free
}

// 4) Return reference to local variable (dangling reference)
const std::string& bad_ref() {
    std::string local = "temporary";
    return local;
}

// 5) Exception-unsafe resource leak
void exception_leak(bool trigger) {
    char* buf = new char[256];
    if (trigger)
        throw std::runtime_error("boom");
    delete[] buf; // skipped when exception thrown
}

// 6) Incorrect operator== breaking symmetry
struct Weird {
    int a;
    bool operator==(const Weird& other) const {
        if (a == 0) return false;
        return a == other.a;
    }
};

// 7) Implicit conversion causing slicing
struct Animal {
    virtual void speak() { std::cout << "Animal\n"; }
};
struct Dog : Animal {
    void speak() override { std::cout << "Dog\n"; }
};
void makeSpeak(Animal a) { a.speak(); } // slicing occurs

// 8) Self-assignment unsafe operator=
struct Buffer {
    char* data;
    Buffer(size_t n) { data = new char[n]; }
    ~Buffer() { delete[] data; }

    Buffer& operator=(const Buffer& other) {
        delete[] data;             // dangerous if self-assigned
        data = new char[strlen(other.data) + 1];
        strcpy(data, other.data);
        return *this;
    }
};

// 9) Shared_ptr cycle — memory leak despite smart pointers
struct Node {
    std::shared_ptr<Node> next;
    ~Node() { std::cout << "Node destroyed\n"; }
};
void make_cycle() {
    auto a = std::make_shared<Node>();
    auto b = std::make_shared<Node>();
    a->next = b;
    b->next = a; // cyclic reference prevents destruction
}

// 10) Range-based for bug: iterating dangling temporary
void dangling_range() {
    for (auto c : std::string("temp")) { // iterates over destroyed temp
        std::cout << c;
    }
    std::cout << "\n";
}

int main() {
    Base* b = new Derived();
    b->greet();
    delete b; // leak (no virtual dtor warning)

    Foo f;
    std::cout << f.value() << "\n"; // uninitialized read

    double_free_example();

    try {
        exception_leak(true);
    } catch (...) {
        std::cout << "Caught exception\n";
    }

    Weird w1{0}, w2{0};
    bool eq = (w1 == w2);
    std::cout << "weird eq: " << eq << "\n";

    Dog d;
    makeSpeak(d); // slicing: Dog becomes Animal copy

    Buffer buf1(16);
    strcpy(buf1.data, "hello");
    Buffer buf2(8);
    buf2 = buf2; // self-assign bug

    make_cycle();

    dangling_range();

    try {
        std::cout << bad_ref() << "\n"; // dangling ref
    } catch (...) {}

    return 0;
}
