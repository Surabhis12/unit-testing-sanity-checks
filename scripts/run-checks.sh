#!/bin/bash
# Run sanity checks

set +e

if [ -f detected_languages.env ]; then
    source detected_languages.env
else
    echo "ERROR: No detected languages"
    exit 1
fi

echo ""
echo "================================"
echo "   RUNNING SANITY CHECKS"
echo "================================"
echo ""

OVERALL_STATUS=0

if [ "$HAS_CPP" = true ]; then
    echo ">>> Running C/C++ checks..."
    if bash scripts/cpp-check.sh; then
        echo "✅ C/C++ checks passed"
    else
        echo "❌ C/C++ checks failed"
        OVERALL_STATUS=1
    fi
    echo ""
fi

if [ "$HAS_JS" = true ]; then
    echo ">>> Running JavaScript checks..."
    if bash scripts/js-check.sh; then
        echo "✅ JavaScript checks passed"
    else
        echo "❌ JavaScript checks failed"
        OVERALL_STATUS=1
    fi
    echo ""
fi

if [ "$HAS_RUST" = true ]; then
    echo ">>> Running Rust checks..."
    if bash scripts/rust-check.sh; then
        echo "✅ Rust checks passed"
    else
        echo "❌ Rust checks failed"
        OVERALL_STATUS=1
    fi
    echo ""
fi

if [ "$HAS_KOTLIN" = true ]; then
    echo ">>> Running Kotlin checks..."
    if bash scripts/kotlin-check.sh; then
        echo "✅ Kotlin checks passed"
    else
        echo "❌ Kotlin checks failed"
        OVERALL_STATUS=1
    fi
    echo ""
fi

if [ "$HAS_SWIFT" = true ]; then
    echo ">>> Running Swift checks..."
    if bash scripts/swift-check.sh; then
        echo "✅ Swift checks passed"
    else
        echo "❌ Swift checks failed"
        OVERALL_STATUS=1
    fi
    echo ""
fi

if [ "$HAS_JAVA" = true ]; then
    echo ">>> Running Java checks..."
    if bash scripts/java-check.sh; then
        echo "✅ Java checks passed"
    else
        echo "❌ Java checks failed"
        OVERALL_STATUS=1
    fi
    echo ""
fi

if [ "$HAS_FLUTTER" = true ]; then
    echo ">>> Running Flutter checks..."
    if bash scripts/flutter-check.sh; then
        echo "✅ Flutter checks passed"
    else
        echo "❌ Flutter checks failed"
        OVERALL_STATUS=1
    fi
    echo ""
fi

echo "================================"
if [ $OVERALL_STATUS -eq 0 ]; then
    echo "✅ ALL SANITY CHECKS PASSED"
    echo "================================"
    exit 0
else
    echo "❌ SANITY CHECKS FAILED"
    echo "================================"
    echo ""
    echo "Please fix the issues listed above."
    echo "The PR cannot be merged until all checks pass."
    exit 1
fi