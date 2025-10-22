#!/bin/bash

# Detect languages based on file extensions in changed files

echo "=== Language Detection ==="
echo ""

CHANGED_FILES=$(cat changed_files.txt)

# Initialize language flags
HAS_CPP=false
HAS_JS=false
HAS_RUST=false
HAS_KOTLIN=false
HAS_SWIFT=false
HAS_JAVA=false
HAS_FLUTTER=false

# Check for each language
if echo "$CHANGED_FILES" | grep -qE '\.(c|cpp|h|hpp)$'; then
    echo "✓ C/C++ files detected"
    HAS_CPP=true
    echo "$CHANGED_FILES" | grep -E '\.(c|cpp|h|hpp)$' > cpp_files.txt
fi

if echo "$CHANGED_FILES" | grep -qE '\.(js|jsx|ts|tsx)$'; then
    echo "✓ JavaScript/TypeScript files detected"
    HAS_JS=true
    echo "$CHANGED_FILES" | grep -E '\.(js|jsx|ts|tsx)$' > js_files.txt
fi

if echo "$CHANGED_FILES" | grep -qE '\.rs$'; then
    echo "✓ Rust files detected"
    HAS_RUST=true
    echo "$CHANGED_FILES" | grep -E '\.rs$' > rust_files.txt
fi

if echo "$CHANGED_FILES" | grep -qE '\.kt$'; then
    echo "✓ Kotlin files detected"
    HAS_KOTLIN=true
    echo "$CHANGED_FILES" | grep -E '\.kt$' > kotlin_files.txt
fi

if echo "$CHANGED_FILES" | grep -qE '\.swift$'; then
    echo "✓ Swift files detected"
    HAS_SWIFT=true
    echo "$CHANGED_FILES" | grep -E '\.swift$' > swift_files.txt
fi

if echo "$CHANGED_FILES" | grep -qE '\.java$'; then
    echo "✓ Java files detected"
    HAS_JAVA=true
    echo "$CHANGED_FILES" | grep -E '\.java$' > java_files.txt
fi

if echo "$CHANGED_FILES" | grep -qE '\.dart$'; then
    echo "✓ Flutter/Dart files detected"
    HAS_FLUTTER=true
    echo "$CHANGED_FILES" | grep -E '\.dart$' > flutter_files.txt
fi

# Export flags for use in run-checks.sh
echo "HAS_CPP=$HAS_CPP" > detected_languages.env
echo "HAS_JS=$HAS_JS" >> detected_languages.env
echo "HAS_RUST=$HAS_RUST" >> detected_languages.env
echo "HAS_KOTLIN=$HAS_KOTLIN" >> detected_languages.env
echo "HAS_SWIFT=$HAS_SWIFT" >> detected_languages.env
echo "HAS_JAVA=$HAS_JAVA" >> detected_languages.env
echo "HAS_FLUTTER=$HAS_FLUTTER" >> detected_languages.env

if [ "$HAS_CPP" = false ] && [ "$HAS_JS" = false ] && [ "$HAS_RUST" = false ] && \
   [ "$HAS_KOTLIN" = false ] && [ "$HAS_SWIFT" = false ] && [ "$HAS_JAVA" = false ] && \
   [ "$HAS_FLUTTER" = false ]; then
    echo ""
    echo "⚠ No supported language files detected"
    exit 0
fi

echo ""