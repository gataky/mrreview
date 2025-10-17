# Git Hooks for MRReviewer

This directory contains git hooks to maintain code quality.

## Pre-commit Hook

The pre-commit hook automatically runs before each commit to ensure code quality:

- **Formatting**: Runs `stylua` to format Lua code
- **Linting**: Runs `luacheck` to catch potential issues
- **Testing**: Runs the test suite to ensure nothing breaks

## Installation

To install the pre-commit hook, run from the project root:

```bash
# Linux/macOS
ln -sf ../../hooks/pre-commit .git/hooks/pre-commit

# Or copy it manually
cp hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## Prerequisites

For the pre-commit hook to work optimally, install these tools:

### Required
- **Neovim**: For running tests

### Optional but Recommended
- **stylua**: Lua code formatter
  ```bash
  cargo install stylua
  # or on macOS
  brew install stylua
  ```

- **luacheck**: Lua linter
  ```bash
  luarocks install luacheck
  # or on macOS
  brew install luacheck
  ```

## Skipping Hooks

If you need to commit without running the hooks (not recommended):

```bash
git commit --no-verify
```

## What Happens During Pre-commit?

1. **Formatting Check**: Checks if Lua files are properly formatted
   - If issues found, automatically fixes them and re-stages files

2. **Linting**: Checks for code quality issues
   - If issues found, commit is blocked

3. **Tests**: Runs the full test suite
   - If tests fail, commit is blocked

All checks must pass for the commit to proceed.
