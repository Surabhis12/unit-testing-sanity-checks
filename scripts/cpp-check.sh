#!/bin/bash

# C/C++ static analysis using cppcheck

set -e

if [ ! -f cpp_files.txt ]; then
    echo "No C/C++ files to check"
    exit 0
fi

FILES=$(cat cpp_files.txt | tr '\n' ' ')

echo "Running cppcheck on C/C++ files..."
echo "Files: $FILES"
echo ""

# Run cppcheck with common options
cppcheck --enable=warning,style,performance,portability \
         --error-exitcode=1 \
         --inline-suppr \
         --suppress=missingIncludeSystem \
         --quiet \
         $FILES

echo "cppcheck completed successfully"