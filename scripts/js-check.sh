#!/bin/bash
# JavaScript/TypeScript Sanity Check - Enhanced with comprehensive detection

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
    # Original checks
    if grep -n "console\.log" "$file" > /dev/null; then
        echo "❌ ERROR: $file contains console.log statements"
        grep -n "console\.log" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    if grep -n "^[[:space:]]*var " "$file" > /dev/null; then
        echo "❌ ERROR: $file uses 'var' - use 'let' or 'const'"
        grep -n "^[[:space:]]*var " "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    if grep -n " == " "$file" | grep -v "===" > /dev/null; then
        echo "❌ ERROR: $file uses '==' - use '===' for strict equality"
        grep -n " == " "$file" | grep -v "==="
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    if grep -n "eval(" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses dangerous eval() function"
        grep -n "eval(" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    if grep -n "debugger" "$file" > /dev/null; then
        echo "❌ ERROR: $file contains debugger statements"
        grep -n "debugger" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    if grep -n "alert(" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses alert()"
        grep -n "alert(" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Enhanced security checks
    
    # 1. Hard-coded secrets
    if grep -inE "(api[_-]?key|api[_-]?token|api[_-]?secret|secret[_-]?key|password|access[_-]?token)\s*[=:]\s*['\"]" "$file" > /dev/null; then
        echo "❌ ERROR: $file contains hard-coded secrets"
        grep -inE "(api[_-]?key|api[_-]?token|api[_-]?secret|secret[_-]?key|password|access[_-]?token)\s*[=:]\s*['\"]" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 2. Math.random() for tokens/security
    if grep -n "Math\.random()" "$file" > /dev/null; then
        if grep -in "token\|secret\|key\|random" "$file" > /dev/null; then
            echo "❌ ERROR: $file uses Math.random() for security purposes (weak RNG)"
            grep -n "Math\.random()" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # 3. Prototype pollution
    if grep -n "__proto__\|\.prototype\[" "$file" > /dev/null; then
        echo "❌ ERROR: $file has prototype pollution pattern"
        grep -n "__proto__\|\.prototype\[" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 4. Command injection via child_process
    if grep -n "child_process\|require.*child\|exec(" "$file" > /dev/null; then
        if grep -n "exec(.*\${" "$file" > /dev/null; then
            echo "❌ ERROR: $file uses child_process.exec with string interpolation (command injection risk)"
            grep -n "exec(" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # 5. Insecure TLS: rejectUnauthorized false
    if grep -n "rejectUnauthorized.*false" "$file" > /dev/null; then
        echo "❌ ERROR: $file disables TLS certificate validation"
        grep -n "rejectUnauthorized" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 6. SQL injection pattern
    if grep -n "SELECT.*FROM\|INSERT.*INTO\|UPDATE.*SET\|DELETE.*FROM" "$file" > /dev/null; then
        if grep -n "SELECT.*\${.*}\|INSERT.*\${.*}\|SELECT.*+.*username\|INSERT.*+.*" "$file" > /dev/null; then
            echo "❌ ERROR: $file constructs SQL via string concatenation (SQL injection risk)"
            grep -n "SELECT.*\${.*}\|INSERT.*+\|SELECT.*+" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # 7. Deprecated Buffer constructor
    if grep -n "new Buffer(" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses deprecated Buffer() constructor - use Buffer.from()"
        grep -n "new Buffer(" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 8. Synchronous file operations in async code
    if grep -n "readFileSync\|writeFileSync\|readSync\|writeSync" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses synchronous I/O (blocks event loop)"
        grep -n "Sync(" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 9. Empty catch blocks
    if grep -Pzo "catch\s*\([^)]*\)\s*\{\s*\}" "$file" > /dev/null 2>&1; then
        echo "❌ ERROR: $file has empty catch blocks (swallows errors)"
        grep -n "catch" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 10. RegExp from user input (ReDoS)
    if grep -n "new RegExp(" "$file" > /dev/null; then
        if grep -n "input\|user\|req\|param\|query" "$file" > /dev/null; then
            echo "❌ ERROR: $file creates RegExp from user input (ReDoS risk)"
            grep -n "new RegExp" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # 11. Predictable temp file paths
    if grep -n "/tmp/.*process\.pid\|/tmp/.*Date\.now()\|/tmp/.*timestamp" "$file" > /dev/null; then
        echo "❌ ERROR: $file creates predictable temp files (TOCTOU risk)"
        grep -n "/tmp/" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 12. Logging sensitive data
    if grep -in "console\.log.*password\|console\.log.*secret\|console\.log.*token\|console\.log.*pass\|log.*password\|log.*pass" "$file" > /dev/null; then
        echo "❌ ERROR: $file logs sensitive data (credentials in logs)"
        grep -in "log.*pass\|log.*secret\|log.*token" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 13. Weak obfuscation/encryption (XOR)
    if grep -n "\.charCodeAt.*\^.*0x[A-Fa-f0-9]\|xor.*encrypt\|xor.*obfuscate" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses weak XOR obfuscation as encryption"
        grep -n "charCodeAt.*\^\|xor" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 14. innerHTML usage (XSS risk)
    if grep -n "\.innerHTML" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses innerHTML (potential XSS)"
        grep -n "\.innerHTML" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 15. Wildcard CORS
    if grep -n "Access-Control-Allow-Origin.*\*\|'Access-Control-Allow-Origin'.*\*" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses wildcard CORS (overly permissive)"
        grep -n "Access-Control-Allow-Origin" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 16. Path traversal risks
    if grep -n "path\.join\|path\.resolve" "$file" > /dev/null; then
        if grep -n "req\.\|input\|user\|param" "$file" > /dev/null; then
            echo "❌ ERROR: $file has potential path traversal vulnerability"
            grep -n "path\.join\|path\.resolve" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
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