#!/bin/bash

# Main orchestrator for running language-specific checks

set -e

source detected_languages.env

OVERALL_STATUS=0

echo "=== Running Sanity Checks ==="
echo ""

# Run C/C++ checks
if [ "$HAS_CPP" = true ]; then
    echo "━━━ C/C++ Analysis ━━━"
    if bash scripts/cpp-check.sh; then
        echo "✓ C/C++ checks passed"
    else
        echo "✗ C/C++ checks failed"
        OVERALL_STATUS=1
    fi
    echo ""
fi

# Run JavaScript checks
if [ "$HAS_JS" = true ]; then
    echo "━━━ JavaScript/TypeScript Analysis ━━━"
    if bash scripts/js-check.sh; then
        echo "✓ JavaScript/TypeScript checks passed"
    else
        echo "✗ JavaScript/TypeScript checks failed"
        OVERALL_STATUS=1
    fi
    echo ""
fi

# Run Rust checks
if [ "$HAS_RUST" = true ]; then
    echo "━━━ Rust Analysis ━━━"
    if bash scripts/rust-check.sh; then
        echo "✓ Rust checks passed"
    else
        echo "✗ Rust checks failed"
        OVERALL_STATUS=1
    fi
    echo ""
fi

# Run Kotlin checks
if [ "$HAS_KOTLIN" = true ]; then
    echo "━━━ Kotlin Analysis ━━━"
    if bash scripts/kotlin-check.sh; then
        echo "✓ Kotlin checks passed"
    else
        echo "✗ Kotlin checks failed"
        OVERALL_STATUS=1
    fi
    echo ""
fi

# Run Swift checks
if [ "$HAS_SWIFT" = true ]; then
    echo "━━━ Swift Analysis ━━━"
    if bash scripts/swift-check.sh; then
        echo "✓ Swift checks passed"
    else
        echo "✗ Swift checks failed"
        OVERALL_STATUS=1
    fi
    echo ""
fi

# Run Java checks
if [ "$HAS_JAVA" = true ]; then
    echo "━━━ Java Analysis ━━━"
    if bash scripts/java-check.sh; then
        echo "✓ Java checks passed"
    else
        echo "✗ Java checks failed"
        OVERALL_STATUS=1
    fi
    echo ""
fi

# Run Flutter checks
if [ "$HAS_FLUTTER" = true ]; then
    echo "━━━ Flutter/Dart Analysis ━━━"
    if bash scripts/flutter-check.sh; then
        echo "✓ Flutter/Dart checks passed"
    else
        echo "✗ Flutter/Dart checks failed"
        OVERALL_STATUS=1
    fi
    echo ""
fi

echo "=== Summary ==="
if [ $OVERALL_STATUS -eq 0 ]; then
    echo "✅ All sanity checks passed!"
else
    echo "❌ Some sanity checks failed. Please review the output above."
fi

exit $OVERALL_STATUS