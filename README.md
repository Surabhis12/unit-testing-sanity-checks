# Unit Testing - Sanity Check Workflow

A GitHub Actions workflow that automatically checks your code for common syntax and style issues before merging. Think of it as your first line of defense against obvious bugs and sloppy code.

## What This Does

When you create or update a Pull Request, this workflow automatically:

1. **Figures out** what programming languages you're using
2. **Installs** only the tools needed for those specific languages
3. **Runs** quick sanity checks on your code
4. **Comments** on your PR with the results
5. **Labels** your PR as passed or failed
6. **Blocks** merging if it finds issues

The key thing here: it only runs on Pull Requests, not every time you push code to your branch. This means you can push freely while working, and the checks only kick in when you're ready to merge.

## Supported Languages

Here's what we check and how:

### C/C++
**Tool:** cppcheck with strict settings

**What we look for:**
- Memory leaks (malloc without matching free)
- Unsafe functions (gets, strcpy)
- Uninitialized variables
- Missing include guards in header files
- Buffer overflow risks

### JavaScript/TypeScript
**Tool:** Pattern matching (no external linter needed)

**What we catch:**
- console.log statements (they shouldn't be in production code)
- Using `var` instead of `let` or `const`
- Using `==` when you should use `===`
- eval() usage (major security red flag)
- debugger statements
- alert() calls

### Rust
**Tool:** Simple pattern checks

**What we flag:**
- unwrap() in library code (use proper error handling instead)
- println! in library code (use a proper logging crate)

### Kotlin
**Tool:** Basic style checks

**What we enforce:**
- No wildcard imports (import x.*)
- Line length under 120 characters
- One statement per line (no semicolon chains)

### Swift
**Tool:** Pattern detection

**What we don't allow:**
- Force unwrapping with !!
- Force casting with as!

### Java
**Tool:** Style validation

**What we check:**
- Class names start with uppercase (PascalCase)
- No System.out.println (use a logger)
- No wildcard imports

### Dart/Flutter
**Tool:** Convention checks

**What we verify:**
- No print() statements (use debugPrint)
- Class names are PascalCase

## How It Actually Works

### For You as a Developer

Your typical workflow looks like this:

```bash
# 1. Work on your feature branch - push as much as you want
git push origin my-feature

# 2. When you're ready, create a PR
gh pr create --base main

# 3. The workflow runs automatically
# Check the PR for a comment with results

# 4. If it fails, fix the issues
git add .
git commit -m "Fix sanity check issues"
git push

# 5. The workflow runs again automatically
# 6. Merge when everything passes
```

The important part: **you can push broken code to your branch**. The checks only run when you open or update a Pull Request. This means no annoying failures while you're actively developing.

### Behind the Scenes

When you create a PR, here's what happens:

1. **Language Detection** - The workflow looks at your changed files and figures out what languages you're using
2. **Tool Installation** - It installs only the tools needed for your specific languages (saves time)
3. **Run Checks** - Each language gets its own check script run against your files
4. **Results** - Everything gets collected and posted as a comment on your PR
5. **Labeling** - Your PR gets labeled with either `sanity-check-passed` or `sanity-check-failed`
6. **Decision** - If checks failed, the workflow fails and blocks merging

## What This Doesn't Do

This is **not** a replacement for proper testing. We're only checking:

- **Syntax** - Will your code actually run?
- **Style** - Does it follow basic conventions?
- **Static Analysis** - Can we spot obvious bugs without running the code?

We're **not** checking:
- Whether your calculator actually adds correctly
- If your API calls work
- Whether your UI looks good

That's what unit tests, integration tests, and code review are for.

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       └── sanity-check.yml        # Main workflow config
├── scripts/
│   ├── detect-language.sh          # Figures out what languages you're using
│   ├── run-checks.sh               # Runs all the checks
│   ├── cpp-check.sh                # C/C++ specific checks
│   ├── js-check.sh                 # JavaScript checks
│   ├── rust-check.sh               # Rust checks
│   ├── kotlin-check.sh             # Kotlin checks
│   ├── swift-check.sh              # Swift checks
│   ├── java-check.sh               # Java checks
│   └── flutter-check.sh            # Dart/Flutter checks
├── test-files/                     # Example files for testing
│   ├── cpp/
│   ├── javascript/
│   ├── rust/
│   ├── kotlin/
│   ├── swift/
│   ├── java/
│   └── dart/
└── README.md
```

## Testing the Workflow

Want to make sure it's working? Here's how to test it:

### Test 1: Good Code (Should Pass)

```bash
git checkout -b test-clean-code

# Add a simple, clean JavaScript file
cat > test.js << 'EOF'
'use strict';
const add = (a, b) => a + b;
module.exports = add;
EOF

git add test.js
git commit -m "Add clean JavaScript"
git push origin test-clean-code

# Create a PR - you should see:
# - Green checkmark
# - "Sanity Check PASSED" comment
# - Label: sanity-check-passed
```

### Test 2: Bad Code (Should Fail)

```bash
git checkout main
git checkout -b test-messy-code

# Add some problematic code
cat > test.js << 'EOF'
var x = 10;
console.log(x);
if (x == 10) {
    eval("alert('bad')");
}
EOF

git add test.js
git commit -m "Add problematic code"
git push origin test-messy-code

# Create a PR - you should see:
# - Red X
# - Comment listing all the issues
# - Label: sanity-check-failed
# - PR blocked from merging
```

## Fixing Failed Checks

When your PR fails, here's what to do:

1. Read the comment the bot posts - it tells you exactly what's wrong
2. Fix each issue mentioned
3. Push your fixes
4. The workflow runs again automatically
5. Merge when it passes

### Common Issues and Fixes

**JavaScript problems:**
```javascript
// Problem: Using var
var x = 10;

// Fix: Use const or let
const x = 10;

// Problem: Using ==
if (x == 10) { }

// Fix: Use ===
if (x === 10) { }

// Problem: console.log in code
console.log("debug info");

// Fix: Remove it or use proper logging
logger.info("debug info");
```

**C++ problems:**
```cpp
// Problem: Memory leak
int* ptr = (int*)malloc(100 * sizeof(int));
// Missing free(ptr)

// Fix: Always free allocated memory
int* ptr = (int*)malloc(100 * sizeof(int));
// ... use ptr ...
free(ptr);

// Or better: Use smart pointers
std::unique_ptr<int[]> ptr = std::make_unique<int[]>(100);
```

**Kotlin problems:**
```kotlin
// Problem: Wildcard import
import kotlin.math.*

// Fix: Import specific functions
import kotlin.math.sqrt
import kotlin.math.pow
```

## Customizing the Checks

### Making Checks Less Strict

If a rule doesn't make sense for your project, you can disable it. Edit the relevant check script:

```bash
# Example: Allow console.log in JavaScript
# In scripts/js-check.sh, comment out:

# if grep -n "console\.log" "$file" > /dev/null; then
#     FAILED=true
# fi
```

### Making Checks More Strict

Want to catch more issues? Add new patterns to the check scripts:

```bash
# Example: Flag TODO comments in JavaScript
# In scripts/js-check.sh, add:

if grep -n "TODO" "$file" > /dev/null; then
    echo "⚠️  WARNING: $file contains TODO comments"
    FAILED=true
fi
```

### Adding a New Language

To add support for another language:

1. Update `.github/workflows/sanity-check.yml` to detect the file extensions
2. Create a new check script: `scripts/your-language-check.sh`
3. Add detection logic to `scripts/detect-language.sh`
4. Call your script from `scripts/run-checks.sh`

## Why These Specific Checks?

You might wonder why we check for these particular things. Here's the reasoning:

**console.log** - Debug statements slow down production code and can leak sensitive info

**var vs let/const** - `var` has weird scoping rules that cause bugs. Modern JavaScript doesn't need it.

**== vs ===** - `==` does type coercion which leads to unexpected results. Always use `===`.

**eval()** - Major security vulnerability. Never use it.

**Memory leaks** - In C/C++, every malloc needs a free. Otherwise you leak memory.

**Force unwrapping** - In Swift, using !! crashes your app if the value is nil. Use proper optional handling.

The common thread: these are all things that cause bugs or security issues, and they're easy to check automatically.

## Important Notes

- This workflow **only runs on Pull Requests**
- You can push to your branch as many times as you want without triggering checks
- All issues must be fixed before you can merge
- The workflow is smart about tools - it only installs what it needs based on your changed files

## Troubleshooting

### The workflow isn't running

- Make sure your file extensions match what we support (.js, .cpp, .rs, etc.)
- Check that your scripts are executable: `chmod +x scripts/*.sh`
- Look at the Actions tab in GitHub for detailed logs

### Getting false positives

If the checks flag something that's actually fine:
- Look at the specific check script to see what pattern it's matching
- Consider whether the rule makes sense for your use case
- You can modify or disable specific checks if needed

### Checks are slow

The first run on a PR might be slower because it needs to install tools. After that, GitHub caches the installations and things speed up. We also only install tools for the languages you're actually using.

## Contributing

When adding new checks or languages:

1. Test with both good and bad example code
2. Document what the check does and why
3. Keep checks simple - we're looking for syntax/style issues, not logic bugs
4. Update this README with your changes

---

*This workflow is part of the "Unit Testing - Getting Started" initiative to catch common issues early and keep code quality high across web, firmware, and mobile projects.*