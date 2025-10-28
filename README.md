Automated sanity checks and static analysis for multi-language projects.

An automated GitHub Actions workflow that performs static analysis and syntax validation on Pull Requests across multiple programming languages.

## Overview

This repository contains a multi-language sanity check system that automatically validates code quality before merging. The workflow detects programming languages in Pull Request changes, runs language-specific linters and static analyzers, and reports results directly on the PR.

## Features

- **Automatic Language Detection** - Identifies programming languages from file extensions
- **Conditional Tool Installation** - Only installs tools for detected languages to optimize runtime
- **Multi-Language Support** - C/C++, JavaScript/TypeScript, Rust, Kotlin, Swift, Java, Dart/Flutter
- **PR Integration** - Posts detailed results as comments and applies status labels
- **Merge Protection** - Blocks PRs with failing checks from being merged

## How It Works

The workflow triggers on Pull Request events (opened, synchronize, reopened) and follows this process:

1. **Checkout** - Retrieves the PR code
2. **File Detection** - Identifies changed files by extension
3. **Language Detection** - Determines which languages are present
4. **Tool Installation** - Conditionally installs only required linting tools
5. **Static Analysis** - Runs language-specific check scripts
6. **Results Reporting** - Posts formatted comment on the PR
7. **Status Labeling** - Applies `sanity-check-passed` or `sanity-check-failed` label
8. **Workflow Status** - Fails the workflow if any checks fail

---

## 🚀 How It Works

### Workflow Trigger
Runs automatically on:
- New Pull Request
- PR updated with new commits
- PR reopened

### Execution Steps
1. **Checkout**: Fetches your PR code
2. **Detect Changes**: Identifies modified files
3. **Language Detection**: Determines which languages are present
4. **Install Tools**: Sets up required linters/analyzers
5. **Run Checks**: Executes language-specific sanity scripts
6. **Report Results**: Posts comment on PR with pass/fail status
7. **Apply Label**: Adds `sanity-check-passed` or `sanity-check-failed`
8. **Block Merge**: Fails the workflow if issues found

---

## 📂 Repository Structure
UNIT-TESTING-SANITY-CHECKS/
│
├── .vscode/                     # Local VS Code settings (optional)
│
├── scripts/                     # Core automation scripts
│   ├── cpp-check.sh             # Runs cppcheck for C/C++ code
│   ├── detect-language.sh       # Detects programming language from PR file list
│   ├── flutter-check.sh         # Placeholder for Flutter/Dart validation
│   ├── java-check.sh            # Runs static checks for Java
│   ├── js-check.sh              # Runs eslint for JavaScript
│   ├── kotlin-check.sh          # Executes ktlint checks for Kotlin
│   ├── rust-check.sh            # Runs cargo clippy for Rust
│   ├── swift-check.sh           # Runs swiftlint for Swift
│   ├── run-checks.sh            # Central script to invoke language-specific checks
│   └── test-detection.sh        # Validates detection and routing logic
│
├── test-files/                  # Sample test files per supported language
│   ├── cpp/
│   │   └── good-example.cpp
│   ├── dart/
│   │   └── sample.dart
│   ├── java/
│   │   └── good-example.java
│   ├── javascript/
│   │   └── good-example.js
│   ├── kotlin/
│   │   └── sample.kt
│   ├── rust/
│   │   └── good-example.rs
│   └── swift/
│       └── good-example.swift
│
├── branch_configuration.md      # Notes on branch strategy and workflow testing
└── README.md                    # Documentation, setup steps, and usage guide
'''

### JavaScript/TypeScript (Pattern Matching)
- console.log detection
- var keyword usage
- Loose equality (==) usage
- eval() usage
- debugger statements
- alert() usage

## 📂 Repository Structure
UNIT-TESTING-SANITY-CHECKS/
│
├── .vscode/                     # Local VS Code settings (optional)
│
├── scripts/                     # Core automation scripts
│   ├── cpp-check.sh             # Runs cppcheck for C/C++ code
│   ├── detect-language.sh       # Detects programming language from PR file list
│   ├── flutter-check.sh         # Placeholder for Flutter/Dart validation
│   ├── java-check.sh            # Runs static checks for Java
│   ├── js-check.sh              # Runs eslint for JavaScript
│   ├── kotlin-check.sh          # Executes ktlint checks for Kotlin
│   ├── rust-check.sh            # Runs cargo clippy for Rust
│   ├── swift-check.sh           # Runs swiftlint for Swift
│   ├── run-checks.sh            # Central script to invoke language-specific checks
│   └── test-detection.sh        # Validates detection and routing logic
│
├── test-files/                  # Sample test files per supported language
│   ├── cpp/
│   │   └── good-example.cpp
│   ├── dart/
│   │   └── sample.dart
│   ├── java/
│   │   └── good-example.java
│   ├── javascript/
│   │   └── good-example.js
│   ├── kotlin/
│   │   └── sample.kt
│   ├── rust/
│   │   └── good-example.rs
│   └── swift/
│       └── good-example.swift
│
├── branch_configuration.md      # Notes on branch strategy and workflow testing
└── README.md                    # Documentation, setup steps, and usage guide
'''

