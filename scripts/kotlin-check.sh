#!/bin/bash
# Kotlin Sanity Check - Enhanced with comprehensive detection

set -e

if [ ! -f kotlin_files.txt ]; then
    echo "No Kotlin files to check"
    exit 0
fi

FILES=$(cat kotlin_files.txt)

echo "================================"
echo "KOTLIN SANITY CHECK REQUIREMENTS"
echo "================================"
echo ""
echo "Checking for:"
echo "  ✓ No wildcard imports"
echo "  ✓ No multiple statements per line"
echo "  ✓ Security vulnerabilities"
echo "  ✓ Bad practices"
echo ""

FAILED=false
ERROR_COUNT=0

for file in $FILES; do
    # Original checks
    if grep -n "import .*\.\*" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses wildcard imports"
        grep -n "import .*\.\*" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    if grep -n ";.*;" "$file" > /dev/null; then
        echo "❌ ERROR: $file has multiple statements on one line"
        grep -n ";.*;" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Enhanced security and quality checks
    
    # 1. Hard-coded secrets
    if grep -inE "(api[_-]?key|api[_-]?secret|password|secret[_-]?key|access[_-]?token|db[_-]?password)\s*=\s*\"" "$file" > /dev/null; then
        echo "❌ ERROR: $file contains hard-coded secrets"
        grep -inE "(api[_-]?key|api[_-]?secret|password|secret[_-]?key|access[_-]?token)\s*=\s*\"" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 2. Weak randomness
    if grep -n "Random(System\.currentTimeMillis()\|Random(.*\.now()\|Random(.*epochSecond" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses weak randomness (predictable seed)"
        grep -n "Random(" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 3. Logging credentials
    if grep -in "println.*password\|println.*pass\|println.*secret\|println.*token\|log.*password\|log.*pass" "$file" > /dev/null; then
        echo "❌ ERROR: $file logs sensitive data"
        grep -in "println.*pass\|log.*pass" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 4. SQL injection pattern
    if grep -n "SELECT.*FROM\|INSERT.*INTO\|UPDATE.*SET" "$file" > /dev/null; then
        if grep -n "\"SELECT.*\$\|\"INSERT.*\$\|\"UPDATE.*\$\|SELECT.*+.*username" "$file" > /dev/null; then
            echo "❌ ERROR: $file constructs SQL via string concatenation (SQL injection risk)"
            grep -n "SELECT.*\$\|INSERT.*\$\|SELECT.*+" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # 5. Insecure TLS - naive TrustManager
    if grep -n "X509TrustManager\|checkServerTrusted\|getAcceptedIssuers" "$file" > /dev/null; then
        if grep -n "override.*checkServerTrusted.*{}\|getAcceptedIssuers.*arrayOf()" "$file" > /dev/null; then
            echo "❌ ERROR: $file disables TLS certificate validation"
            grep -n "TrustManager\|checkServerTrusted" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # 6. Insecure deserialization
    if grep -n "ObjectInputStream.*readObject()" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses insecure deserialization"
        grep -n "ObjectInputStream\|readObject" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 7. Force unwrap operator !!
    if grep -n "!!" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses !! force-unwrap operator (crash risk)"
        grep -n "!!" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 8. Unsafe cast
    if grep -n " as String\| as Int\| as Map\| as List" "$file" > /dev/null; then
        if ! grep -n " as?" "$file" > /dev/null; then
            echo "❌ ERROR: $file uses unsafe cast 'as' (runtime exception risk)"
            grep -n " as String\| as Int\| as Map" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # 9. Empty catch blocks
    if grep -Pzo "catch\s*\([^)]*\)\s*\{\s*\}" "$file" > /dev/null 2>&1; then
        echo "❌ ERROR: $file has empty catch blocks (swallows errors)"
        grep -n "catch" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 10. Command injection via Runtime.exec
    if grep -n "Runtime\.getRuntime()\.exec\|exec(.*sh.*-c\|exec(arrayOf.*sh" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses shell command execution (command injection risk)"
        grep -n "Runtime.*exec\|exec(.*sh" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 11. Weak hashing (MD5)
    if grep -n "MessageDigest\.getInstance.*MD5\|getInstance.*\"MD5\"" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses weak MD5 hashing"
        grep -n "MD5\|MessageDigest" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 12. XOR obfuscation as encryption
    if grep -n "xor.*0x[A-Fa-f0-9]\|encrypt.*xor\|obfuscate\|\.xor" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses weak XOR obfuscation as encryption"
        grep -n "xor\|obfuscate" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 13. Predictable temp files
    if grep -n "/tmp/\|java\.io\.tmpdir" "$file" > /dev/null; then
        if grep -n "pid()\|currentTimeMillis()\|ProcessHandle" "$file" > /dev/null; then
            echo "❌ ERROR: $file creates predictable temp files (TOCTOU risk)"
            grep -n "/tmp/\|tmpdir" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # 14. RegExp from user input
    if grep -n "Regex(" "$file" > /dev/null; then
        if grep -n "pattern\|input\|user\|param" "$file" > /dev/null; then
            echo "❌ ERROR: $file creates RegExp from user input (ReDoS risk)"
            grep -n "Regex(" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # 15. Global mutable state
    if grep -n "^var GLOBAL\|^var [A-Z_]*CACHE\|^var [A-Z_]*STORE" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses global mutable state"
        grep -n "^var GLOBAL\|^var.*CACHE\|^var.*STORE" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 16. Reflection without validation
    if grep -n "Class\.forName\|getDeclaredConstructor\|newInstance" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses reflection (potential security risk)"
        grep -n "Class\.forName\|getDeclaredConstructor\|newInstance" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 17. Blocking I/O
    if grep -n "\.readText()\|\.readBytes()\|\.readLines()\|\.writeText(" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses blocking I/O (bad for UI/server threads)"
        grep -n "\.read\|\.write" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 18. Weak crypto (ECB mode)
    if grep -n "AES/ECB\|Cipher\.getInstance.*AES/ECB" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses insecure AES/ECB mode"
        grep -n "ECB\|Cipher\.getInstance" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
done


echo ""
echo "================================"
if [ "$FAILED" = true ]; then
    echo "❌ Kotlin sanity check FAILED"
    echo "Total issues found: $ERROR_COUNT"
    echo "Please fix the issues above before merging"
    exit 1
else
    echo "✅ Kotlin sanity check PASSED"
    exit 0
fi