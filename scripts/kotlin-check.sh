#!/bin/bash
# Kotlin Sanity Check - Clean cppcheck-like output format

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

FAILED=false
ERROR_COUNT=0

for file in $FILES; do
    # Wildcard imports
    if grep -n "import .*\.\*" "$file" > /dev/null; then
        grep -n "import .*\.\*" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: warning: wildcard import used [no-wildcard-imports]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Multiple statements per line
    if grep -n ";.*;" "$file" > /dev/null; then
        grep -n ";.*;" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: multiple statements on one line [one-statement-per-line]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Hard-coded secrets
    if grep -inE "(api[_-]?key|api[_-]?secret|password|secret[_-]?key)\s*=\s*\"" "$file" > /dev/null; then
        grep -inE "(api[_-]?key|api[_-]?secret|password|secret[_-]?key)\s*=\s*\"" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: hard-coded secret found [no-hardcoded-passwords]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Weak randomness
    if grep -n "Random(System\.currentTimeMillis()\|Random(.*\.now()" "$file" > /dev/null; then
        grep -n "Random(" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: weak randomness with predictable seed [insecure-random]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Logging credentials
    if grep -in "println.*password\|println.*pass\|println.*secret" "$file" > /dev/null; then
        grep -in "println.*pass\|log.*pass" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: sensitive data logged [log-sensitive-data]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # SQL injection
    if grep -n "\"SELECT.*\$\|\"INSERT.*\$\|\"UPDATE.*\$" "$file" > /dev/null; then
        grep -n "SELECT.*\$\|INSERT.*\$" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: SQL injection via string interpolation [sql-injection]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Insecure TLS
    if grep -n "checkServerTrusted.*{}\|getAcceptedIssuers.*arrayOf()" "$file" > /dev/null; then
        grep -n "TrustManager\|checkServerTrusted" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: TLS certificate validation disabled [insecure-tls]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Insecure deserialization
    if grep -n "ObjectInputStream.*readObject()" "$file" > /dev/null; then
        grep -n "ObjectInputStream\|readObject" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: insecure deserialization (gadget attack risk) [unsafe-deserialization]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Force unwrap !!
    if grep -n "!!" "$file" > /dev/null; then
        grep -n "!!" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: force-unwrap operator !! used (crash risk) [unsafe-call]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Unsafe cast
    if grep -n " as String\| as Int\| as Map" "$file" > /dev/null; then
        grep -n " as String\| as Int\| as Map" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: warning: unsafe cast 'as' used (runtime exception risk) [unsafe-cast]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Command injection
    if grep -n "Runtime\.getRuntime()\.exec\|exec(.*sh.*-c" "$file" > /dev/null; then
        grep -n "Runtime.*exec\|exec(.*sh" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: shell command execution (command injection risk) [command-injection]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Weak MD5
    if grep -n "MessageDigest\.getInstance.*MD5\|\"MD5\"" "$file" > /dev/null; then
        grep -n "MD5\|MessageDigest" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: weak MD5 hashing algorithm used [weak-hash]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Predictable temp files
    if grep -n "/tmp/.*pid()\|/tmp/.*currentTimeMillis()" "$file" > /dev/null; then
        grep -n "/tmp/\|tmpdir" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: predictable temp file path (TOCTOU risk) [predictable-path]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # RegExp from user input
    if grep -n "Regex(" "$file" > /dev/null && grep -n "pattern\|input" "$file" > /dev/null; then
        grep -n "Regex(" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: RegExp from user input (ReDoS risk) [redos]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Global mutable state
    if grep -n "^var GLOBAL\|^var [A-Z_]*CACHE" "$file" > /dev/null; then
        grep -n "^var GLOBAL\|^var.*CACHE" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: warning: global mutable state used [avoid-mutable-global-state]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Unsafe reflection
    if grep -n "Class\.forName\|getDeclaredConstructor\|newInstance" "$file" > /dev/null; then
        grep -n "Class\.forName\|newInstance" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: warning: reflection used (potential security risk) [unsafe-reflection]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Blocking I/O
    if grep -n "\.readText()\|\.readBytes()\|\.writeText(" "$file" > /dev/null; then
        grep -n "\.read\|\.write" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: warning: blocking I/O operation [blocking-io]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Weak AES/ECB
    if grep -n "AES/ECB\|Cipher\.getInstance.*AES/ECB" "$file" > /dev/null; then
        grep -n "ECB" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: insecure AES/ECB mode used [weak-cipher]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
done

echo ""
echo "================================"
if [ "$FAILED" = true ]; then
    echo "❌ Kotlin sanity check FAILED"
    echo "Total issues found: $ERROR_COUNT"
    exit 1
else
    echo "✅ Kotlin sanity check PASSED"
    exit 0
fi