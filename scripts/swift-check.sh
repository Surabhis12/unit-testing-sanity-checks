#!/bin/bash
# Swift Sanity Check - Enhanced with comprehensive detection

set -e

if [ ! -f swift_files.txt ]; then
    echo "No Swift files to check"
    exit 0
fi

FILES=$(cat swift_files.txt)

echo "==============================="
echo "SWIFT SANITY CHECK REQUIREMENTS"
echo "==============================="
echo ""
echo "Checking for:"
echo "  ✓ No force unwrapping (!)"
echo "  ✓ No force casts (as!)"
echo "  ✓ Security vulnerabilities"
echo "  ✓ Memory management issues"
echo "  ✓ Bad practices"
echo ""

FAILED=false
ERROR_COUNT=0

for file in $FILES; do
    # Original checks - force unwrapping
    if grep -n "!" "$file" | grep -v "!=" | grep -v "!<" | grep -v "!>" | grep -v "//" | grep -v "print" > /dev/null; then
        echo "❌ ERROR: $file uses force unwrapping (!)"
        grep -n "!" "$file" | grep -v "!=" | grep -v "!<" | grep -v "!>" | grep -v "//"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Force cast
    if grep -n " as! " "$file" > /dev/null; then
        echo "❌ ERROR: $file uses force cast (as!)"
        grep -n " as! " "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Enhanced security and quality checks
    
    # 1. Hard-coded secrets
    if grep -inE "(api[_-]?secret|api[_-]?key|password|secret|token)\s*=\s*\"" "$file" > /dev/null; then
        echo "❌ ERROR: $file contains hard-coded secrets"
        grep -inE "(secret|api.*key|password|token)\s*=\s*\"" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 2. UserDefaults for secrets
    if grep -in "UserDefaults.*set.*secret\|UserDefaults.*set.*password\|UserDefaults.*set.*token\|UserDefaults.*set.*api" "$file" > /dev/null; then
        echo "❌ ERROR: $file stores secrets in UserDefaults (insecure storage)"
        grep -in "UserDefaults.*set" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 3. Insecure TLS
    if grep -n "URLAuthenticationChallenge\|serverTrust!\|useCredential" "$file" > /dev/null; then
        if grep -n "URLSession.*didReceive.*challenge" "$file" > /dev/null; then
            echo "❌ ERROR: $file disables TLS certificate validation"
            grep -n "URLAuthenticationChallenge\|serverTrust" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # 4. Weak randomness
    if grep -n "arc4random\|arc4random_uniform" "$file" > /dev/null; then
        if grep -in "token\|secret\|key\|random" "$file" > /dev/null; then
            echo "❌ ERROR: $file uses arc4random for security purposes (use SecRandomCopyBytes)"
            grep -n "arc4random" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # 5. Weak hashing (MD5)
    if grep -n "CC_MD5\|MD5\|md5" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses weak MD5 hashing"
        grep -n "MD5\|md5\|CC_MD5" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 6. XOR obfuscation
    if grep -n "\\^.*0x[A-Fa-f0-9]\|xor.*encrypt\|xor.*obfuscate\|XOR.*obfuscate" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses weak XOR obfuscation as encryption"
        grep -n "\\^.*0x\|xor" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 7. SQL concatenation
    if grep -n "SELECT.*FROM\|INSERT.*INTO" "$file" > /dev/null; then
        if grep -n "\"SELECT.*\\\\(\|\"INSERT.*\\\\(\|SELECT.*\\\\(.*username" "$file" > /dev/null; then
            echo "❌ ERROR: $file constructs SQL via string interpolation (SQL injection risk)"
            grep -n "SELECT.*\\\\(\|INSERT.*\\\\(" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # 8. Force-try (try!)
    if grep -n "try!" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses try! (will crash on error)"
        grep -n "try!" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 9. Blocking main thread
    if grep -n "String(contentsOfFile:\|Data(contentsOf:\|String(contentsOf:\|contentsOfFile" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses blocking I/O (bad for UI thread)"
        grep -n "contentsOf\|contentsOfFile" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 10. Retain cycle patterns
    if grep -n "Timer.*scheduledTimer\|Timer\.scheduledTimer" "$file" > /dev/null; then
        if ! grep -n "\[weak self\]\|\[unowned self\]" "$file" > /dev/null; then
            echo "❌ ERROR: $file may have retain cycle in Timer closure"
            grep -n "Timer" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # 11. Empty catch blocks
    if grep -Pzo "catch\s*\{[^}]*\}" "$file" 2>/dev/null | grep -Pzo "catch\s*\{\s*\}" > /dev/null 2>&1; then
        echo "❌ ERROR: $file has empty catch blocks (swallows errors)"
        grep -n "catch" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 12. Predictable temp files
    if grep -n "NSTemporaryDirectory\|/tmp/" "$file" > /dev/null; then
        if grep -n "processIdentifier\|getpid()\|pid" "$file" > /dev/null; then
            echo "❌ ERROR: $file creates predictable temp files (TOCTOU risk)"
            grep -n "NSTemporaryDirectory\|/tmp/" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # 13. Force cast Any types
    if grep -n "Any.*as!\|as! Int\|as! String\|as! \[" "$file" > /dev/null; then
        echo "❌ ERROR: $file force-casts Any types (runtime crash risk)"
        grep -n "Any.*as!\|as! Int\|as! String" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 14. Global mutable state
    if grep -n "^var GLOBAL\|^var [A-Z_]*CACHE\|^var [A-Z_]*STORE" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses global mutable state"
        grep -n "^var GLOBAL\|^var.*CACHE\|^var.*STORE" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 15. RegExp from user input
    if grep -n "NSRegularExpression\|try.*NSRegularExpression" "$file" > /dev/null; then
        if grep -n "pattern:\|input\|user\|param" "$file" > /dev/null; then
            echo "❌ ERROR: $file creates RegExp from user input (ReDoS risk)"
            grep -n "NSRegularExpression" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # 16. Implicitly unwrapped optionals
    if grep -n "var.*:.*!\|let.*:.*!" "$file" | grep -v "//" | grep -v "@IB" > /dev/null; then
        echo "❌ ERROR: $file uses implicitly unwrapped optionals"
        grep -n "var.*:.*!\|let.*:.*!" "$file" | grep -v "//" | grep -v "@IB"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 17. Unowned reference captures
    if grep -n "\[unowned self\]" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses unowned self (dangling pointer risk)"
        grep -n "\[unowned self\]" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
done

echo ""
echo "================================"
if [ "$FAILED" = true ]; then
    echo "❌ Swift sanity check FAILED"
    echo "Total issues found: $ERROR_COUNT"
    echo "Please fix the issues above before merging"
    exit 1
else
    echo "✅ Swift sanity check PASSED"
    exit 0
fi