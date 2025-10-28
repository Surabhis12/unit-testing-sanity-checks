#!/bin/bash
# Test language detection locally

echo "Testing Language Detection"
echo "=========================="

# Test JavaScript
echo ""
echo "Test 1: JavaScript Detection"
echo "test-files/javascript/good-example.js" > changed_files.txt
bash scripts/detect-language.sh
echo ""
echo "✓ JS detection test complete"
echo ""

# Test C++
echo "Test 2: C++ Detection"
echo "test-files/cpp/good-example.cpp" > changed_files.txt
bash scripts/detect-language.sh
echo ""
echo "✓ C++ detection test complete"
echo ""

# Test Rust
echo "Test 3: Rust Detection"
echo "test-files/rust/good-example.rs" > changed_files.txt
bash scripts/detect-language.sh
echo ""
echo "✓ Rust detection test complete"
echo ""

# Test Kotlin
echo "Test 4: Kotlin Detection"
echo "test-files/kotlin/good-example.kt" > changed_files.txt
bash scripts/detect-language.sh
echo ""
echo "✓ Kotlin detection test complete"
echo ""

# Test Multiple Files
echo "Test 5: Multiple Languages"
echo -e "test-files/javascript/good-example.js\ntest-files/cpp/good-example.cpp" > changed_files.txt
bash scripts/detect-language.sh
echo ""
echo "✓ Multi-language detection test complete"

echo ""
echo "=========================="
echo "All tests complete!"