### Swift (Pattern Matching)
- Force unwrapping (!!)
- Force casting (as!)

### Java (Pattern Matching)
- Class naming conventions (PascalCase)
- System.out.println usage
- Wildcard imports

### Dart/Flutter (Pattern Matching)
- print() statement detection
- Class naming conventions

## Repository Structure

```
.github/workflows/sanity-check.yml    # Main workflow configuration
scripts/detect-language.sh            # Language detection logic
scripts/run-checks.sh                 # Check orchestration
scripts/cpp-check.sh                  # C/C++ analyzer
scripts/js-check.sh                   # JavaScript analyzer
scripts/rust-check.sh                 # Rust analyzer
scripts/kotlin-check.sh               # Kotlin analyzer
scripts/swift-check.sh                # Swift analyzer
scripts/java-check.sh                 # Java analyzer
scripts/flutter-check.sh              # Dart/Flutter analyzer
test-files/                           # Test cases for each language
README.md                             # This file
```

## Usage

### For Repository Integration

1. Copy the `.github/workflows/sanity-check.yml` file to your repository
2. Copy the `scripts/` directory with all check scripts
3. Ensure scripts are executable: `chmod +x scripts/*.sh`
4. Commit and push to enable the workflow

### For Testing

The `test-files/` directory contains example files:
- `good-example.*` - Code that passes all checks
- `bad-example.*` - Code with intentional violations

Create a Pull Request with these files to verify workflow functionality.

### Expected Behavior

**Passing Checks:**
- Green checkmark in PR status
- Comment: "✅ Sanity Check PASSED"
- Label: `sanity-check-passed`
- PR can be merged

**Failing Checks:**
- Red X in PR status
- Comment with detailed error list
- Label: `sanity-check-failed`
- PR merge blocked

## Configuration

### Workflow File (`.github/workflows/sanity-check.yml`)

Key configuration points:

**Trigger Events:**
```yaml
on:
  pull_request:
    types: [opened, synchronize, reopened]
```

**File Extensions:**
```yaml
files: |
  **/*.c
  **/*.cpp
  **/*.js
  # ... other extensions
```

**Tool Installation:**
Each language has a conditional installation step that only runs if that language is detected.

### Check Scripts (`scripts/*.sh`)

Each check script:
- Reads a list of files from `[language]_files.txt`
- Runs language-specific validation
- Exits with code 0 (pass) or 1 (fail)
- Outputs human-readable results to stdout

### Customization

**To modify checks:**
Edit the relevant script in `scripts/` directory. Each script uses simple pattern matching with `grep` for maximum portability.

**To add new languages:**
1. Add file extensions to workflow YAML
2. Create new check script: `scripts/[language]-check.sh`
3. Add detection logic to `detect-language.sh`
4. Add execution call in `run-checks.sh`

## Implementation Details

### Language Detection

The `detect-language.sh` script:
- Reads `changed_files.txt` containing space-separated file paths
- Uses `case` statement for extension matching
- Creates `[language]_files.txt` for each detected language
- Exports detection results to `detected_languages.env`

### Check Execution

The `run-checks.sh` script:
- Sources `detected_languages.env`
- Runs checks only for detected languages
- Aggregates results
- Exits with combined status code

### Result Reporting

The workflow uses GitHub Actions Script to:
- Read `check_results.txt` containing all check output
- Parse status from text markers
- Format as collapsible comment
- Apply appropriate label
- Set workflow exit status

## Technical Requirements

**GitHub Actions Environment:**
- Ubuntu latest runner
- Node.js 18 (for JavaScript checks)
- Rust stable toolchain (for Rust checks)
- Java 17 (for Java checks)
- System packages: cppcheck (for C/C++ checks)

**Permissions:**
- `contents: read` - Repository access
- `pull-requests: write` - Comment and label management
- `issues: write` - Label management

## Limitations

- Checks are syntax and style focused, not functional testing
- Some tools (ktlint, Flutter) require external downloads
- Swift checks require macOS runner for SwiftLint (currently uses pattern matching)
- No code coverage or complexity analysis
- Binary files are not analyzed

## Validation

This workflow was developed and tested with:
- Multiple test PRs covering all supported languages
- Both passing and failing test cases
- Real-world code examples
- GitHub Actions workflow execution logs

## Future Enhancements

Potential improvements:
- Integration with additional linters (ESLint, Pylint, etc.)
- Configurable rule severity levels
- Support for additional languages (Python, Go, etc.)
- Custom rule definitions per repository
- Performance metrics and check duration reporting

## Contributing

To add new checks or languages:
1. Create check script following existing pattern
2. Test with good and bad example files
3. Update `detect-language.sh` for file detection
4. Update `run-checks.sh` to execute new checks
5. Update this README with new language support

---

## 🎓 Evaluation Criteria

Your setup will be validated by:
1. Creating a PR with test files
2. Verifying workflow runs automatically
3. Checking language detection works
4. Confirming appropriate checks execute
5. Validating PR comment is posted
6. Ensuring correct label is applied

**Task Complete When**: A PR with intentionally bad code triggers the workflow, detects the issues, posts a detailed comment, applies the fail label, and blocks the merge.](https://github.com/Surabhis12/unit-testing-sanity-checks.git)
