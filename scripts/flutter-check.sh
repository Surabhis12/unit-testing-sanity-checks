#!/bin/bash
# Flutter/Dart Sanity Check

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
echo "Checking for:"
echo "  ✓ No print() in production code"
echo "  ✓ Proper class naming (PascalCase)"
echo ""

FAILED=false

for file in $FILES; do
    # Check for print() statements
    if grep -n "print(" "$file" > /dev/null; then
        echo "⚠️  WARNING: $file uses print()"
        grep -n "print(" "$file"
        FAILED=true
    fi
    
    # Check for class naming
    if grep -n "^class [a-z]" "$file" > /dev/null; then
        echo "❌ ERROR: $file has class with lowercase name"
        grep -n "^class [a-z]" "$file"
        FAILED=true
    fi
done

echo ""
if [ "$FAILED" = true ]; then
    echo "❌ Flutter/Dart sanity check FAILED"
    echo "Please fix the issues above before merging"
    exit 1
else
    echo "✅ Flutter/Dart sanity check PASSED"
    exit 0
fi