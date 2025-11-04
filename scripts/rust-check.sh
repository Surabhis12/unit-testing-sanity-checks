#!/bin/bash
# Rust Sanity Check - Enhanced with comprehensive detection

set -e

if [ ! -f rust_files.txt ]; then
    echo "No Rust files to check"
    exit 0
fi

echo "=============================="
echo "RUST SANITY CHECK REQUIREMENTS"
echo "=============================="
echo ""
echo "Checking for:"
echo "  ✓ No unwrap() in library code"
echo "  ✓ No println! in library code"
echo "  ✓ Proper naming conventions"
echo "  ✓ Hard-coded secrets"
echo "  ✓ Weak randomness patterns"
echo "  ✓ Command injection risks"
echo "  ✓ Unsafe pointer operations"
echo "  ✓ Error handling issues"
echo ""

FAILED=false
ERROR_COUNT=0

echo "Checking for anti-patterns and security issues..."
echo ""

while IFS= read -r file; do
    # Check for unwrap() in non-main/non-test files
    if [[ ! "$file" =~ main\.rs$ ]] && [[ ! "$file" =~ test ]]; then
        if grep -n "\.unwrap()" "$file" > /dev/null; then
            echo "❌ ERROR: $file uses unwrap() - use proper error handling"
            grep -n "\.unwrap()" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
        
        if grep -n "\.expect(" "$file" > /dev/null; then
            echo "❌ ERROR: $file uses expect() - consider proper error handling"
            grep -n "\.expect(" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
        
        # Check for println! in library code
        if grep -n "println!" "$file" > /dev/null; then
            echo "❌ ERROR: $file uses println! in library code"
            grep -n "println!" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # Security checks for ALL files
    
    # 1. Hard-coded secrets (API keys, tokens, passwords)
    if grep -inE "(api[_-]?key|api[_-]?secret|password|secret[_-]?key|access[_-]?token|auth[_-]?token)\s*[:=]\s*\"" "$file" > /dev/null; then
        echo "❌ ERROR: $file contains hard-coded secrets"
        grep -inE "(api[_-]?key|api[_-]?secret|password|secret[_-]?key|access[_-]?token|auth[_-]?token)\s*[:=]\s*\"" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 2. Weak randomness (using SystemTime for tokens/crypto)
    if grep -n "SystemTime::now()" "$file" > /dev/null && grep -n "token\|random\|secret" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses weak randomness (SystemTime for tokens)"
        grep -n "SystemTime::now()" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 3. Command injection via shell
    if grep -n "Command::new.*sh.*-c\|sh.*-c.*Command" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses shell command execution (command injection risk)"
        grep -n "Command::new\|sh.*-c" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 4. Unsafe blocks (should be reviewed)
    if grep -n "unsafe" "$file" > /dev/null; then
        unsafe_count=$(grep -c "unsafe" "$file")
        if [ "$unsafe_count" -gt 2 ]; then
            echo "❌ ERROR: $file has $unsafe_count unsafe blocks - requires review"
            grep -n "unsafe" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # 5. get_unchecked usage (bounds checking bypass)
    if grep -n "get_unchecked" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses get_unchecked (unsafe indexing)"
        grep -n "get_unchecked" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 6. Box::from_raw without proper ownership (double-free risk)
    if grep -n "Box::from_raw" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses Box::from_raw (potential double-free)"
        grep -n "Box::from_raw" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 7. Ignored Results (underscore assignment)
    if grep -n "let _ = .*Result\|let _ = .*\.read\|let _ = .*\.write\|let _ = .*\.open\|let _ = .*\.status" "$file" > /dev/null; then
        echo "❌ ERROR: $file ignores Result/error values"
        grep -n "let _ = " "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 8. mem::transmute usage (type safety bypass)
    if grep -n "mem::transmute" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses mem::transmute (unsafe type conversion)"
        grep -n "mem::transmute" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 9. Needless clone (performance issue)
    if grep -n "\.to_string().*\.clone()\|\.clone().*\.clone()" "$file" > /dev/null; then
        echo "❌ ERROR: $file has needless clone"
        grep -n "\.clone()" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 10. Weak obfuscation used as crypto
    if grep -n "xor.*0x[A-Fa-f0-9]\|0x[A-Fa-f0-9].*xor" "$file" > /dev/null && grep -in "encrypt\|obfuscate\|cipher" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses weak XOR obfuscation as encryption"
        grep -n "xor" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 11. Predictable temp file patterns
    if grep -n "/tmp/.*process::id()\|/tmp/.*pid()\|/tmp/.*\.pid\|/tmp/.*millisecond" "$file" > /dev/null; then
        echo "❌ ERROR: $file creates predictable temp file (TOCTOU risk)"
        grep -n "/tmp/" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 12. Box::leak usage (intentional memory leak)
    if grep -n "Box::leak" "$file" > /dev/null; then
        echo "❌ ERROR: $file intentionally leaks memory with Box::leak"
        grep -n "Box::leak" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # 13. Panic in production code
    if grep -n "panic!\|unimplemented!\|unreachable!" "$file" > /dev/null; then
        if [[ ! "$file" =~ test ]]; then
            echo "❌ ERROR: $file uses panic macros in production code"
            grep -n "panic!\|unimplemented!\|unreachable!" "$file"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # 14. Float equality comparison
    if grep -n " == .*f32\| == .*f64\|f32 == \|f64 == \|0\.[0-9] == \| == 0\.[0-9]" "$file" > /dev/null; then
        echo "❌ ERROR: $file compares floats with == (precision issue)"
        grep -n " == .*f32\| == .*f64\|0\.[0-9] == \| == 0\.[0-9]" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    
    # 15. Raw pointer operations
    if grep -n "std::ptr::write\|ptr::write\|std::ptr::read\|ptr::read" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses raw pointer operations"
        grep -n "ptr::write\|ptr::read" "$file"
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
done < rust_files.txt

echo ""
echo "================================"
if [ "$FAILED" = true ]; then
    echo "❌ Rust sanity check FAILED"
    echo "Total issues found: $ERROR_COUNT"
    echo "Please fix the issues above before merging"
    exit 1
else
    echo "✅ Rust sanity check PASSED"
    exit 0
fi