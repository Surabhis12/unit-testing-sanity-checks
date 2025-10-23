#!/bin/bash
# C/C++ Sanity Check with Strict Rules
# This enforces coding standards and catches common issues

set -e

if [ ! -f cpp_files.txt ]; then
    echo "No C/C++ files to check"
    exit 0
fi

FILES=$(cat cpp_files.txt | tr '\n' ' ')

echo "================================"
echo "C/C++ SANITY CHECK REQUIREMENTS"
echo "================================"
echo ""
echo "Checking for:"
echo "  ✓ Uninitialized variables"
echo "  ✓ Memory leaks"
echo "  ✓ Null pointer dereferences"
echo "  ✓ Array bounds violations"
echo "  ✓ Missing return statements"
echo "  ✓ Unused variables/functions"
echo "  ✓ Type mismatches"
echo "  ✓ Buffer overflows"
echo ""
echo "Files to analyze: $FILES"
echo ""

FAILED=false

# Run cppcheck with STRICT rules
echo "Running cppcheck (strict mode)..."
if ! cppcheck \
    --enable=all \
    --error-exitcode=1 \
    --inline-suppr \
    --suppress=missingIncludeSystem \
    --suppress=unmatchedSuppression \
    --check-level=exhaustive \
    --inconclusive \
    --std=c++11 \
    $FILES 2>&1 | tee cppcheck_output.txt; then
    FAILED=true
    echo "❌ cppcheck found issues!"
fi

# Check for common anti-patterns
echo ""
echo "Checking for anti-patterns..."

for file in $FILES; do
    # Check for malloc without free (potential memory leak)
    if grep -n "malloc\|calloc\|realloc" "$file" > /dev/null; then
        if ! grep -n "free" "$file" > /dev/null; then
            echo "⚠️  WARNING: $file uses malloc but no free() found"
            FAILED=true
        fi
    fi
    
    # Check for gets() usage (unsafe)
    if grep -n "gets(" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses unsafe gets() function"
        FAILED=true
    fi
    
    # Check for strcpy without bounds checking
    if grep -n "strcpy(" "$file" > /dev/null; then
        echo "⚠️  WARNING: $file uses strcpy - consider strncpy for safety"
        FAILED=true
    fi
    
    # Check for missing include guards in headers
    if [[ "$file" == *.h ]] || [[ "$file" == *.hpp ]]; then
        if ! grep -q "#ifndef\|#pragma once" "$file"; then
            echo "❌ ERROR: $file missing include guard"
            FAILED=true
        fi
    fi
done

echo ""
if [ "$FAILED" = true ]; then
    echo "❌ C/C++ sanity check FAILED"
    echo "Please fix the issues above before merging"
    exit 1
else
    echo "✅ C/C++ sanity check PASSED"
    exit 0
fi