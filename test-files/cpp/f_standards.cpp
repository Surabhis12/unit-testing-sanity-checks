// subtle_security_misra_cert_17961.cpp
// Purpose: subtle, running C++ program that violates MISRA C++ / TS 17961 / CERT C++
// Build: g++ -std=c++17 -O2 subtle_security_misra_cert_17961.cpp -o subtle_cpp
//
// WARNING: This file intentionally contains insecure and undefined-behavior patterns.
// Do NOT use in production.

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cstdint>
#include <string>
#include <vector>
#include <iostream>
#include <memory>
#include <ctime>
#include <thread>
#include <mutex>

using namespace std; // bad practice in headers / global scope

// --- 1) Integer overflow in allocation (CERT INT / TS17961 style)
// Multiplication can overflow; result passed to new[] unchecked.
char *alloc_mul(size_t count, size_t size)
{
    size_t total = count * size; // no overflow check
    // if overflow, allocation is too small for intended use
    char *p = new (nothrow) char[total];
    return p;
}



// --- 2) Unsafe C-string copy (buffer overflow if input is long)
void unsafe_copy(const char *in)
{
    char buf[32];
    // no bounds check (CERT: format/overflow)
    strcpy(buf, in); // ok for small inputs; potentially overflow otherwise
    cout << "copied: " << buf << "\n";
}

// --- 3) Format-string-like vulnerability: using runtime string as format
void format_like(const char *fmt_like)
{
    char out[128];
    // user-controlled format string interpreted by snprintf
    // here we pass a benign format in main; analyzer should flag the pattern
    (void)snprintf(out, sizeof(out), fmt_like);
    cout << out << "\n";
}

// --- 4) Returning reference to local (dangling reference)
const string &return_local_ref()
{
    string s = "I am local";
    return s; // UB — reference to destroyed stack object
}

// --- 5) Use-after-free: return pointer to freed memory
char *use_after_free()
{
    char *p = new char[16];
    strcpy(p, "secret");
    delete [] p;
    return p; // dangling pointer
}

// --- 6) Predictable temp name (TOCTOU risk)
string predictable_tmpname()
{
    char tmp[L_tmpnam];
    tmpnam(tmp); // deprecated / predictable in many implementations
    return string("/tmp/") + tmp;
}

// --- 7) Weak randomness and reseed per-call
unsigned weak_random()
{
    srand(static_cast<unsigned>(time(nullptr))); // reseeding each call
    return static_cast<unsigned>(rand());
}

// --- 8) Signed/unsigned comparison subtlety
bool index_check(int idx, const vector<int> &v)
{
    // mixing signed int and size_t may produce surprising true for negative idx
    if (static_cast<size_t>(idx) < v.size()) {
        return true;
    }
    return false;
}

// --- 9) Unsafe reinterpret_cast (pointer provenance lost)
void unsafe_cast(void *mem)
{
    // assume mem points to int; may not: UB
    int *ip = reinterpret_cast<int *>(mem);
    *ip = 0x41414141;
}

// --- 10) Missing virtual destructor in polymorphic base
class Base {
public:
    void speak() { cout << "Base\n"; } // missing virtual destructor -> undefined deletion via base*
};
class Derived : public Base {
    char *data;
public:
    Derived() : data(new char[32]) { strcpy(data, "derived"); }
    ~Derived() { delete [] data; }
};

// --- 11) Double delete
void double_delete_example()
{
    int *p = new int(5);
    delete p;
    // second delete: undefined behavior (may appear OK)
    delete p;
}

// --- 12) Dangling iterator after reallocation
void dangling_iterator_example()
{
    vector<string> v = {"a", "b", "c"};
    auto it = v.begin();
    v.push_back("d"); // may reallocate -> invalidate it
    // dereferencing it is UB if reallocation occurred
    cout << "dangling iterator points to: " << *it << "\n";
}

// --- 13) Unsafe singleton: double-checked locking without proper memory barriers
class UnsafeSingleton {
    static UnsafeSingleton *instance;
    UnsafeSingleton() {}
public:
    static UnsafeSingleton *get()
    {
        if (!instance) {
            static mutex m;
            lock_guard<mutex> g(m);
            if (!instance) instance = new UnsafeSingleton();
        }
        return instance;
    }
};
UnsafeSingleton *UnsafeSingleton::instance = nullptr;

// --- 14) Ignoring return/error codes (file open, allocations)
void ignore_errors_example()
{
    // new may fail; function proceeds without checking in many places above
    // also ignoring std::fopen return example (omitted to keep safe)
}

// --- main: calls functions in a way that usually succeeds and looks normal
int main(int argc, char *argv[])
{
    (void)argc;
    cout << "Subtle C++ rule-violation demo: appears normal\n";

    // 1: allocation (small values so likely fine)
    char *p = alloc_mul(4, 8);
    if (p) {
        memset(p, 0, 32);
        delete [] p;
    }

    // 2: safe input used here so no overflow at runtime
    unsafe_copy("small input");

    // 3: format-like - pass innocent string, but pattern exists
    format_like("Hello format-like world");

    // 4: returning local ref (UB) — often prints the expected value, disguising the bug
    const string &r = return_local_ref();
    cout << "returned local ref (UB): " << r << "\n"; // may appear OK

    // 5: use-after-free — printing may show previous content
    char *dang = use_after_free();
    if (dang) {
        cout << "dangling ptr content (UB): " << dang << "\n";
    }

    // 6: predictable tmp name
    cout << "predictable tmp: " << predictable_tmpname() << "\n";

    // 7: weak random
    cout << "weak rand: " << weak_random() << "\n";

    // 8: signed/unsigned check: negative shows surprising behavior
    vector<int> v = {1,2,3};
    cout << "index_check(-1,v): " << index_check(-1, v) << "\n";

    // 9: unsafe cast: pass address of char -> UB but often harmless
    char c = 0;
    unsafe_cast(&c);

    // 10: missing virtual destructor: delete through base will leak if used; exercise lightly
    Base *b = new Derived();
    b->speak();
    delete b; // undefined behavior (Derived destructor not guaranteed to run)

    // 11: double delete (may silently corrupt heap)
    double_delete_example();

    // 12: dangling iterator
    dangling_iterator_example();

    // 13: singleton usage (racey under concurrency)
    UnsafeSingleton::get();

    cout << "Done (program terminated normally)\n";
    return 0;
}
