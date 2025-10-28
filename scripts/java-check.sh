#!/bin/bash
# Java Sanity Check

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
echo ""

FAILED=false

for file in $FILES; do
    # Check for class naming
    if grep -n "^class [a-z]" "$file" > /dev/null; then
        echo "❌ ERROR: $file has class with lowercase name"
        grep -n "^class [a-z]" "$file"
        FAILED=true
    fi
    
    # Check for System.out.println
    if grep -n "System\.out\.println" "$file" > /dev/null; then
        echo "⚠️  WARNING: $file uses System.out.println"
        FAILED=true
    fi
    
    # Check for wildcard imports
    if grep -n "import .*\.\*;" "$file" > /dev/null; then
        echo "⚠️  WARNING: $file uses wildcard imports"
        grep -n "import .*\.\*;" "$file"
        FAILED=true
    fi
done

echo ""
if [ "$FAILED" = true ]; then
    echo "❌ Java sanity check FAILED"
    echo "Please fix the issues above before merging"
    exit 1
else
    echo "✅ Java sanity check PASSED"
    exit 0
fi