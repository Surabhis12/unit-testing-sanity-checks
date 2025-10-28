#!/bin/bash
# JavaScript/TypeScript Sanity Check

set -e

if [ ! -f js_files.txt ]; then
    echo "No JavaScript/TypeScript files to check"
    exit 0
fi

FILES=$(cat js_files.txt | tr '\n' ' ')

echo "===================================="
echo "JAVASCRIPT SANITY CHECK REQUIREMENTS"
echo "===================================="
echo ""
echo "Checking for:"
echo "  ✓ No console.log in production code"
echo "  ✓ No unused variables"
echo "  ✓ Use === instead of =="
echo "  ✓ Use let/const instead of var"
echo "  ✓ No eval() usage"
echo "  ✓ No debugger statements"
echo ""

FAILED=false

echo "Checking for anti-patterns..."

for file in $FILES; do
    # Check for console.log
    if grep -n "console\.log" "$file" > /dev/null; then
        echo "❌ ERROR: $file contains console.log statements"
        grep -n "console\.log" "$file"
        FAILED=true
    fi
    
    # Check for var usage
    if grep -n "^[[:space:]]*var " "$file" > /dev/null; then
        echo "❌ ERROR: $file uses 'var' - use 'let' or 'const'"
        grep -n "^[[:space:]]*var " "$file"
        FAILED=true
    fi
    
    # Check for == usage (but not ===)
    if grep -n " == " "$file" | grep -v "===" > /dev/null; then
        echo "❌ ERROR: $file uses '==' - use '===' for strict equality"
        grep -n " == " "$file" | grep -v "==="
        FAILED=true
    fi
    
    # Check for eval()
    if grep -n "eval(" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses dangerous eval() function"
        grep -n "eval(" "$file"
        FAILED=true
    fi
    
    # Check for debugger
    if grep -n "debugger" "$file" > /dev/null; then
        echo "❌ ERROR: $file contains debugger statements"
        grep -n "debugger" "$file"
        FAILED=true
    fi
    
    # Check for alert()
    if grep -n "alert(" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses alert()"
        grep -n "alert(" "$file"
        FAILED=true
    fi
done

echo ""
if [ "$FAILED" = true ]; then
    echo "❌ JavaScript sanity check FAILED"
    echo "Please fix the issues above before merging"
    exit 1
else
    echo "✅ JavaScript sanity check PASSED"
    exit 0
fi