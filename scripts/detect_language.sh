#!/bin/bash
FILES=$(git diff --name-only origin/main...HEAD)

if echo "$FILES" | grep -E '\.js$|\.jsx$|\.ts$|\.tsx$'; then
  echo "js"
else
  echo "unknown"
fi
