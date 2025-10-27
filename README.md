Automated sanity checks and static analysis for multi-language projects.

## 🎯 Purpose

This workflow enforces coding standards and catches common issues **before** code is merged, acting as a first line of defense against bugs, security vulnerabilities, and poor code quality.

---

## 📋 Sanity Check Requirements

### What Gets Checked?

The workflow automatically detects languages in your PR and runs strict checks:

#### **C/C++ Requirements**
- ✅ No memory leaks (malloc must have corresponding free)
- ✅ No buffer overflows (strcpy, gets are flagged)
- ✅ No uninitialized variables
- ✅ All header files must have include guards
- ✅ No null pointer dereferences
- ✅ Proper error handling for divide-by-zero
- ✅ No array bounds violations

**Tool Used**: `cppcheck` with `--check-level=exhaustive`

#### **JavaScript/TypeScript Requirements**
- ✅ No `console.log` statements (production code)
- ✅ No unused variables
- ✅ Must use `===` instead of `==`
- ✅ Must use `let`/`const` instead of `var`
- ✅ Semicolons required
- ✅ No `eval()` usage
- ✅ No `debugger` statements
- ✅ Single quotes for strings

**Tool Used**: `eslint` with strict ruleset

#### **Kotlin Requirements**
- ✅ Proper indentation (4 spaces)
- ✅ No wildcard imports
- ✅ Consistent spacing around operators
- ✅ Max line length: 120 characters
- ✅ Proper brace placement

**Tool Used**: `ktlint`

#### **Rust Requirements**
- ✅ No compiler warnings
- ✅ No clippy warnings
- ✅ Proper error handling (no unwrap in production)
- ✅ Following Rust best practices

**Tool Used**: `cargo clippy`

#### **Swift Requirements**
- ✅ Proper code formatting
- ✅ No force unwrapping (!!)
- ✅ Consistent naming conventions
- ✅ No compiler warnings

**Tool Used**: `swiftlint`

#### **Java Requirements**
- ✅ No compiler warnings
- ✅ Proper formatting
- ✅ No unused imports
- ✅ Consistent code style

**Tool Used**: `javac` with warnings enabled

#### **Flutter/Dart Requirements**
- ✅ Passes `flutter analyze`
- ✅ Proper formatting
- ✅ No linter warnings

**Tool Used**: `flutter analyze`

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

## 🛠️ Setup Instructions

### 1. Copy to Your Repository

```bash
# Clone this repository
git clone <your-repo-url>
cd <your-repo>

# Copy workflow and scripts
mkdir -p .github/workflows scripts
cp sanity-check.yml .github/workflows/
cp scripts/*.sh scripts/

# Make scripts executable
chmod +x scripts/*.sh
```

### 2. Commit and Push

```bash
git add .github/ scripts/
git commit -m "Add sanity check workflow"
git push origin main
```

### 3. Test the Workflow

Create a test PR with intentionally bad code to verify checks catch issues:

```bash
git checkout -b test-sanity-check
# Add test files with issues
git add test-files/cpp/bad-example.cpp
git commit -m "Test: Add code with issues"
git push origin test-sanity-check
```

Create the PR and verify:
- Workflow runs automatically
- Issues are detected
- Comment is posted
- Label is applied
- PR is blocked from merging

---

## 📊 Expected Output

### ✅ Successful Check
```
## ✅ Sanity Check PASSED

<details>
<summary>Click to view detailed results</summary>

=== Language Detection ===
✓ C/C++ files detected

================================
C/C++ SANITY CHECK REQUIREMENTS
================================
Checking for:
  ✓ Uninitialized variables
  ✓ Memory leaks
  ✓ Null pointer dereferences
  ...

✅ C/C++ sanity check PASSED
</details>

---
*Automated sanity checks completed at 2025-10-23T10:30:00.000Z*
```

### ❌ Failed Check
```
## ❌ Sanity Check FAILED

<details>
<summary>Click to view detailed results</summary>

❌ ERROR: bad-example.cpp uses malloc but no free() found
❌ ERROR: bad-example.cpp uses unsafe strcpy() function
⚠️  WARNING: Uninitialized variable usage detected

❌ JavaScript sanity check FAILED
- console.log found at line 5
- Using 'var' instead of 'let'/'const' at line 3
- Using '==' instead of '===' at line 7

Please fix the issues above before merging
</details>

---
*Automated sanity checks completed at 2025-10-23T10:30:00.000Z*
```

---

## 🔧 Customization

### Modify Checked Languages

Edit `.github/workflows/sanity-check.yml`:

```yaml
- name: Get changed files
  uses: tj-actions/changed-files@v39
  with:
    files: |
      **/*.c
      **/*.cpp
      **/*.js
      # Add or remove file extensions here
```

### Adjust Strictness

Edit individual check scripts (e.g., `scripts/cpp-check.sh`):

```bash
# Make checks more lenient
cppcheck --enable=warning,style $FILES  # Remove 'all'

# Make checks stricter
cppcheck --enable=all --inconclusive --check-level=exhaustive $FILES
```

### Add New Language Support

1. Add detection in `detect-language.sh`
2. Create new check script (e.g., `python-check.sh`)
3. Call from `run-checks.sh`
4. Update workflow to install tools

---

## 🧪 Testing Your Setup

### Validation Checklist

- [ ] Workflow runs on PR creation
- [ ] Detects correct programming language
- [ ] Runs appropriate sanity checks
- [ ] Posts comment with results
- [ ] Applies correct label
- [ ] Blocks merge when checks fail
- [ ] Allows merge when checks pass

### Test Cases Provided

Use the files in `test-files/` directory:
- `good-example.*` → Should PASS
- `bad-example.*` → Should FAIL

---

## 📖 Usage for Developers

### Before Creating PR
```bash
# Run checks locally (if you want)
bash scripts/detect-language.sh
bash scripts/run-checks.sh
```

### When PR Fails
1. Check the PR comment for specific issues
2. Fix the reported problems
3. Commit and push fixes
4. Workflow re-runs automatically
5. Merge when checks pass

---

## 🤝 Contributing

### Adding New Check Rules

1. Identify the issue/pattern to catch
2. Add detection logic to appropriate `*-check.sh` script
3. Test with both good and bad examples
4. Update this README with new requirement

### Example: Adding a New C++ Rule

```bash
# In cpp-check.sh, add:
if grep -n "goto " "$file" > /dev/null; then
    echo "❌ ERROR: $file uses goto statement"
    FAILED=true
fi
```

---

## 📝 Notes

- **Not a Replacement**: This is a sanity check, not comprehensive testing
- **Fast Feedback**: Catches obvious issues quickly
- **Extensible**: Easy to add more languages and rules
- **Educational**: Helps developers learn best practices

---

## 📞 Support

For issues or questions:
1. Check workflow run logs in GitHub Actions
2. Verify scripts are executable (`chmod +x scripts/*.sh`)
3. Ensure required tools are installed by workflow
4. Test locally before pushing

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
