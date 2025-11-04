#!/bin/bash
# Flutter/Dart Sanity Check - Enhanced with comprehensive detection

set -e

if [ ! -f flutter_files.txt ]; then
    echo "No Flutter/Dart files to check"
    exit 0
fi

FILES=$(cat flutter_files.txt)

echo "===================================="
echo "FLUTTER/DART SANITY CHECK REQUIREMENTS"
echo "===================================="
echo ""
echo "Checking for:"
echo "  ✓ No print() in production code"
echo "  ✓ Proper class naming (PascalCase)"
echo "  ✓ Security vulnerabilities"
echo "  ✓ Bad practices"
echo ""

FAILED=false
ERROR_COUNT=0

for file in $FILES; do
    # Original checks
    if grep -n "print(" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses print() - consider using debugPrint() or logging"
        grep -n "print(" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    if grep -n "^class [a-z]" "$file" > /dev/null; then
        echo "❌ ERROR: $file has class with lowercase name (should be PascalCase)"
        grep -n "^class [a-z]" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Enhanced security and quality checks
    
    # 1. Hard-coded secrets
    if grep -inE "(api[_-]?key|api[_-]?secret|password|secret[_-]?key|access[_-]?token)\s*=\s*['\"]" "$file" > /dev/null; then
        echo "❌ ERROR: $file contains hard-coded secrets"
        grep -inE "(api.*key|secret|password|token)\s*=\s*['\"]" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 2. Weak randomness
    if grep -n "Random(DateTime\.now()\|Random(.*millisecondsSinceEpoch)" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses weak randomness (predictable seed)"
        grep -n "Random(" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 3. Logging secrets
    if grep -in "print.*password\|print.*secret\|print.*token\|print.*pass\|print.*api.*key" "$file" > /dev/null; then
        echo "❌ ERROR: $file logs sensitive data"
        grep -in "print.*pass\|print.*secret\|print.*token" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 4. Insecure HTTP client
    if grep -n "badCertificateCallback.*=.*true\|badCertificateCallback.*=>.*true\|badCertificateCallback.*return true" "$file" > /dev/null; then
        echo "❌ ERROR: $file disables certificate validation (insecure TLS)"
        grep -n "badCertificateCallback" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 5. Predictable temp files
    if grep -n "/tmp/\|systemTemp" "$file" > /dev/null; then
        if grep -n "pid()\|Platform\.pid\|millisecond" "$file" > /dev/null; then
            echo "❌ ERROR: $file creates predictable temp files (TOCTOU risk)"
            grep -n "/tmp/\|systemTemp" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # 6. Unsafe JSON parsing
    if grep -n "json\.decode\|jsonDecode" "$file" > /dev/null; then
        if grep -n "as Map\|as dynamic\|as List" "$file" > /dev/null; then
            echo "❌ ERROR: $file uses unsafe JSON casting"
            grep -n "json\.decode\|as Map\|as dynamic" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # 7. SQL injection
    if grep -n "SELECT.*FROM\|INSERT.*INTO\|UPDATE.*SET" "$file" > /dev/null; then
        if grep -n "SELECT.*\$\|INSERT.*\$\|UPDATE.*\$" "$file" > /dev/null; then
            echo "❌ ERROR: $file constructs SQL via string interpolation (SQL injection risk)"
            grep -n "SELECT.*\$\|INSERT.*\$" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # 8. RegExp from user input
    if grep -n "RegExp(" "$file" > /dev/null; then
        if grep -n "pattern\|input\|user\|param" "$file" > /dev/null; then
            echo "❌ ERROR: $file creates RegExp from user input (ReDoS risk)"
            grep -n "RegExp(" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # 9. Unawaited futures
    if grep -n "Future\.delayed\|Future\.wait\|Future\." "$file" > /dev/null; then
        if grep -n "Future\..*;" "$file" | grep -v "await" > /dev/null; then
            echo "❌ ERROR: $file has unawaited futures (fire-and-forget)"
            grep -n "Future\." "$file" | grep -v "await"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # 10. Force unwrap with !
    if grep -n "!\[.*\]\|!;" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses null assertion operator ! (crash risk)"
        grep -n "!\[.*\]\|!;" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 11. Dynamic type misuse
    if grep -n "dynamic.*as int\|dynamic.*as String\|dynamic.*as Map" "$file" > /dev/null; then
        echo "❌ ERROR: $file casts dynamic types unsafely"
        grep -n "dynamic.*as " "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 12. Path traversal
    if grep -n "File(.*\$\|readString.*\$\|writeString.*\$" "$file" > /dev/null; then
        echo "❌ ERROR: $file has potential path traversal vulnerability"
        grep -n "File(.*\$\|readString\|writeString" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 13. XOR obfuscation
    if grep -n "\\^.*0x[A-Fa-f0-9]\|xor.*encrypt\|obfuscate" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses weak XOR obfuscation as encryption"
        grep -n "\\^.*0x\|xor\|obfuscate" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    
    # 14. Empty catch blocks
    if grep -Pzo "catch\s*\([^)]*\)\s*\{\s*\}" "$file" > /dev/null 2>&1; then
        echo "❌ ERROR: $file has empty catch blocks (swallows exceptions)"
        grep -n "catch" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 15. Synchronous blocking I/O
    if grep -n "readAsStringSync\|writeAsStringSync\|readAsBytesSync\|writeAsBytesSync" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses synchronous blocking I/O"
        grep -n "Sync(" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 16. Weak hashing
    if grep -in "md5\|MD5\|weakMd5\|MessageDigest.*MD5" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses weak MD5 hashing"
        grep -in "md5\|MD5" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 17. Late variables
    if grep -n "^[[:space:]]*late " "$file" > /dev/null; then
        echo "❌ ERROR: $file uses late variables (ensure proper initialization)"
        grep -n "^[[:space:]]*late " "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 18. Null safety issues
    if grep -n "\.length.*null\|null.*\.length" "$file" > /dev/null; then
        echo "❌ ERROR: $file has potential null dereference"
        grep -n "\.length" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 19. Command execution patterns
    if grep -n "Process\.run\|Process\.start" "$file" > /dev/null; then
        if grep -n "sh.*-c\|\$(" "$file" > /dev/null; then
            echo "❌ ERROR: $file executes shell commands (command injection risk)"
            grep -n "Process\.run\|Process\.start" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
done

echo ""
echo "================================"
if [ "$FAILED" = true ]; then
    echo "❌ Flutter/Dart sanity check FAILED"
    echo "Total issues found: $ERROR_COUNT"
    echo "Please fix the issues above before merging"
    exit 1
else
    echo "✅ Flutter/Dart sanity check PASSED"
    exit 0
fi