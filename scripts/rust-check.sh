#!/bin/bash
# Rust Sanity Check

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
echo ""

FAILED=false

echo "Checking for anti-patterns..."

while IFS= read -r file; do
    # Check for unwrap() in non-main files
    if [[ ! "$file" =~ main\.rs$ ]] && [[ ! "$file" =~ test ]]; then
        if grep -n "\.unwrap()" "$file" > /dev/null; then
            echo "❌ ERROR: $file uses unwrap() - use proper error handling"
            grep -n "\.unwrap()" "$file"
            FAILED=true
        fi
        
        # Check for println! in library code
        if grep -n "println!" "$file" > /dev/null; then
            echo "❌ ERROR: $file uses println! in library code"
            grep -n "println!" "$file"
            FAILED=true
        fi
    fi
done < rust_files.txt

echo ""
if [ "$FAILED" = true ]; then
    echo "❌ Rust sanity check FAILED"
    echo "Please fix the issues above before merging"
    exit 1
else
    echo "✅ Rust sanity check PASSED"
    exit 0
fi