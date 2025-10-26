#!/bin/bash
# Detect languages based on file extensions in changed files

echo "=== Language Detection ==="
echo ""

# Read changed files
if [ ! -f changed_files.txt ]; then
    echo "❌ ERROR: changed_files.txt not found"
    exit 1
fi

# Read files line by line (handles spaces in filenames)
CHANGED_FILES=$(cat changed_files.txt)

echo "Changed files:"
echo "$CHANGED_FILES"
echo ""

# Initialize language flags
HAS_CPP=false
HAS_JS=false
HAS_RUST=false
HAS_KOTLIN=false
HAS_SWIFT=false
HAS_JAVA=false
HAS_FLUTTER=false

# Clear old files
rm -f cpp_files.txt js_files.txt rust_files.txt kotlin_files.txt swift_files.txt java_files.txt flutter_files.txt

# Process each file individually
while IFS= read -r file; do
    # Skip empty lines
    [ -z "$file" ] && continue
    
    # Check C/C++
    if echo "$file" | grep -qE '\.(c|cpp|h|hpp)$'; then
        HAS_CPP=true
        echo "$file" >> cpp_files.txt
    fi
    
    # Check JavaScript/TypeScript
    if echo "$file" | grep -qE '\.(js|jsx|ts|tsx)$'; then
        HAS_JS=true
        echo "$file" >> js_files.txt
    fi
    
    # Check Rust
    if echo "$file" | grep -qE '\.rs$'; then
        HAS_RUST=true
        echo "$file" >> rust_files.txt
    fi
    
    # Check Kotlin
    if echo "$file" | grep -qE '\.kt$'; then
        HAS_KOTLIN=true
        echo "$file" >> kotlin_files.txt
    fi
    
    # Check Swift
    if echo "$file" | grep -qE '\.swift$'; then
        HAS_SWIFT=true
        echo "$file" >> swift_files.txt
    fi
    
    # Check Java
    if echo "$file" | grep -qE '\.java$'; then
        HAS_JAVA=true
        echo "$file" >> java_files.txt
    fi
    
    # Check Dart/Flutter
    if echo "$file" | grep -qE '\.dart$'; then
        HAS_FLUTTER=true
        echo "$file" >> flutter_files.txt
    fi
done <<< "$CHANGED_FILES"

# Show detected languages
if [ "$HAS_CPP" = true ]; then
    echo "✓ C/C++ files detected"
    echo "  Files: $(cat cpp_files.txt | tr '\n' ' ')"
fi

if [ "$HAS_JS" = true ]; then
    echo "✓ JavaScript/TypeScript files detected"
    echo "  Files: $(cat js_files.txt | tr '\n' ' ')"
fi

if [ "$HAS_RUST" = true ]; then
    echo "✓ Rust files detected"
    echo "  Files: $(cat rust_files.txt | tr '\n' ' ')"
fi

if [ "$HAS_KOTLIN" = true ]; then
    echo "✓ Kotlin files detected"
    echo "  Files: $(cat kotlin_files.txt | tr '\n' ' ')"
fi

if [ "$HAS_SWIFT" = true ]; then
    echo "✓ Swift files detected"
    echo "  Files: $(cat swift_files.txt | tr '\n' ' ')"
fi

if [ "$HAS_JAVA" = true ]; then
    echo "✓ Java files detected"
    echo "  Files: $(cat java_files.txt | tr '\n' ' ')"
fi

if [ "$HAS_FLUTTER" = true ]; then
    echo "✓ Flutter/Dart files detected"
    echo "  Files: $(cat flutter_files.txt | tr '\n' ' ')"
fi

# Export flags for use in run-checks.sh
echo "HAS_CPP=$HAS_CPP" > detected_languages.env
echo "HAS_JS=$HAS_JS" >> detected_languages.env
echo "HAS_RUST=$HAS_RUST" >> detected_languages.env
echo "HAS_KOTLIN=$HAS_KOTLIN" >> detected_languages.env
echo "HAS_SWIFT=$HAS_SWIFT" >> detected_languages.env
echo "HAS_JAVA=$HAS_JAVA" >> detected_languages.env
echo "HAS_FLUTTER=$HAS_FLUTTER" >> detected_languages.env

echo ""
echo "Detection summary:"
echo "  C/C++: $HAS_CPP"
echo "  JavaScript: $HAS_JS"
echo "  Rust: $HAS_RUST"
echo "  Kotlin: $HAS_KOTLIN"
echo "  Swift: $HAS_SWIFT"
echo "  Java: $HAS_JAVA"
echo "  Dart/Flutter: $HAS_FLUTTER"

# Check if any language was detected
if [ "$HAS_CPP" = false ] && [ "$HAS_JS" = false ] && [ "$HAS_RUST" = false ] && \
   [ "$HAS_KOTLIN" = false ] && [ "$HAS_SWIFT" = false ] && [ "$HAS_JAVA" = false ] && \
   [ "$HAS_FLUTTER" = false ]; then
    echo ""
    echo "⚠️  No supported language files detected"
    exit 0
fi

echo ""
echo "✅ Language detection completed"