// cpp_security_bad_practices.cpp
// Purpose: compact set of common security vulnerabilities + bad coding practices
// for testing static analyzers and code-review rules.
//
// Build (example): g++ -std=c++17 -O0 -Wall cpp_security_bad_practices.cpp -o badcpp
// NOTE: This file is intentionally insecure. Do NOT use in production.

#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <cstring>      // strcpy, strcmp
#include <cstdlib>      // system, rand, getenv
#include <ctime>        // time
#include <mutex>
#include <thread>


using namespace std;    // Bad practice: pollutes global namespace

#define MAX_BUF 32      // Macro + magic number - bad style

// 1) Hard-coded credentials (embedded secret)
static const char* ADMIN_PASS = "SuperSecret123!"; // detected by secret scanners

// 2) Unsafe C-style string handling -> buffer overflow
void insecure_copy(const char* user_input) {
    char buf[MAX_BUF];
    // No bounds checking — classic buffer overflow
    strcpy(buf, user_input);
    cout << "You entered: " << buf << "\n";
}

// 3) Format-like misuse (user-controlled format)
void insecure_format(const char* fmt_like) {
    char out[128];
    // user controls format string -> format-string vulnerability
    snprintf(out, sizeof(out), fmt_like);
    cout << out << "\n";
}

// 4) Command injection via system() (unsanitized input)
void insecure_system(const char* filename) {
    char cmd[256];
    // naive concatenation allows injection like "file; rm -rf /"
    snprintf(cmd, sizeof(cmd), "ls -l %s", filename);
    system(cmd); // flagged by SAST rules
}

// 5) Predictable temporary filename (tmpnam / predictable)
string insecure_tmpname() {
    char name[L_tmpnam];
    tmpnam(name); // deprecated / predictable on some platforms
    // returns predictable, race-prone path
    return string("/tmp/") + name;
}

// 6) Weak randomness for tokens (rand())
string generate_token_weak() {
    srand((unsigned)time(nullptr)); // reseeding every call is bad
    unsigned r = rand();
    return to_string(r); // predictable / non-crypto
}

// 7) Returning pointer to local stack storage (dangling pointer)
const char* dangling_return() {
    char buf[64];
    strcpy(buf, "temporary");
    return buf; // returns pointer to stack — UB
}

// 8) Use-after-free / double delete via raw new/delete
char* use_after_free() {
    char* p = (char*)malloc(16);
    strcpy(p, "secret");
    free(p);
    // still use p
    if (p) p[0] = 'X'; // use-after-free
    return p;
}

// 9) Unsafe cast: reinterpret_cast hiding type mismatch
void unsafe_casting(void* mem) {
    // assume mem points to int but might not
    int* ip = reinterpret_cast<int*>(mem);
    *ip = 42; // UB if mem not an int*
}

// 10) Integer overflow in size calculations
char* alloc_mul(size_t n, size_t itemsize) {
    // naive multiply may overflow
    size_t total = n * itemsize;
    char* p = (char*)malloc(total); // small allocation if overflowed
    return p;
}

// 11) Global mutable state + no const correctness
int global_counter = 0; // bad: global mutable state

// 12) Unsafe singleton (double-checked locking without volatile/memory fences)
class UnsafeSingleton {
    static UnsafeSingleton* instance;
    UnsafeSingleton() {}
public:
    static UnsafeSingleton* get() {
        if (!instance) {
            // race-prone double-checked locking
            static mutex m;
            lock_guard<mutex> g(m);
            if (!instance) instance = new UnsafeSingleton();
        }
        return instance;
    }
};
UnsafeSingleton* UnsafeSingleton::instance = nullptr;

// 13) Ignoring return codes and exceptions (poor error handling)
void ignore_errors() {
    FILE* f = fopen("maybe.txt", "r");
    // don't check fopen result; calling fread on NULL will crash
    char tmp[16];
    fread(tmp, 1, sizeof(tmp), f); // ignoring return and NULL check
    // no fclose
}

// 14) Insecure file permissions & excessive privileges (platform dependent)
void insecure_open() {
    // Using ofstream with default permissions, then chmod or leaving world-readable is a risk.
    ofstream ofs("/tmp/data.txt"); // no checks on ownership/permissions
    ofs << "sensitive\n";
    ofs.close();
}

// 15) Dangling iterator / invalidated reference after vector modification
void dangling_iterator() {
    vector<string> v = {"a","b","c"};
    auto it = v.begin();
    v.push_back("d"); // may reallocate -> invalidate it
    cout << *it << "\n"; // undefined behavior if reallocated
}

// 16) Excessive use of macros and no RAII (manual resource management)
FILE* open_file_manual(const char* path) {
    FILE* f = fopen(path, "w");
    // caller must fclose; easy to forget -> resource leak
    return f;
}

// 17) Weakcrypto-like custom XOR obfuscation (bad practice)
string obfuscate(const string& s) {
    string out = s;
    for (size_t i = 0; i < out.size(); ++i) out[i] ^= 0xAA; // not crypto
    return out;
}

// Driver to exercise functions (use with caution)
int main(int argc, char** argv) {
    cout << "Demo: insecure C++ patterns\n";

    // 1
    if (argc > 1) insecure_copy(argv[1]);

    // 2
    if (argc > 2) insecure_format(argv[2]);

    // 3
    insecure_system(".");

    // 4
    cout << "tmpname: " << insecure_tmpname() << "\n";

    // 5
    cout << "token: " << generate_token_weak() << "\n";

    // 6
    const char* d = dangling_return();
    cout << "dangling: " << (d ? d : "null") << "\n";

    // 7
    char* p = use_after_free();
    if (p) cout << "after free: " << p[0] << "\n";

    // 8
    ignore_errors();

    // 9
    dangling_iterator();

    // 10
    FILE* fh = open_file_manual("/tmp/needs_close.txt");
    if (fh) {
        fputs("data\n", fh);
        // intentionally not closing -> leak
    }

    // 11: global mutable usage
    ++global_counter;
    cout << "global_counter: " << global_counter << "\n";

    // 12: obfuscation
    cout << "obf: " << obfuscate(\"hello\") << "\n";

    return 0;
}
