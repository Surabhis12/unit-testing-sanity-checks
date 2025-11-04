#!/bin/bash
# Java Sanity Check - Enhanced with comprehensive detection

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
echo "Checking for:"
echo "  ✓ Proper class naming (PascalCase)"
echo "  ✓ No System.out.println (use logger)"
echo "  ✓ No wildcard imports"
echo "  ✓ Security vulnerabilities"
echo "  ✓ Common bugs and anti-patterns"
echo ""

FAILED=false
ERROR_COUNT=0

for file in $FILES; do
    # Original checks
    if grep -n "^class [a-z]\|^public class [a-z]" "$file" > /dev/null; then
        echo "❌ ERROR: $file has class with lowercase name (should be PascalCase)"
        grep -n "^class [a-z]\|^public class [a-z]" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    if grep -n "System\.out\.println" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses System.out.println - consider using a logger"
        grep -n "System\.out\.println" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    if grep -n "import .*\.\*;" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses wildcard imports"
        grep -n "import .*\.\*;" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Enhanced security and quality checks
    
    # 1. Hard-coded credentials
    if grep -inE "(password|secret|api[_-]?key|private[_-]?key|access[_-]?token|db[_-]?password)\s*=\s*\"" "$file" > /dev/null; then
        echo "❌ ERROR: $file contains hard-coded credentials"
        grep -inE "(password|secret|api[_-]?key|private[_-]?key|access[_-]?token)\s*=\s*\"" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 2. SQL injection pattern
    if grep -n "SELECT.*FROM\|INSERT.*INTO\|UPDATE.*SET\|DELETE.*FROM" "$file" > /dev/null; then
        if grep -n "\"SELECT.*+\|\"INSERT.*+\|\"UPDATE.*+\|\"DELETE.*+\|String.*sql.*=.*+.*username" "$file" > /dev/null; then
            echo "❌ ERROR: $file constructs SQL via string concatenation (SQL injection risk)"
            grep -n "\"SELECT.*+\|\"INSERT.*+\|String.*sql.*=.*+" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # 3. Command injection
    if grep -n "Runtime\.getRuntime()\.exec\|ProcessBuilder\|\.exec(" "$file" > /dev/null; then
        echo "❌ ERROR: $file executes system commands (command injection risk)"
        grep -n "Runtime.*exec\|ProcessBuilder\|\.exec(" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 4. Insecure TLS
    if grep -n "TrustManager\|X509TrustManager\|checkServerTrusted\|getAcceptedIssuers" "$file" > /dev/null; then
        echo "❌ ERROR: $file disables TLS certificate validation"
        grep -n "TrustManager\|checkServerTrusted\|getAcceptedIssuers" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 5. Insecure deserialization
    if grep -n "ObjectInputStream.*readObject()" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses insecure deserialization (gadget attack risk)"
        grep -n "ObjectInputStream\|readObject" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 6. Weak randomness
    if grep -n "new Random(System\.currentTimeMillis()\|new Random(.*\.getTime()" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses weak randomness (predictable seed)"
        grep -n "new Random(" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 7. Null pointer patterns
    if grep -n "== null" "$file" > /dev/null; then
        if grep -n "\.length()\|\.toString()\|\.getName()" "$file" > /dev/null; then
            echo "❌ ERROR: $file has potential null pointer dereference"
            grep -n "== null" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # 8. Resource leaks
    if grep -n "new FileInputStream\|new FileReader\|new BufferedReader\|new FileOutputStream" "$file" > /dev/null; then
        if ! grep -n "try-with-resources\|\.close()\|finally" "$file" > /dev/null; then
            echo "❌ ERROR: $file may have resource leaks (streams not closed)"
            grep -n "new File.*Stream\|new.*Reader\|new.*Writer" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # 9. String comparison with ==
    if grep -n "String.*==\|== new String\|\".*\" == " "$file" > /dev/null; then
        echo "❌ ERROR: $file uses == for String comparison (use .equals())"
        grep -n "String.*==\|== new String" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 10. equals() without hashCode()
    if grep -n "public boolean equals(Object" "$file" > /dev/null; then
        if ! grep -n "public int hashCode()" "$file" > /dev/null; then
            echo "❌ ERROR: $file overrides equals() but not hashCode()"
            grep -n "public boolean equals" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # 11. Empty catch blocks
    if grep -Pzo "catch\s*\([^)]*\)\s*\{\s*\}" "$file" > /dev/null 2>&1; then
        echo "❌ ERROR: $file has empty catch blocks (swallows exceptions)"
        grep -n "catch" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 12. Weak crypto (MD5, DES)
    if grep -n "MessageDigest\.getInstance.*MD5\|Cipher\.getInstance.*DES\|\"MD5\"\|\"DES\"" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses weak cryptography (MD5/DES)"
        grep -n "MD5\|DES\|MessageDigest\|Cipher" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 13. ECB mode encryption
    if grep -n "AES/ECB\|Cipher\.getInstance.*AES/ECB" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses insecure AES/ECB mode"
        grep -n "ECB\|Cipher\.getInstance" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 14. Predictable temp files
    if grep -n "new File(\"/tmp/\|File.*tmpdir" "$file" > /dev/null; then
        if grep -n "pid()\|currentTimeMillis\|ProcessHandle" "$file" > /dev/null; then
            echo "❌ ERROR: $file creates predictable temp files (TOCTOU risk)"
            grep -n "new File(\"/tmp/\|File.*tmpdir" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # 15. XOR as encryption
    if grep -n "\\^.*0x[A-Fa-f0-9]\|xor.*encrypt\|xor.*cipher" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses weak XOR obfuscation as encryption"
        grep -n "\\^\|xor" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 16. Reflection without validation
    if grep -n "Class\.forName\|getDeclaredConstructor\|newInstance\|setAccessible(true)" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses reflection (potential security risk)"
        grep -n "Class\.forName\|getDeclaredConstructor\|newInstance\|setAccessible" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 17. Path traversal
    if grep -n "new File.*+\|File.*resolve\|readString\|readAllBytes" "$file" > /dev/null; then
        if grep -n "user\|input\|param\|request" "$file" > /dev/null; then
            echo "❌ ERROR: $file has potential path traversal vulnerability"
            grep -n "new File.*+\|resolve" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # 18. Integer overflow
    if grep -n "Integer\.MAX_VALUE.*+\|MAX_VALUE.*\*\|Integer\.MAX_VALUE.*-" "$file" > /dev/null; then
        echo "❌ ERROR: $file has potential integer overflow"
        grep -n "MAX_VALUE" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 19. Logging sensitive data
    if grep -in "println.*password\|println.*secret\|println.*token\|log.*password\|log.*pass" "$file" > /dev/null; then
        echo "❌ ERROR: $file logs sensitive data"
        grep -in "println.*pass\|log.*pass\|println.*secret" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 20. Infinite recursion
    if grep -n "factorial.*factorial(n)\|recursion.*recursion(" "$file" > /dev/null; then
        echo "❌ ERROR: $file has potential infinite recursion"
        grep -n "factorial\|recursion" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
   
done


echo ""
echo "================================"
if [ "$FAILED" = true ]; then
    echo "❌ Java sanity check FAILED"
    echo "Total issues found: $ERROR_COUNT"
    echo "Please fix the issues above before merging"
    exit 1
else
    echo "✅ Java sanity check PASSED"
    exit 0
fi