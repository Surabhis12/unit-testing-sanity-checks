#!/bin/bash
# Rust Sanity Check - Clean cppcheck-like output format

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
echo "  ✓ Security vulnerabilities"
echo ""

FAILED=false
ERROR_COUNT=0

echo "Checking for anti-patterns and security issues..."
echo ""

while IFS= read -r file; do
    # Check for unwrap() in non-main/non-test files
    if [[ ! "$file" =~ main\.rs$ ]] && [[ ! "$file" =~ test ]]; then
        if grep -n "\.unwrap()" "$file" > /dev/null; then
            grep -n "\.unwrap()" "$file" | while IFS=: read -r line_num line_content; do
                echo "$file:$line_num: error: unwrap() used, use proper error handling [unwrap-used]"
            done
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
        
        if grep -n "\.expect(" "$file" > /dev/null; then
            grep -n "\.expect(" "$file" | while IFS=: read -r line_num line_content; do
                echo "$file:$line_num: error: expect() used, consider proper error handling [expect-used]"
            done
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
        
        if grep -n "println!" "$file" > /dev/null; then
            grep -n "println!" "$file" | while IFS=: read -r line_num line_content; do
                echo "$file:$line_num: error: println! used in library code [print-literal]"
            done
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # Security checks for ALL files
    
    # Hard-coded secrets
    if grep -inE "(api[_-]?key|api[_-]?secret|password|secret[_-]?key|access[_-]?token)\s*[:=]\s*\"" "$file" > /dev/null; then
        grep -inE "(api[_-]?key|api[_-]?secret|password|secret[_-]?key|access[_-]?token)\s*[:=]\s*\"" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: hard-coded secret found [no-hardcoded-secrets]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Weak randomness
    if grep -n "SystemTime::now()" "$file" > /dev/null && grep -n "token\|random\|secret" "$file" > /dev/null; then
        grep -n "SystemTime::now()" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: weak randomness using SystemTime for security purposes [weak-rng]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Command injection
    if grep -n "Command::new.*sh.*-c" "$file" > /dev/null; then
        grep -n "Command::new\|sh.*-c" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: shell command execution (command injection risk) [shell-injection]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Excessive unsafe blocks
    unsafe_count=$(grep -c "unsafe" "$file" 2>/dev/null || echo "0")
    if [ "$unsafe_count" -gt 2 ]; then
        grep -n "unsafe" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: warning: unsafe block requires review ($unsafe_count total) [unsafe-code]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # get_unchecked usage
    if grep -n "get_unchecked" "$file" > /dev/null; then
        grep -n "get_unchecked" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: get_unchecked bypasses bounds checking (unsafe indexing) [unchecked-indexing]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Box::from_raw
    if grep -n "Box::from_raw" "$file" > /dev/null; then
        grep -n "Box::from_raw" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: Box::from_raw usage (potential double-free) [box-from-raw]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Ignored Results
    if grep -n "let _ = .*Result\|let _ = .*\.read\|let _ = .*\.write\|let _ = .*\.open\|let _ = .*\.status" "$file" > /dev/null; then
        grep -n "let _ = " "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: Result/error value ignored [unused-result]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # mem::transmute
    if grep -n "mem::transmute" "$file" > /dev/null; then
        grep -n "mem::transmute" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: mem::transmute bypasses type safety [transmute]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Needless clone
    if grep -n "\.to_string().*\.clone()\|\.clone().*\.clone()" "$file" > /dev/null; then
        grep -n "\.clone()" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: warning: needless clone detected [needless-clone]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Weak XOR obfuscation
    if grep -n "xor.*0x[A-Fa-f0-9]\|0x[A-Fa-f0-9].*xor" "$file" > /dev/null; then
        grep -n "xor" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: weak XOR obfuscation used as encryption [weak-crypto]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Predictable temp files
    if grep -n "/tmp/.*process::id()\|/tmp/.*pid()\|/tmp/.*millisecond" "$file" > /dev/null; then
        grep -n "/tmp/" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: predictable temp file path (TOCTOU risk) [predictable-path]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Box::leak
    if grep -n "Box::leak" "$file" > /dev/null; then
        grep -n "Box::leak" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: warning: intentional memory leak with Box::leak [memory-leak]"
        done
        ERROR_COUNT=$((ERROR_COUNT + 1))
        FAILED=true
    fi
    
    # Panic in production
    if [[ ! "$file" =~ test ]]; then
        if grep -n "panic!\|unimplemented!\|unreachable!" "$file" > /dev/null; then
            grep -n "panic!\|unimplemented!\|unreachable!" "$file" | while IFS=: read -r line_num line_content; do
                echo "$file:$line_num: warning: panic macro used in production code [panic]"
            done
            ERROR_COUNT=$((ERROR_COUNT + 1))
            FAILED=true
        fi
    fi
    
    # Raw pointer operations
    if grep -n "std::ptr::write\|ptr::write\|std::ptr::read" "$file" > /dev/null; then
        grep -n "ptr::write\|ptr::read" "$file" | while IFS=: read -r line_num line_content; do
            echo "$file:$line_num: error: raw pointer operation [raw-pointer-deref]"
        done
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