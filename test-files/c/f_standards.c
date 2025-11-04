/*
 * subtle_security_misra_cert_17961.c
 *
 * Purpose: compact collection of subtle violations of MISRA C, ISO/IEC TS 17961,
 * and CERT C/C++ rules for testing static analyzers and CI pipelines.
 *
 * Compiles and runs normally on typical Linux x86_64 with:
 *   gcc -std=c11 -O2 subtle_security_misra_cert_17961.c -o subtle_test
 *
 * The vulnerabilities are subtle (data-dependent, platform-dependent or logic-level)
 * so the program usually runs and prints innocuous output.
 *
 * DO NOT USE IN PRODUCTION.
 */

 
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <time.h>
#include <unistd.h>

/* ---------- Subtle violations collected below ---------- */

/* 1) Integer multiplication overflow used for allocation (CERT INT34 / TS17961 style)
 *    count * size can overflow; result used directly in malloc().
 *    Appears fine for small inputs but fails silently on overflow.
 */
void *sneaky_alloc(size_t count, size_t size)
{
    /* no overflow check */
    size_t total = count * size;
    void *p = malloc(total); /* if overflowed, p is too small for intended use */
    return p;
}

/* 2) Format-string-like usage: user string used as format to snprintf.
 *    If user supplies format tokens, behavior can be surprising.
 *    (CERT: format string issues; MISRA: use of runtime format strings)
 */
void sneaky_format(const char *user)
{
    char buf[128];
    /* user controls format — insecure pattern */
    /* If 'user' contains %s/%x/etc, snprintf will interpret it. */
    (void)snprintf(buf, sizeof(buf), user);
    puts(buf);
}

/* 3) Missing bounds in scanf -> buffer overflow possibility (CERT/FIO)
 *    Using "%s" with scanf without width specifier is unsafe but common.
 */
void read_name_unsafely(void)
{
    char name[16];
    printf("Enter small name: ");
    /* no width limit; subtle overflow if user enters long name */
    (void)scanf("%s", name); /* intentionally unsafe */
    printf("Hello, %.8s\n", name); /* partial print hides long input */
}

/* 4) Use-after-free: pointer returned from function but freed earlier (CERT MEM) */
char *use_after_free_example(void)
{
    char *p = (char *)malloc(32);
    if (p == NULL) {
        return NULL;
    }
    strcpy(p, "sensitive");
    free(p);
    /* returning dangling pointer — UB but may look fine if caller just prints */
    return p;
}

/* 5) Returning address of stack-allocated buffer (CERT DCL / MISRA)
 *    Very subtle: on many runs the string remains readable, but it's UB.
 */
char *return_stack_addr(void)
{
    char local[24];
    strcpy(local, "stack_tmp");
    return local; /* dangling pointer */
}

/* 6) Predictable temporary filename (TOCTOU / TS17961)
 *    Predictable filename based on PID — race-prone on multi-user systems.
 */
char *predictable_tmpname(void)
{
    static char name[64];
    (void)snprintf(name, sizeof(name), "/tmp/app_tmp_%d.tmp", (int)getpid());
    return name; /* static to keep it usable by caller */
}

/* 7) Weak randomness (CERT RNG) + reseeding each call */
unsigned weak_token(void)
{
    /* reseeding on each call is a bad practice and rand() is not CSPRNG */
    srand((unsigned)time(NULL));
    return (unsigned)rand();
}

/* 8) Signed/unsigned comparison subtlety (MISRA rules about mixing)
 *    Using size_t (unsigned) compared to signed int; negative input becomes large positive.
 */
int index_check(int idx, size_t n)
{
    /* idx might be negative; (size_t)idx becomes huge and comparison behaves unexpectedly */
    if ((size_t)idx < n) {
        return 1;
    }
    return 0;
}

/* 9) memcpy with length derived from untrusted source (TS17961 / CERT)
 *    No thorough validation of length — can copy more than destination expects.
 */
void copy_from_user(const char *src, size_t len)
{
    char dst[32];
    /* no check that len <= sizeof(dst) */
    (void)memcpy(dst, src, len); /* potential overflow if len > 32 */
    dst[31] = '\0';
    printf("copied: %.31s\n", dst);
}

/* 10) Ignoring return codes and errors (CERT ERR)
 *     Bad error handling: assume fopen/fread succeed.
 */
void ignore_errors_example(const char *path)
{
    FILE *f = fopen(path, "r");
    /* no check on f */
    char line[80];
    if (f != NULL) {
        /* even here we ignore return of fgets intentionally elsewhere */
        (void)fgets(line, sizeof(line), f); /* no check on result */
        printf("first line: %.64s\n", line);
        (void)fclose(f);
    } else {
        /* swallow failure silently */
    }
}

/* 11) Unsafe cast: hiding pointer provenance (CERT DCL)
 *     Recasting between pointer types without alignment or provenance checks.
 */
void unsafe_cast_example(void *mem)
{
    /* assume mem points to int — may not */
    int *ip = (int *)mem; /* unsafe cast */
    *ip = 42; /* UB if mem isn't suitable */
}

/* 12) Forbidden constructs in many safety profiles: goto + multiple returns
 *     MISRA discourages goto; multiple exit points violate certain MISRA guidelines.
 */
int goto_and_multiple_exit(int x)
{
    if (x < 0) {
        goto done; /* MISRA discourages goto */
    }
    if (x == 0) {
        return 0; /* multiple returns allowed by C but discouraged by MISRA */
    }
done:
    return x + 1;
}

/* 13) Hidden logic that makes the program appear normal while violating rules */
int main(int argc, char *argv[])
{
    (void)argc;

    printf("Demo: subtle rule violations (appears normal)\n");

    /* sneaky_alloc: integer overflow if values are large; here using small values */
    void *p = sneaky_alloc(4, 8);
    if (p != NULL) {
        memset(p, 0, 4 * 8);
        free(p);
    }

    /* sneaky_format: usually harmless if argument contains no % tokens */
    sneaky_format("regular user-provided text (no format specifiers)");

    /* read_name_unsafely: uses scanf without width (hidden risk) */
    /* To keep demo noninteractive in many CI runs we skip calling it by default.
     * Uncomment to test interactive detection. */
    /* read_name_unsafely(); */
    read_name_unsafely();

    /* use_after_free_example: returns dangling pointer, printing often "works" */
    char *dang = use_after_free_example();
    if (dang != NULL) {
        /* may print stale contents or crash depending on runtime */
        printf("dangling contents: %.16s\n", dang);
    }

    /* return_stack_addr: definitely UB; often prints the earlier value */
    char *stk = return_stack_addr();
    printf("stack returned string (UB): %.16s\n", stk);

    /* predictable tmp name */
    char *tmp = predictable_tmpname();
    printf("predictable tmpname: %s\n", tmp);

    /* weak token print */
    printf("weak token sample: %u\n", weak_token());

    /* signed/unsigned check: surprising behavior when negative passed */
    printf("index_check(-1, 10) -> %d\n", index_check(-1, 10));

    /* copy_from_user: chooses length based on benign input so usually OK */
    const char *payload = "short string";
    copy_from_user(payload, strlen(payload) + 1u);

    /* ignore errors: attempt to read non-existing file quietly */
    ignore_errors_example("/does/not/exist.txt");

    /* unsafe_cast_example: pass address of a char -> UB but often harmless */
    char local_char = 0;
    unsafe_cast_example((void *)&local_char);

    /* goto example */
    printf("goto_and_multiple_exit(5) -> %d\n", goto_and_multiple_exit(5));

    /* quietly exit cleanly */
    return 0;
}
