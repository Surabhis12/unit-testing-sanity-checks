#!/bin/bash
echo "Running C/C++ sanity checks..."
cppcheck --enable=all --error-exitcode=1 .
