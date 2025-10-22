Branch Configuration Guide
This guide explains how to configure which branches trigger the sanity check workflow.

🎯 Default Behavior (RECOMMENDED)
Current setup: Workflow runs on PRs to ALL branches

This is the recommended approach because:

✅ Ensures code quality across all development branches
✅ Catches issues early, regardless of branch
✅ Works well for teams with multiple active branches
✅ Provides consistent checks for feature branches, hotfixes, etc.
🔧 Configuration Options
Option 1: All Branches (Current Default)
File: .github/workflows/sanity-check.yml

yaml
on:
  pull_request:
    types: [opened, synchronize, reopened]
When to use:

Multi-branch development workflow
Want comprehensive coverage
Team works on feature branches, release branches, etc.
Option 2: Only Main Branch
yaml
on:
  pull_request:
    types: [opened, synchronize, reopened]
    branches:
      - main
When to use:

Simple workflow with direct commits to main
Only care about production-ready code
Want to save GitHub Actions minutes
Example scenarios:

✅ PR from feature/login → main (RUNS)
❌ PR from feature/login → develop (SKIPPED)
Option 3: Multiple Specific Branches
yaml
on:
  pull_request:
    types: [opened, synchronize, reopened]
    branches:
      - main
      - develop
      - staging
When to use:

Git Flow or similar branching strategy
Want checks on key branches only
Balance between coverage and resource usage
Example scenarios:

✅ PR → main (RUNS)
✅ PR → develop (RUNS)
✅ PR → staging (RUNS)
❌ PR → feature/xyz (SKIPPED)
Option 4: Pattern Matching
yaml
on:
  pull_request:
    types: [opened, synchronize, reopened]
    branches:
      - main
      - develop
      - 'release/**'  # Matches release/v1.0, release/v2.0, etc.
      - 'hotfix/**'   # Matches hotfix/bug-123, etc.
When to use:

Consistent branch naming conventions
Want to include all branches matching a pattern
Example scenarios:

✅ PR → release/v1.0 (RUNS)
✅ PR → release/v2.5.3 (RUNS)
✅ PR → hotfix/critical-bug (RUNS)
❌ PR → feature/new-ui (SKIPPED)
Option 5: Exclude Branches
yaml
on:
  pull_request:
    types: [opened, synchronize, reopened]
    branches-ignore:
      - experimental
      - 'docs/**'
      - archive
When to use:

Want checks on most branches
Have specific branches to exclude (experimental, documentation, etc.)
Example scenarios:

✅ PR → main (RUNS)
✅ PR → feature/login (RUNS)
❌ PR → experimental (SKIPPED)
❌ PR → docs/update-readme (SKIPPED)
Option 6: Run on Push to Main (Additional Trigger)
yaml
on:
  pull_request:
    types: [opened, synchronize, reopened]
  push:
    branches:
      - main
When to use:

Want checks on both PRs AND direct pushes
Ensure main branch is always validated
Catch issues from force pushes or bypassed PRs
🛠️ How to Change Configuration
Open the workflow file:
bash
   nano .github/workflows/sanity-check.yml
   # or use your preferred editor
Modify the on: section with your chosen option
Commit and push:
bash
   git add .github/workflows/sanity-check.yml
   git commit -m "Update workflow branch triggers"
   git push origin main
Test: Create a PR to verify it works as expected
📊 Comparison Table
Configuration	PRs to Main	PRs to Develop	PRs to Feature	Direct Push to Main	Resource Usage
All Branches	✅	✅	✅	❌	High
Only Main	✅	❌	❌	❌	Low
Main + Develop	✅	✅	❌	❌	Medium
Pattern Match	✅	✅*	❌	❌	Medium
Exclude Branches	✅	✅	✅*	❌	Medium-High
PR + Push	✅	✅	✅	✅	High
*Depends on pattern/exclusion rules

💡 Best Practices
For Small Teams / Simple Projects
yaml
# Run only on PRs to main
on:
  pull_request:
    branches:
      - main
For Medium Teams / Git Flow
yaml
# Run on main and develop
on:
  pull_request:
    branches:
      - main
      - develop
For Large Teams / Complex Workflows
yaml
# Run on all branches (default)
on:
  pull_request:
    types: [opened, synchronize, reopened]
For CI/CD Pipelines
yaml
# Run on PRs and direct pushes
on:
  pull_request:
    branches:
      - main
      - staging
  push:
    branches:
      - main
🔍 Troubleshooting
Workflow not running?
Check branch name matches exactly:
main ≠ master
Case-sensitive!
Verify workflow file syntax:
bash
   # Use GitHub's workflow validator
   # Push changes and check Actions tab for errors
Check if workflow is enabled:
Go to repository → Actions tab
Ensure workflows are enabled
Workflow running too often?
Solution: Add branch filters to reduce triggers:

yaml
on:
  pull_request:
    branches:
      - main  # Add specific branches
Workflow not running on feature branches?
Solution: Remove branch filters or add feature branch pattern:

yaml
on:
  pull_request:
    branches:
      - main
      - 'feature/**'  # Add this line
📞 Need Help?
Check GitHub Actions documentation: https://docs.github.com/en/actions
Review workflow runs in: Repository → Actions tab
Test changes in a dummy repository first
