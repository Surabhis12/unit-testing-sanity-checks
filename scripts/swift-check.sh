#!/bin/bash

# Swift Linting using SwiftLint
# Checks for Swift style and conventions

set -e

echo "Running SwiftLint on Swift files..."
echo ""

# Source language flags
source language_flags.sh

if [ -z "$SWIFT_FILES" ]; then
    echo "⚠️  No Swift files to check"
    exit 0
fi

# Note: SwiftLint is primarily for macOS. On Linux, we'll do basic checks
if ! command -v swiftlint &> /dev/null; then
    echo "⚠️  SwiftLint not available on this platform (Linux)"
    echo "Performing basic syntax validation..."
    
    # Basic checks - look for common issues
    RESULTS_FILE=$(mktemp)
    HAS_ERRORS=false
    
    for file in $SWIFT_FILES; do
        echo "Checking: $file"
        
        # Check for basic syntax issues
        if grep -n "func.*{.*{" "$file" > /dev/null; then
            echo "$file: Warning: Possible missing closing brace" | tee -a "$RESULTS_FILE"
            HAS_ERRORS=true
        fi
        
        # Check for trailing whitespace
        if grep -n " $" "$file" > /dev/null; then
            echo "$file: Warning: Trailing whitespace found" | tee -a "$RESULTS_FILE"
        fi
        
        # Check for TODO/FIXME comments
        if grep -n "TODO\|FIXME" "$file" > /dev/null; then
            echo "$file: Info: TODO/FIXME comments found" | tee -a "$RESULTS_FILE"
        fi
    done
    
    echo ""
    
    if [ "$HAS_ERRORS" = true ] || [ -s "$RESULTS_FILE" ]; then
        echo "**Basic Validation Results:**"
        echo '```'
        cat "$RESULTS_FILE"
        echo '```'
        echo ""
        echo "ℹ️  **Note:** Full SwiftLint checks require macOS environment"
        rm -f "$RESULTS_FILE"
        exit 0
    else
        echo "✅ Basic validation passed"
        rm -f "$RESULTS_FILE"
        exit 0
    fi
else
    # SwiftLint is available, use it
    RESULTS_FILE=$(mktemp)
    HAS_ERRORS=false
    
    echo "Analyzing files with SwiftLint..."
    for file in $SWIFT_FILES; do
        echo "Checking: $file"
        if ! swiftlint lint "$file" 2>&1 | tee -a "$RESULTS_FILE"; then
            HAS_ERRORS=true
        fi
    done
    
    echo ""
    
    if [ "$HAS_ERRORS" = true ] || [ -s "$RESULTS_FILE" ]; then
        echo "**Issues Found:**"
        echo '```'
        cat "$RESULTS_FILE"
        echo '```'
        echo ""
        
        # Count issues
        ERROR_COUNT=$(grep -c "error:" "$RESULTS_FILE" || echo "0")
        WARNING_COUNT=$(grep -c "warning:" "$RESULTS_FILE" || echo "0")
        
        echo "- 🔴 Errors: $ERROR_COUNT"
        echo "- 🟡 Warnings: $WARNING_COUNT"
        
        rm -f "$RESULTS_FILE"
        
        if [ "$ERROR_COUNT" -gt 0 ]; then
            exit 1
        fi
        exit 0
    else
        echo "✅ No issues found"
        rm -f "$RESULTS_FILE"
        exit 0
    fi
fi