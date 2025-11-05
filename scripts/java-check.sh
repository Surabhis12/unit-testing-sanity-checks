#!/bin/bash
# Java Sanity Check - Clean cppcheck-like output format

set -e

if [ ! -f java_files.txt ]; then
    echo "No Java files to check"
    exit 0
fi

FILES=$(cat java_files.txt)

echo "==============================="
echo "JAVA SANITY CHECK REQUIREMENTS"
echo "==============================="
echo ""

FAILED=false
ERROR_COUNT=0

for file in $FILES; do
    # Class naming
    if grep -n "^class [a-z]\|^public class [a-z]" "$file" > /dev/null; then
        grep -n "^class [a-z]\|^public class [a-z]" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: class name should be PascalCase [class-naming]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # System.out.println
    if grep -n "System\.out\.println" "$file" > /dev/null; then
        grep -n "System\.out\.println" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: warning: System.out.println used, consider using a logger [system-out]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Wildcard imports
    if grep -n "import .*\.\*;" "$file" > /dev/null; then
        grep -n "import .*\.\*;" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: warning: wildcard import used [wildcard-import]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Hard-coded credentials
    if grep -inE "(password|secret|api[_-]?key|private[_-]?key)\s*=\s*\"" "$file" > /dev/null; then
        grep -inE "(password|secret|api[_-]?key)\s*=\s*\"" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: hard-coded credential found [hardcoded-password]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # SQL injection
    if grep -n "\"SELECT.*+\|\"INSERT.*+\|\"UPDATE.*+\|String.*sql.*=.*+" "$file" > /dev/null; then
        grep -n "\"SELECT.*+\|String.*sql.*=" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: SQL injection via string concatenation [sql-injection]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Command injection
    if grep -n "Runtime\.getRuntime()\.exec\|ProcessBuilder\|\.exec(" "$file" > /dev/null; then
        grep -n "Runtime.*exec\|ProcessBuilder" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: system command execution (command injection risk) [command-injection]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Insecure TLS
    if grep -n "TrustManager\|checkServerTrusted\|getAcceptedIssuers" "$file" > /dev/null; then
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
    
    # Weak randomness
    if grep -n "new Random(System\.currentTimeMillis()" "$file" > /dev/null; then
        grep -n "new Random(" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: weak randomness with predictable seed [insecure-random]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Null pointer patterns
    if grep -n "== null" "$file" > /dev/null && grep -n "\.length()\|\.toString()" "$file" > /dev/null; then
        grep -n "== null" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: warning: potential null pointer dereference [null-dereference]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Resource leaks
    if grep -n "new FileInputStream\|new FileReader\|new BufferedReader" "$file" > /dev/null; then
        if ! grep -n "try-with-resources\|\.close()" "$file" > /dev/null; then
            grep -n "new File.*Stream\|new.*Reader" "$file" | while IFS=: read -r line_num line_content; do
                echo "$file:$line_num: warning: potential resource leak (stream not closed) [resource-leak]"
            done
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # String == comparison
    if grep -n "String.*==\|== new String" "$file" > /dev/null; then
        grep -n "String.*==\|== new String" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: String comparison with ==, use .equals() [string-compare]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # equals() without hashCode()
    if grep -n "public boolean equals(Object" "$file" > /dev/null && ! grep -n "public int hashCode()" "$file" > /dev/null; then
        grep -n "public boolean equals" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: warning: equals() overridden but not hashCode() [missing-hashcode]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Weak MD5/DES
    if grep -n "MessageDigest\.getInstance.*MD5\|Cipher\.getInstance.*DES\|\"MD5\"\|\"DES\"" "$file" > /dev/null; then
        grep -n "MD5\|DES" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: weak cryptography (MD5/DES) [weak-hash]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # AES/ECB mode
    if grep -n "AES/ECB\|Cipher\.getInstance.*AES/ECB" "$file" > /dev/null; then
        grep -n "ECB" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: insecure AES/ECB mode [weak-cipher]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Predictable temp files
    if grep -n "new File(\"/tmp/.*pid()\|File.*tmpdir.*currentTimeMillis" "$file" > /dev/null; then
        grep -n "new File(\"/tmp/\|tmpdir" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: predictable temp file path (TOCTOU risk) [predictable-path]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Unsafe reflection
    if grep -n "Class\.forName\|getDeclaredConstructor\|setAccessible(true)" "$file" > /dev/null; then
        grep -n "Class\.forName\|setAccessible" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: warning: reflection used (potential security risk) [unsafe-reflection]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Integer overflow
    if grep -n "Integer\.MAX_VALUE.*+\|MAX_VALUE.*\*" "$file" > /dev/null; then
        grep -n "MAX_VALUE" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: warning: potential integer overflow [integer-overflow]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Logging secrets
    if grep -in "println.*password\|println.*secret\|log.*password" "$file" > /dev/null; then
        grep -in "println.*pass\|log.*pass" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: sensitive data logged [log-sensitive-data]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
done

echo ""
echo "================================"
if [ "$FAILED" = true ]; then
    echo "❌ Java sanity check FAILED"
    echo "Total issues found: $ERROR_COUNT"
    exit 1
else
    echo "✅ Java sanity check PASSED"
    exit 0
fi