#include <iostream>
#include <cstring>
using namespace std;

// Memory leak
void leak() {
    int* p = (int*)malloc(100 * sizeof(int));
    *p = 42;
}


// Buffer overflow
void overflow() {
    char buf[10];
    strcpy(buf, "This is way too long for buffer");
}

// Null pointer
void nullPtr() {
    int* p = nullptr;
    *p = 10;
}

// Uninitialized
int uninit() {
    int x;
    return x + 10;
}

int main() {
    leak();
    return 0;
}