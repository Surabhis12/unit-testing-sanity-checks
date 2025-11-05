#!/bin/bash
# Swift Sanity Check - Clean cppcheck-like output format

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

FAILED=false
ERROR_COUNT=0

for file in $FILES; do
    # Force unwrapping
    if grep -n "!" "$file" | grep -v "!=" | grep -v "!<" | grep -v "//" > /dev/null; then
        grep -n "!" "$file" | grep -v "!=" | grep -v "!<" | grep -v "//" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: force unwrapping (!) used (crash risk) [force-unwrap]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Force cast
    if grep -n " as! " "$file" > /dev/null; then
        grep -n " as! " "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: force cast (as!) used (crash risk) [force-cast]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Hard-coded secrets
    if grep -inE "(api[_-]?secret|api[_-]?key|password|secret|token)\s*=\s*\"" "$file" > /dev/null; then
        grep -inE "(secret|api.*key|password|token)\s*=\s*\"" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: hard-coded secret found [hardcoded-secret]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # UserDefaults for secrets
    if grep -in "UserDefaults.*set.*secret\|UserDefaults.*set.*password" "$file" > /dev/null; then
        grep -in "UserDefaults.*set" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: secrets stored in UserDefaults (insecure storage) [insecure-storage]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Insecure TLS
    if grep -n "URLAuthenticationChallenge.*useCredential\|serverTrust!" "$file" > /dev/null; then
        grep -n "URLAuthenticationChallenge\|serverTrust" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: TLS certificate validation disabled [insecure-tls]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Weak randomness
    if grep -n "arc4random\|arc4random_uniform" "$file" > /dev/null && grep -in "token\|secret\|key" "$file" > /dev/null; then
        grep -n "arc4random" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: arc4random used for security (use SecRandomCopyBytes) [weak-random]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Weak MD5
    if grep -n "CC_MD5\|MD5\|md5" "$file" > /dev/null; then
        grep -n "MD5\|md5\|CC_MD5" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: weak MD5 hashing used [weak-hash]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # XOR obfuscation
    if grep -n "\\^.*0x[A-Fa-f0-9]\|xor.*encrypt" "$file" > /dev/null; then
        grep -n "\\^.*0x\|xor" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: weak XOR obfuscation used as encryption [weak-crypto]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # SQL injection
    if grep -n "SELECT.*\\\\(\|INSERT.*\\\\(" "$file" > /dev/null; then
        grep -n "SELECT\|INSERT" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: SQL injection via string interpolation [sql-injection]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Force-try
    if grep -n "try!" "$file" > /dev/null; then
        grep -n "try!" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: force-try (try!) used (will crash on error) [force-try]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Blocking main thread
    if grep -n "String(contentsOfFile:\|Data(contentsOf:\|contentsOfFile" "$file" > /dev/null; then
        grep -n "contentsOf\|contentsOfFile" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: blocking I/O on main thread [blocking-main-thread]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Retain cycles
    if grep -n "Timer.*scheduledTimer" "$file" > /dev/null && ! grep -n "\[weak self\]\|\[unowned self\]" "$file" > /dev/null; then
        grep -n "Timer" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: warning: potential retain cycle in Timer closure [retain-cycle]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Predictable temp files
    if grep -n "NSTemporaryDirectory\|/tmp/" "$file" > /dev/null && grep -n "processIdentifier\|pid" "$file" > /dev/null; then
        grep -n "NSTemporaryDirectory\|/tmp/" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: predictable temp file path (TOCTOU risk) [predictable-path]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Force cast Any
    if grep -n "Any.*as!\|as! Int\|as! String" "$file" > /dev/null; then
        grep -n "as! Int\|as! String" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: force-cast on Any type (runtime crash risk) [force-cast-any]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Global mutable state
    if grep -n "^var GLOBAL\|^var [A-Z_]*CACHE" "$file" > /dev/null; then
        grep -n "^var GLOBAL\|^var.*CACHE" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: warning: global mutable state used [mutable-global]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # RegExp from user input
    if grep -n "NSRegularExpression" "$file" > /dev/null && grep -n "pattern:\|input" "$file" > /dev/null; then
        grep -n "NSRegularExpression" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: RegExp from user input (ReDoS risk) [redos]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Implicitly unwrapped optionals
    if grep -n "var.*:.*!\|let.*:.*!" "$file" | grep -v "//" | grep -v "@IB" > /dev/null; then
        grep -n "var.*:.*!\|let.*:.*!" "$file" | grep -v "//" | grep -v "@IB" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: warning: implicitly unwrapped optional used [implicitly-unwrapped-optional]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Unowned captures
    if grep -n "\[unowned self\]" "$file" > /dev/null; then
        grep -n "\[unowned self\]" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: warning: unowned self used (dangling pointer risk) [unowned-reference]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
done

echo ""
echo "================================"
if [ "$FAILED" = true ]; then
    echo "❌ Swift sanity check FAILED"
    echo "Total issues found: $ERROR_COUNT"
    exit 1
else
    echo "✅ Swift sanity check PASSED"
    exit 0
fi