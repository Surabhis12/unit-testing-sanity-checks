#!/bin/bash

# JavaScript/TypeScript linting using ESLint

set -e

if [ ! -f js_files.txt ]; then
    echo "No JavaScript/TypeScript files to check"
    exit 0
fi

FILES=$(cat js_files.txt | tr '\n' ' ')

echo "Running ESLint on JavaScript/TypeScript files..."
echo "Files to check:"
cat js_files.txt
echo ""

# Ensure ESLint config exists
if [ ! -f .eslintrc.json ]; then
    echo "⚠️  Warning: .eslintrc.json not found, using default config"
    cat > .eslintrc.json <<EOF
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
    "no-unused-vars": "error",
    "no-undef": "error",
    "no-console": "warn",
    "eqeqeq": "error",
    "semi": ["error", "always"],
    "quotes": ["error", "single"]
  }
}
EOF
fi

# Run ESLint with proper error handling
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ESLint Analysis Starting..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Run ESLint and capture both stdout and exit code
set +e  # Don't exit on error
ESLINT_OUTPUT=$(eslint --format=stylish $FILES 2>&1)
ESLINT_EXIT_CODE=$?
set -e  # Re-enable exit on error

echo "$ESLINT_OUTPUT"
echo ""

if [ $ESLINT_EXIT_CODE -eq 0 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ ESLint: No errors found!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 0
else
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ ESLint: Errors detected!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Please fix the linting errors above before merging."
    exit 1
fi