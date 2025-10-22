Unit Testing - Sanity Checks and Static Analysis
Automated sanity checks and static analysis for multi-language projects. This repository provides a GitHub Actions workflow that automatically detects programming languages in pull requests and runs appropriate linting and static analysis tools.

🎯 Overview
This system provides baseline testing for:

C/C++ - cppcheck
JavaScript/TypeScript - eslint
Rust - cargo clippy
Kotlin - ktlint
Swift - swiftlint (basic checks on Linux)
Java - checkstyle
Flutter/Dart - dart analyze
📁 Repository Structure
.
├── .github/
│   └── workflows/
│       └── sanity-check.yml          # Main GitHub Actions workflow
├── scripts/
│   ├── detect-language.sh            # Language detection
│   ├── run-checks.sh                 # Orchestrator for all checks
│   ├── cpp-check.sh                  # C/C++ static analysis
│   ├── js-check.sh                   # JavaScript/TypeScript linting
│   ├── rust-check.sh                 # Rust linting
│   ├── kotlin-check.sh               # Kotlin linting
│   ├── swift-check.sh                # Swift linting
│   ├── java-check.sh                 # Java static analysis
│   └── flutter-check.sh              # Flutter/Dart analysis
├── test-files/                       # Sample files for testing
│   ├── cpp/
│   ├── javascript/
│   ├── rust/
│   ├── kotlin/
│   ├── swift/
│   ├── java/
│   └── flutter/
└── README.md
🚀 Quick Start
For End Users (Testing the Workflow)
Fork or clone this repository
Create a new branch:
bash
   git checkout -b test-sanity-checks
Add or modify files in any supported language
Commit and push:
bash
   git add .
   git commit -m "Test sanity checks"
   git push origin test-sanity-checks
Create a pull request on GitHub
Watch the workflow run automatically!
The workflow will:

✅ Detect the languages in your PR
✅ Run appropriate linting tools
✅ Post results as a PR comment
✅ Apply a sanity-check-passed or sanity-check-failed label
For Developers (Setting Up)
Prerequisites
Git installed on your machine
GitHub account
Basic understanding of Git commands
Initial Setup
Clone the repository:
bash
   git clone https://github.com/YOUR_USERNAME/unit-testing-sanity-checks.git
   cd unit-testing-sanity-checks
Ensure scripts are executable:
bash
   chmod +x scripts/*.sh
Create test files (optional):
bash
   # Example: Create a test C++ file
   mkdir -p test-files/cpp
   echo '#include <iostream>
   int main() {
       std::cout << "Hello, World!" << std::endl;
       return 0;
   }' > test-files/cpp/hello.cpp
Push to GitHub:
bash
   git add .
   git commit -m "Initial setup"
   git push origin main
🔧 How It Works
Workflow Trigger
Current Configuration: The workflow runs on PRs to ALL branches (recommended for comprehensive coverage)

The workflow is triggered on:

Opening a pull request to any branch
Pushing new commits to an existing PR
Reopening a PR
Customizing Branch Triggers
You can customize which branches trigger the workflow by editing .github/workflows/sanity-check.yml:

Option 1: All Branches (Current - Recommended)

yaml
on:
  pull_request:
    types: [opened, synchronize, reopened]
    # No branches filter = runs on all branches
Option 2: Only PRs targeting main branch

yaml
on:
  pull_request:
    types: [opened, synchronize, reopened]
    branches:
      - main
Option 3: Multiple specific branches

yaml
on:
  pull_request:
    types: [opened, synchronize, reopened]
    branches:
      - main
      - develop
      - staging
      - release/*  # Matches release/v1.0, release/v2.0, etc.
Option 4: Exclude certain branches

yaml
on:
  pull_request:
    types: [opened, synchronize, reopened]
    branches-ignore:
      - experimental
      - docs-only
Language Detection
The detect-language.sh script:

Reads all changed files from the PR
Identifies file extensions (.cpp, .js, .rs, etc.)
Creates lists of files for each detected language
Exports environment variables for the orchestrator
Check Execution
The run-checks.sh orchestrator:

Sources the detected languages
Runs language-specific check scripts
Collects results from each language
Returns overall pass/fail status
Result Reporting
The workflow:

Captures all output from the checks
Posts a formatted comment on the PR with
