/* c_security_traps.c
 *
 * Purpose: compact collection of common security vulnerabilities and bad practices
 * for testing static analyzers / review pipelines.
 *
 * Build (example): gcc -std=c11 -O2 c_security_traps.c -o c_security_traps
 *
 * NOTE: This file is intentionally insecure. Do NOT use as-is in production.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <fcntl.h>
#include <time.h>

/* 1) Buffer overflow: fixed-size stack buffer + unchecked strcpy */
void vuln_buffer_overflow(const char *s) {
    char buf[32];
    /* strcpy will overflow if s is longer than 31 bytes */
    strcpy(buf, s);
    printf("buf: %s\n", buf);
}

/* 2) Format-string vulnerability: user string used as format */
void vuln_format_string(const char *user) {
    char out[128];
    /* dangerous: user controls format string */
    snprintf(out, sizeof(out), user);
    puts(out);
}

/* 3) Command injection via system() with unsanitized input */
void vuln_command_injection(const char *file) {
    char cmd[256];
    /* attacker-controlled 'file' can inject commands */
    snprintf(cmd, sizeof(cmd), "ls -l %s", file);
    system(cmd); /* insecure */
}

/* 4) Insecure temporary file (TOCTOU and predictable filename) */
int vuln_insecure_tmpfile(void) {
    char tmpname[64];
    pid_t pid = getpid();
    snprintf(tmpname, sizeof(tmpname), "/tmp/app.%d.tmp", (int)pid); /* predictable */
    /* TOCTOU: attacker may create symlink between check and open */
    int fd = open(tmpname, O_CREAT | O_RDWR, 0600);
    return fd;
}

/* 5) Hard-coded credentials */
const char *vuln_hardcoded_password(void) {
    /* Hard-coded secret in binary (easy to extract) */
    return "P@ssw0rd1234!";
}

/* 6) Integer overflow leading to small allocation */
void *vuln_integer_overflow_alloc(size_t count, size_t size) {
    /* naive multiplication can overflow */
    size_t total = count * size; /* overflow possible */
    void *p = malloc(total);
    return p;
}

/* 7) Use-after-free / dangling pointer */
char *vuln_use_after_free(void) {
    char *p = malloc(64);
    if (!p) return NULL;
    strcpy(p, "sensitive");
    free(p);
    /* returning dangling pointer */
    return p;
}

/* 8) Weak randomness for security purposes */
unsigned int vuln_weak_rand(void) {
    /* rand() is not cryptographically secure */
    srand((unsigned)time(NULL));
    return rand();
}

/* 9) Missing bounds check on integer index used for array access */
int vuln_index_out_of_bounds(int idx) {
    int arr[5] = {0,1,2,3,4};
    /* no validation of idx */
    return arr[idx];
}

/* 10) Excessive privileges: opening file world-writable or without least privilege */
int vuln_excess_privilege(const char *path) {
    /* opens with read-write for anyone if file mode later changed, or used in privileged context */
    int fd = open(path, O_RDWR | O_CREAT, 0666); /* overly-permissive permissions */
    return fd;
}

/* Driver to exercise functions (use with caution) */
int main(int argc, char **argv) {
    (void)argc;
    /* 1 */
    vuln_buffer_overflow("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");

    /* 2 */
    vuln_format_string("User input: %s %x %x");

    /* 3 */
    vuln_command_injection("; echo hacked >/tmp/hacked.txt");

    /* 4 */
    int fd = vuln_insecure_tmpfile();
    if (fd >= 0) {
        write(fd, "temp", 4);
        close(fd);
    }

    /* 5 */
    printf("password: %s\n", vuln_hardcoded_password());

    /* 6 */
    void *p = vuln_integer_overflow_alloc((size_t)1 << 31, (size_t)8);
    if (p) free(p);

    /* 7 */
    char *dang = vuln_use_after_free();
    if (dang) printf("dangling: %s\n", dang); /* undefined behavior */

    /* 8 */
    printf("weak rand: %u\n", vuln_weak_rand());

    /* 9 */
    /* intentionally calling with out of range index */
    printf("value: %d\n", vuln_index_out_of_bounds(10)); /* may crash */

    /* 10 */
    int fd2 = vuln_excess_privilege("/tmp/example_perm.txt");
    if (fd2 >= 0) close(fd2);

    return 0;
}
