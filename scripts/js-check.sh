#!/bin/bash
# JavaScript/TypeScript Sanity Check with Strict Rules

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
echo "  ✓ Semicolons required"
echo "  ✓ No eval() usage"
echo "  ✓ No debugger statements"
echo "  ✓ No alert() usage"
echo ""

# Create strict ESLint configuration
cat > .eslintrc.json << 'EOF'
{
  "env": {
    "browser": true,
    "es2021": true,
    "node": true
  },
  "extends": "eslint:recommended",
  "parserOptions": {
    "ecmaVersion": 12,
    "sourceType": "module"
  },
  "rules": {
    "no-console": "error",
    "no-unused-vars": "error",
    "no-undef": "error",
    "semi": ["error", "always"],
    "quotes": ["error", "single"],
    "eqeqeq": "error",
    "no-var": "error",
    "prefer-const": "error",
    "no-debugger": "error",
    "no-alert": "error",
    "no-eval": "error"
  }
}
EOF

FAILED=false

echo "Running ESLint (strict mode)..."
if ! eslint $FILES 2>&1; then
    FAILED=true
    echo "❌ ESLint found issues!"
fi

echo ""
echo "Checking for anti-patterns..."

for file in $FILES; do
    # Check for eval() usage
    if grep -n "eval(" "$file" > /dev/null; then
        echo "❌ ERROR: $file uses dangerous eval() function"
        FAILED=true
    fi
    
    # Check for var usage
    if grep -n "var " "$file" > /dev/null; then
        echo "⚠️  WARNING: $file uses 'var' - use 'let' or 'const'"
        FAILED=true
    fi
    
    # Check for == usage
    if grep -n " == " "$file" > /dev/null; then
        echo "⚠️  WARNING: $file uses '==' - use '===' for strict equality"
        FAILED=true
    fi
    
    # Check for console.log
    if grep -n "console.log" "$file" > /dev/null; then
        echo "❌ ERROR: $file contains console.log statements"
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