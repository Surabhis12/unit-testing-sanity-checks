#!/bin/bash
echo "Running Java compilation sanity check..."
find . -name "*.java" > sources.txt
if [ -s sources.txt ]; then
  javac @sources.txt
else
  echo "No Java files found."
fi
