# Contributing to MRReviewer

Thank you for your interest in contributing to MRReviewer! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Development Setup](#development-setup)
- [Running Tests](#running-tests)
- [Code Style Guide](#code-style-guide)
- [Pull Request Process](#pull-request-process)
- [Project Structure](#project-structure)
- [Reporting Issues](#reporting-issues)

## Development Setup

### Prerequisites

1. **Neovim** >= 0.8.0
   ```bash
   nvim --version
   ```

2. **Git** for version control
   ```bash
   git --version
   ```

3. **glab** - GitLab CLI (for testing GitLab integration)
   ```bash
   # macOS
   brew install glab

   # Authenticate
   glab auth login
   ```

4. **Development Tools** (optional but recommended)
   - **stylua** - Lua code formatter
     ```bash
     cargo install stylua
     # or on macOS
     brew install stylua
     ```

   - **luacheck** - Lua linter
     ```bash
     luarocks install luacheck
     # or on macOS
     brew install luacheck
     ```

### Cloning the Repository

```bash
git clone https://github.com/yourusername/mrreviewer.git
cd mrreviewer
```

### Installing Dependencies

The project uses [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) for testing and utilities.

For testing, plenary will be automatically cloned to `/tmp/plenary.nvim` when you run tests for the first time.

### Setting Up Git Hooks

Install the pre-commit hook to ensure code quality:

```bash
# Create symlink (recommended)
ln -sf ../../hooks/pre-commit .git/hooks/pre-commit

# Or copy it
cp hooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

The pre-commit hook will:
- Format code with stylua
- Run luacheck for linting
- Run the test suite
- Block commits if any check fails

## Running Tests

### Full Test Suite

Run all tests with plenary.busted:

```bash
nvim --headless --noplugin -u tests/minimal_init.lua \
  -c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.lua' }"
```

### Running a Single Test File

```bash
nvim --headless --noplugin -u tests/minimal_init.lua \
  -c "PlenaryBustedFile tests/git_spec.lua"
```

### Test Structure

Tests are located in the `tests/` directory:

```
tests/
├── minimal_init.lua      # Test setup and plenary configuration
├── git_spec.lua          # Tests for git module
├── glab_spec.lua         # Tests for glab wrapper
├── config_spec.lua       # Tests for configuration
├── state_spec.lua        # Tests for state management
├── logger_spec.lua       # Tests for logging system
└── ...
```

### Writing Tests

Tests use [plenary.busted](https://github.com/nvim-lua/plenary.nvim#plenarybusted) (BDD-style testing):

```lua
describe('my_module', function()
  local my_module

  before_each(function()
    -- Setup before each test
    my_module = require('mrreviewer.my_module')
  end)

  after_each(function()
    -- Cleanup after each test
  end)

  it('should do something', function()
    local result = my_module.do_something()
    assert.equals('expected', result)
  end)

  it('should handle errors', function()
    local result, err = my_module.failing_operation()
    assert.is_nil(result)
    assert.is_not_nil(err)
  end)
end)
```

## Code Style Guide

### Formatting

We use **StyLua** for consistent code formatting. Configuration in `.stylua.toml`:

- **Line width**: 100 characters
- **Indentation**: 4 spaces
- **Quote style**: Auto-prefer single quotes
- **Collapse statements**: Never

Format your code before committing:

```bash
stylua lua/ tests/
```

### Linting

We use **luacheck** for linting. Configuration in `.luacheckrc`:

- Max line length: 100
- Max cyclomatic complexity: 15
- Neovim globals allowed: `vim`

Check your code:

```bash
luacheck lua/ tests/
```

### Naming Conventions

- **Files**: `snake_case.lua`
- **Modules**: `snake_case`
- **Functions**: `snake_case()`
- **Variables**: `snake_case`
- **Constants**: `UPPER_CASE`
- **Private functions**: Prefix with underscore or use `local function`

### Code Organization

```lua
-- Module header comment
-- Describes what this module does

local M = {}

-- Module dependencies
local utils = require('mrreviewer.utils')
local config = require('mrreviewer.config')

-- Private functions (local)
local function private_helper()
  -- Implementation
end

--- Public function with documentation
--- @param param string Parameter description
--- @return table Result description
function M.public_function(param)
  -- Implementation
end

return M
```

### Documentation Comments

Use LuaDoc-style annotations for public functions:

```lua
--- Brief description of the function
--- Detailed description if needed
--- @param name string The user's name
--- @param age number The user's age
--- @param opts table|nil Optional configuration
--- @return boolean, string|nil Success status and error message
function M.create_user(name, age, opts)
  -- Implementation
end
```

### Error Handling

Use the `errors` module for consistent error handling:

```lua
local errors = require('mrreviewer.errors')

function M.risky_operation()
  local result, err = some_operation()
  if not result then
    return nil, errors.wrap('Failed to perform operation', err)
  end

  return result, nil
end
```

All errors should:
- Return `(result, error)` tuples
- Use appropriate error types (GitError, NetworkError, etc.)
- Include context for debugging

### Logging

Use the `logger` module for debugging:

```lua
local logger = require('mrreviewer.logger')

function M.complex_operation()
  logger.debug('module', 'Starting complex operation', { param = value })

  -- Do work

  logger.info('module', 'Operation completed successfully')
end
```

## Pull Request Process

### Before Submitting

1. **Update your fork**:
   ```bash
   git checkout main
   git pull upstream main
   ```

2. **Create a feature branch**:
   ```bash
   git checkout -b feature/my-new-feature
   # or
   git checkout -b fix/bug-description
   ```

3. **Make your changes**:
   - Write clear, focused commits
   - Follow the code style guide
   - Add tests for new functionality
   - Update documentation as needed

4. **Run pre-commit checks**:
   ```bash
   # The pre-commit hook will run automatically, or run manually:
   ./hooks/pre-commit
   ```

5. **Commit your changes**:
   ```bash
   git add .
   git commit -m "feat: add new feature"
   ```

   Use [Conventional Commits](https://www.conventionalcommits.org/):
   - `feat:` - New feature
   - `fix:` - Bug fix
   - `docs:` - Documentation changes
   - `refactor:` - Code refactoring
   - `test:` - Adding or updating tests
   - `chore:` - Maintenance tasks

6. **Push to your fork**:
   ```bash
   git push origin feature/my-new-feature
   ```

### Submitting the PR

1. Go to the GitHub repository
2. Click "New Pull Request"
3. Select your feature branch
4. Fill in the PR template:
   - **Title**: Clear, concise description
   - **Description**:
     - What does this PR do?
     - Why is this change needed?
     - How was it tested?
   - **Related Issues**: Link to any related issues

### PR Template

```markdown
## Description
Brief description of the changes

## Motivation
Why is this change needed?

## Changes
- List key changes
- Made in this PR

## Testing
- [ ] All existing tests pass
- [ ] Added new tests for changes
- [ ] Manually tested with test MR

## Checklist
- [ ] Code follows project style guide
- [ ] Documentation updated
- [ ] Tests added/updated
- [ ] Commit messages follow convention
```

### Review Process

1. **Automated Checks**: Pre-commit hooks and tests must pass
2. **Code Review**: Maintainer will review your code
3. **Feedback**: Address any requested changes
4. **Approval**: Once approved, PR will be merged

### After Merge

1. **Delete your branch**:
   ```bash
   git checkout main
   git pull upstream main
   git branch -d feature/my-new-feature
   ```

2. **Update your fork**:
   ```bash
   git push origin main
   ```

## Project Structure

```
mrreviewer/
├── lua/mrreviewer/         # Main plugin code
│   ├── init.lua           # Plugin entry point
│   ├── commands.lua       # Neovim command handlers
│   ├── config.lua         # Configuration management
│   ├── state.lua          # Centralized state management
│   ├── logger.lua         # Logging system
│   ├── errors.lua         # Error handling
│   ├── git.lua            # Git operations wrapper
│   ├── glab.lua           # GitLab CLI wrapper
│   ├── project.lua        # Project detection
│   ├── parsers.lua        # Data parsing
│   ├── utils.lua          # Utility functions
│   ├── ui.lua             # UI helpers
│   ├── highlights.lua     # Highlight groups
│   ├── position.lua       # Position mapping
│   ├── diff/              # Diff view system
│   │   ├── init.lua       # Public API
│   │   ├── view.lua       # Diff view creation
│   │   ├── navigation.lua # Navigation logic
│   │   └── keymaps.lua    # Keymap setup
│   └── comments/          # Comment system
│       ├── init.lua       # Core logic
│       └── formatting.lua # Comment formatting
├── plugin/                # Neovim plugin registration
│   └── mrreviewer.lua    # Command registration
├── tests/                 # Test suite
│   ├── minimal_init.lua  # Test configuration
│   └── *_spec.lua        # Test files
├── hooks/                 # Git hooks
│   ├── pre-commit        # Pre-commit hook
│   └── README.md         # Hook documentation
├── .stylua.toml          # Formatter config
├── .luacheckrc           # Linter config
├── .editorconfig         # Editor config
└── README.md             # User documentation
```

## Reporting Issues

### Bug Reports

When reporting bugs, please include:

1. **Neovim version**: Output of `nvim --version`
2. **Plugin version**: Git commit hash or tag
3. **Steps to reproduce**: Clear, minimal reproduction steps
4. **Expected behavior**: What should happen
5. **Actual behavior**: What actually happens
6. **Error messages**: Any error messages or logs
7. **Configuration**: Your mrreviewer config (if relevant)

### Feature Requests

When requesting features:

1. **Use case**: Describe the problem you're trying to solve
2. **Proposed solution**: How you envision the feature working
3. **Alternatives**: Any alternative solutions you've considered
4. **Additional context**: Screenshots, examples, etc.

## Questions?

- **Documentation**: Check the [README.md](README.md)
- **Issues**: Search [existing issues](https://github.com/yourusername/mrreviewer/issues)
- **Discussions**: Start a [discussion](https://github.com/yourusername/mrreviewer/discussions)

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers
- Focus on constructive feedback
- Assume good intentions

Thank you for contributing to MRReviewer! 🎉
