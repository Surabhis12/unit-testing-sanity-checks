#!/bin/bash
# Kotlin Sanity Check

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
echo "Checking for:"
echo "  ✓ No wildcard imports"
echo "  ✓ No multiple statements per line"
echo ""

FAILED=false

for file in $FILES; do
    # Check for wildcard imports
    if grep -n "import .*\.\*" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses wildcard imports"
        grep -n "import .*\.\*" "$file"
        FAILED=true
    fi
    
    
    # Check for multiple statements on one line
    if grep -n ";.*;" "$file" > /dev/null; then
        echo "❌ ERROR: $file has multiple statements on one line"
        grep -n ";.*;" "$file"
        FAILED=true
    fi
done

echo ""
if [ "$FAILED" = true ]; then
    echo "❌ Kotlin sanity check FAILED"
    echo "Please fix the issues above before merging"
    exit 1
else
    echo "✅ Kotlin sanity check PASSED"
    exit 0
fi