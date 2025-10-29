#!/bin/bash
# Swift Sanity Check

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
echo "  ✓ No force unwrapping (!!)"
echo "  ✓ No force casts (as!)"
echo ""

FAILED=false

for file in $FILES; do
    # Check for force unwrapping (!!)
    if grep -n "!!" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses force unwrapping (!!)"
        grep -n "!!" "$file"
        FAILED=true
    fi
    
    # Check for force cast (as!)
    if grep -n " as! " "$file" > /dev/null; then
        echo "❌ ERROR: $file uses force cast (as!)"
        grep -n " as! " "$file"
        FAILED=true
    fi
done

echo ""
if [ "$FAILED" = true ]; then
    echo "❌ Swift sanity check FAILED"
    echo "Please fix the issues above before merging"
    exit 1
else
    echo "✅ Swift sanity check PASSED"
    exit 0
fi