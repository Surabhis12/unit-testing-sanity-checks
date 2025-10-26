#!/bin/bash
# Detect languages from changed files

echo "=== Language Detection ==="
echo ""

if [ ! -f changed_files.txt ]; then
    echo "ERROR: changed_files.txt not found"
    exit 1
fi

# Read all changed files (may be space-separated on one line)
CHANGED_FILES=$(cat changed_files.txt)

echo "Changed files:"
echo "$CHANGED_FILES"
echo ""

# Initialize
HAS_CPP=false
HAS_JS=false
HAS_RUST=false
HAS_KOTLIN=false
HAS_SWIFT=false
HAS_JAVA=false
HAS_FLUTTER=false

# Clear old detection files
rm -f cpp_files.txt js_files.txt rust_files.txt kotlin_files.txt swift_files.txt java_files.txt flutter_files.txt

# Convert space-separated list to newline-separated and process
echo "$CHANGED_FILES" | tr ' ' '\n' | while IFS= read -r file; do
    [ -z "$file" ] && continue
    
    case "$file" in
        *.c|*.cpp|*.h|*.hpp)
            HAS_CPP=true
            echo "$file" >> cpp_files.txt
            ;;
        *.js|*.jsx|*.ts|*.tsx)
            HAS_JS=true
            echo "$file" >> js_files.txt
            ;;
        *.rs)
            HAS_RUST=true
            echo "$file" >> rust_files.txt
            ;;
        *.kt)
            HAS_KOTLIN=true
            echo "$file" >> kotlin_files.txt
            ;;
        *.swift)
            HAS_SWIFT=true
            echo "$file" >> swift_files.txt
            ;;
        *.java)
            HAS_JAVA=true
            echo "$file" >> java_files.txt
            ;;
        *.dart)
            HAS_FLUTTER=true
            echo "$file" >> flutter_files.txt
            ;;
    esac
done

# Read what was actually written to files
[ -f cpp_files.txt ] && HAS_CPP=true
[ -f js_files.txt ] && HAS_JS=true
[ -f rust_files.txt ] && HAS_RUST=true
[ -f kotlin_files.txt ] && HAS_KOTLIN=true
[ -f swift_files.txt ] && HAS_SWIFT=true
[ -f java_files.txt ] && HAS_JAVA=true
[ -f flutter_files.txt ] && HAS_FLUTTER=true

# Show detected languages
[ "$HAS_CPP" = true ] && echo "✓ C/C++ detected: $(cat cpp_files.txt 2>/dev/null | wc -l) files"
[ "$HAS_JS" = true ] && echo "✓ JavaScript detected: $(cat js_files.txt 2>/dev/null | wc -l) files"
[ "$HAS_RUST" = true ] && echo "✓ Rust detected: $(cat rust_files.txt 2>/dev/null | wc -l) files"
[ "$HAS_KOTLIN" = true ] && echo "✓ Kotlin detected: $(cat kotlin_files.txt 2>/dev/null | wc -l) files"
[ "$HAS_SWIFT" = true ] && echo "✓ Swift detected: $(cat swift_files.txt 2>/dev/null | wc -l) files"
[ "$HAS_JAVA" = true ] && echo "✓ Java detected: $(cat java_files.txt 2>/dev/null | wc -l) files"
[ "$HAS_FLUTTER" = true ] && echo "✓ Dart detected: $(cat flutter_files.txt 2>/dev/null | wc -l) files"

# Export results
cat > detected_languages.env << EOF
HAS_CPP=$HAS_CPP
HAS_JS=$HAS_JS
HAS_RUST=$HAS_RUST
HAS_KOTLIN=$HAS_KOTLIN
HAS_SWIFT=$HAS_SWIFT
HAS_JAVA=$HAS_JAVA
HAS_FLUTTER=$HAS_FLUTTER
EOF

echo ""
echo "Detection summary:"
cat detected_languages.env
echo ""
echo "✅ Detection complete"