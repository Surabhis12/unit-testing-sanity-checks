// cppcheck_tricky_errors.c
// Purpose: deliberately include multiple subtle issues for static analysis tests.
//
// Compile (example): gcc -std=c11 -O2 cppcheck_tricky_errors.c -o tricky

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>


/* 1) Uninitialized variable used (control-flow dependent) */
int uninit_usage(int flag)
{
    int maybe_set;
    if (flag > 0) {
        maybe_set = 42;
    }
    /* Using maybe_set when flag <= 0 -> uninitialized read in some paths */
    return maybe_set + 1;
}

/* 2) Buffer overflow (off-by-one): copying strlen() bytes into size = strlen() */
char *off_by_one_const_copy(const char *src)
{
    size_t n = strlen(src);
    /* allocate without room for terminating NUL */
    char *buf = malloc(n);
    if (!buf) return NULL;
    /* copies n+1 bytes expected, but buf only size n -> overflow */
    memcpy(buf, src, n + 1);
    return buf; /* leaked by caller unless freed */
}

/* 3) Null pointer deref after conditional free (use-after-free) */
char *use_after_free(int drop)
{
    char *p = malloc(64);
    if (!p) return NULL;
    strcpy(p, "Hello, world!");
    if (drop) {
        free(p);
    }
    /* still uses p even when freed above */
    p[0] = 'h';
    return p;
}

/* 4) Integer overflow leading to undersized allocation */
void *alloc_mul(size_t a, size_t b)
{
    /* supposed to allocate a*b elements but multiplication can overflow size_t */
    size_t nbytes = a * b; /* overflow possible */
    void *x = malloc(nbytes);
    return x;
}

/* 5) Format-string vulnerability: using external string directly */
void format_vuln(const char *user)
{
    char buf[128];
    /* user directly passed as format string */
    snprintf(buf, sizeof(buf), user);
    printf("%s\n", buf);
}

/* 6) Tainted pointer arithmetic: cast then compare (signed/unsigned subtlety) */
int signed_unsigned_cmp(int a, unsigned int b)
{
    /* comparison mixes signed and unsigned, subtle if a negative */
    if ((unsigned int)a < b) {
        return 1;
    }
    return 0;
}

/* 7) Array index out of bounds via mistaken loop boundary */
int find_first_zero(int *arr, size_t n)
{
    for (size_t i = 0; i <= n; ++i) { /* <= is wrong; should be < */
        if (arr[i] == 0) return (int)i;
    }
    return -1;
}

/* 8) Memory leak combined with early return paths */
char *create_copy_conditional(const char *s, int make_copy)
{
    char *tmp = NULL;
    if (make_copy) {
        tmp = malloc(strlen(s) + 1);
        if (!tmp) return NULL;
        strcpy(tmp, s);
        /* forgot to free tmp on the success path that returns a duplicated pointer */
        return tmp; /* ok for caller to free — but if caller doesn't, leak */
    } else {
        /* some other path that returns but tmp stays allocated if code changes */
        return "static";
    }
}

/* A small driver that exercises some functions to avoid "unused function" noise */
int main(int argc, char **argv)
{
    (void)argc;
    const char *sample = "abc";
    int flag = (argv && argv[1]) ? atoi(argv[1]) : 0;

    int a = uninit_usage(flag);
    printf("uninit_usage -> %d\n", a);

    char *c1 = off_by_one_const_copy(sample);
    if (c1) {
        printf("copied: %s\n", c1);
        free(c1);
    }

    char *c2 = use_after_free(flag);
    if (c2) {
        /* c2 may be dangling if flag was non-zero; still attempt to print to exercise */
        printf("maybe dangling: %.10s\n", c2);
        /* Avoid free to simulate caller oversight */
    }

    void *p = alloc_mul((size_t)1 << 31, (size_t)1 << 31); /* likely overflow on 64-bit/32-bit */
    if (p) free(p);

    format_vuln(argv[1] ? argv[1] : "Default %s");

    signed_unsigned_cmp(-1, 1u);

    int arr[3] = {1, 0, 2};
    int idx = find_first_zero(arr, 3);
    printf("first zero at %d\n", idx);

    char *c3 = create_copy_conditional("hello", flag);
    if (c3 && c3 != "static") {
        /* intentionally do not free in some runs to simulate leak */
        if (flag == 0) free(c3);
    }

    return 0;
}
