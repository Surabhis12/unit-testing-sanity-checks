#!/bin/bash
# Flutter/Dart Sanity Check - Clean cppcheck-like output format

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

FAILED=false
ERROR_COUNT=0

for file in $FILES; do
    # print() statements
    if grep -n "print(" "$file" > /dev/null; then
        grep -n "print(" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: warning: print() used, consider debugPrint() or logging [avoid-print]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Lowercase class names
    if grep -n "^class [a-z]" "$file" > /dev/null; then
        grep -n "^class [a-z]" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: class name should be PascalCase [class-naming]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Hard-coded secrets
    if grep -inE "(api[_-]?key|api[_-]?secret|password|secret[_-]?key)\s*=\s*['\"]" "$file" > /dev/null; then
        grep -inE "(api.*key|secret|password|token)\s*=\s*['\"]" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: hard-coded secret found [hardcoded-secret]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Weak randomness
    if grep -n "Random(DateTime\.now()\|Random(.*millisecondsSinceEpoch)" "$file" > /dev/null; then
        grep -n "Random(" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: weak randomness with predictable seed [insecure-random]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Logging secrets
    if grep -in "print.*password\|print.*secret\|print.*token" "$file" > /dev/null; then
        grep -in "print.*pass\|print.*secret\|print.*token" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: sensitive data logged [log-sensitive-data]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Insecure HTTP
    if grep -n "badCertificateCallback.*=.*true\|badCertificateCallback.*=>.*true" "$file" > /dev/null; then
        grep -n "badCertificateCallback" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: certificate validation disabled (insecure TLS) [insecure-tls]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Predictable temp files
    if grep -n "/tmp/\|systemTemp" "$file" > /dev/null && grep -n "pid()\|Platform\.pid\|millisecond" "$file" > /dev/null; then
        grep -n "/tmp/\|systemTemp" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: predictable temp file path (TOCTOU risk) [predictable-path]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Unsafe JSON
    if grep -n "json\.decode\|jsonDecode" "$file" > /dev/null && grep -n "as Map\|as dynamic" "$file" > /dev/null; then
        grep -n "json\.decode\|as Map" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: warning: unsafe JSON casting without validation [unsafe-json-cast]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # SQL injection
    if grep -n "SELECT.*\$\|INSERT.*\$\|UPDATE.*\$" "$file" > /dev/null; then
        grep -n "SELECT.*\$\|INSERT.*\$" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: SQL injection via string interpolation [sql-injection]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # RegExp from user input
    if grep -n "RegExp(" "$file" > /dev/null && grep -n "pattern\|input\|user" "$file" > /dev/null; then
        grep -n "RegExp(" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: RegExp from user input (ReDoS risk) [redos]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Unawaited futures
    if grep -n "Future\.delayed\|Future\." "$file" | grep -v "await" > /dev/null; then
        grep -n "Future\." "$file" | grep -v "await" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: warning: unawaited future (fire-and-forget) [unawaited-future]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Null assertion operator !
    if grep -n "!\[.*\]\|!;" "$file" > /dev/null; then
        grep -n "!\[.*\]\|!;" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: null assertion operator ! used (crash risk) [null-assertion]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Dynamic misuse
    if grep -n "dynamic.*as int\|dynamic.*as String\|dynamic.*as Map" "$file" > /dev/null; then
        grep -n "dynamic.*as " "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: unsafe dynamic type casting [unsafe-cast]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # XOR obfuscation
    if grep -n "\\^.*0x[A-Fa-f0-9]\|xor.*encrypt" "$file" > /dev/null; then
        grep -n "\\^.*0x\|xor\|obfuscate" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: weak XOR obfuscation used as encryption [weak-crypto]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Sync blocking I/O
    if grep -n "readAsStringSync\|writeAsStringSync\|readAsBytesSync" "$file" > /dev/null; then
        grep -n "Sync(" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: synchronous blocking I/O [blocking-io]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Weak MD5
    if grep -in "md5\|MD5\|weakMd5" "$file" > /dev/null; then
        grep -in "md5\|MD5" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: weak MD5 hashing used [weak-hash]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Late variables
    if grep -n "^[[:space:]]*late " "$file" > /dev/null; then
        grep -n "^[[:space:]]*late " "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: warning: late variable used (ensure proper initialization) [late-variable]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Command execution
    if grep -n "Process\.run\|Process\.start" "$file" > /dev/null && grep -n "sh.*-c\|\$(" "$file" > /dev/null; then
        grep -n "Process\.run\|Process\.start" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: shell command execution (command injection risk) [command-injection]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
done

echo ""
echo "================================"
if [ "$FAILED" = true ]; then
    echo "❌ Flutter/Dart sanity check FAILED"
    echo "Total issues found: $ERROR_COUNT"
    exit 1
else
    echo "✅ Flutter/Dart sanity check PASSED"
    exit 0
fi