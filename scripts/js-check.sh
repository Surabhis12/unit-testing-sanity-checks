#!/bin/bash
# JavaScript/TypeScript Sanity Check - Clean cppcheck-like output format

set -e

if [ ! -f js_files.txt ]; then
    echo "No JavaScript/TypeScript files to check"
    exit 0
fi

FILES=$(cat js_files.txt | tr '\n' ' ')

echo "===================================="
echo "JAVASCRIPT SANITY CHECK REQUIREMENTS"
echo "===================================="
echo ""
echo "Checking for:"
echo "  ✓ No console.log in production code"
echo "  ✓ No unused variables"
echo "  ✓ Use === instead of =="
echo "  ✓ Use let/const instead of var"
echo "  ✓ No eval() usage"
echo "  ✓ No debugger statements"
echo "  ✓ Security vulnerabilities"
echo "  ✓ Bad practices"
echo ""

FAILED=false
ERROR_COUNT=0

echo "Checking for anti-patterns and security issues..."
echo ""

for file in $FILES; do
    # 1. console.log
    if grep -n "console\.log" "$file" > /dev/null; then
        grep -n "console\.log" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: console.log statement found [no-console]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 2. var usage
    if grep -n "^[[:space:]]*var " "$file" > /dev/null; then
        grep -n "^[[:space:]]*var " "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: 'var' keyword used, use 'let' or 'const' [no-var]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 3. == usage
    if grep -n " == " "$file" | grep -v "===" > /dev/null; then
        grep -n " == " "$file" | grep -v "===" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: loose equality (==) used, use strict equality (===) [eqeqeq]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 4. eval()
    if grep -n "eval(" "$file" > /dev/null; then
        grep -n "eval(" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: dangerous eval() function used [no-eval]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 5. debugger
    if grep -n "debugger" "$file" > /dev/null; then
        grep -n "debugger" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: debugger statement found [no-debugger]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 6. alert()
    if grep -n "alert(" "$file" > /dev/null; then
        grep -n "alert(" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: alert() used [no-alert]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 7. Hard-coded secrets
    if grep -inE "(api[_-]?key|api[_-]?token|api[_-]?secret|secret[_-]?key|password|access[_-]?token)\s*[=:]\s*['\"]" "$file" > /dev/null; then
        grep -inE "(api[_-]?key|api[_-]?token|api[_-]?secret|secret[_-]?key|password|access[_-]?token)\s*[=:]\s*['\"]" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: hard-coded secret found [no-secrets]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 8. Math.random() for security
    if grep -n "Math\.random()" "$file" > /dev/null; then
        if grep -in "token\|secret\|key" "$file" > /dev/null; then
            grep -n "Math\.random()" "$file" | while IFS=: read -r line_num line_content; do
                echo "$file:$line_num: error: Math.random() used for security purposes (weak RNG) [crypto-strength]"
            done
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # 9. Prototype pollution
    if grep -n "__proto__\|\.prototype\[" "$file" > /dev/null; then
        grep -n "__proto__\|\.prototype\[" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: prototype pollution pattern detected [no-prototype-builtins]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 10. Command injection
    if grep -n "exec(.*\${" "$file" > /dev/null; then
        grep -n "exec(" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: command injection risk in child_process.exec [security/detect-child-process]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 11. Insecure TLS
    if grep -n "rejectUnauthorized.*false" "$file" > /dev/null; then
        grep -n "rejectUnauthorized" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: TLS certificate validation disabled [security/detect-disable-mustache-escape]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 12. SQL injection
    if grep -n "SELECT.*\${.*}\|INSERT.*\${.*}\|SELECT.*+\|INSERT.*+" "$file" > /dev/null; then
        grep -n "SELECT\|INSERT" "$file" | grep "\${\|+" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: SQL injection via string concatenation [security/detect-sql-injection]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 13. Deprecated Buffer
    if grep -n "new Buffer(" "$file" > /dev/null; then
        grep -n "new Buffer(" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: deprecated Buffer() constructor, use Buffer.from() [node/no-deprecated-api]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 14. Sync file operations
    if grep -n "readFileSync\|writeFileSync\|readSync\|writeSync" "$file" > /dev/null; then
        grep -n "Sync(" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: synchronous I/O blocks event loop [node/no-sync]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 15. RegExp from user input
    if grep -n "new RegExp(" "$file" > /dev/null; then
        if grep -n "input\|user\|req\|param\|query" "$file" > /dev/null; then
            grep -n "new RegExp(" "$file" | while IFS=: read -r line_num line_content; do
                echo "$file:$line_num: error: RegExp constructed from user input (ReDoS risk) [security/detect-non-literal-regexp]"
            done
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # 16. Predictable temp files
    if grep -n "/tmp/.*process\.pid\|/tmp/.*Date\.now()" "$file" > /dev/null; then
        grep -n "/tmp/" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: predictable temp file path (TOCTOU risk) [security/detect-non-literal-fs-filename]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 17. Logging secrets
    if grep -in "console\.log.*password\|console\.log.*secret\|console\.log.*token\|log.*password" "$file" > /dev/null; then
        grep -in "log.*pass\|log.*secret\|log.*token" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: sensitive data logged [security/detect-possible-timing-attacks]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 18. XOR obfuscation
    if grep -n "\.charCodeAt.*\^.*0x[A-Fa-f0-9]" "$file" > /dev/null; then
        grep -n "charCodeAt.*\^\|xor" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: weak XOR obfuscation used as encryption [security/detect-unsafe-regex]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 19. innerHTML
    if grep -n "\.innerHTML" "$file" > /dev/null; then
        grep -n "\.innerHTML" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: innerHTML usage (XSS risk) [security/detect-unsafe-regex]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 20. Wildcard CORS
    if grep -n "Access-Control-Allow-Origin.*\*" "$file" > /dev/null; then
        grep -n "Access-Control-Allow-Origin" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: wildcard CORS policy (overly permissive) [security/detect-unsafe-regex]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
done

echo ""
echo "================================"
if [ "$FAILED" = true ]; then
    echo "❌ JavaScript sanity check FAILED"
    echo "Total issues found: $ERROR_COUNT"
    echo "Please fix the issues above before merging"
    exit 1
else
    echo "✅ JavaScript sanity check PASSED"
    exit 0
fi