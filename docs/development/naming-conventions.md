# Naming Conventions

This document outlines the standardized naming conventions used across the mrreviewer codebase.

## File Naming Conventions

### General Rules
- Use lowercase with underscores (snake_case) for file names
- Use descriptive names that clearly indicate the file's purpose
- Keep names concise but meaningful

### Specific Patterns

#### Panel Files
Files that represent UI panels should use the `*_panel.lua` suffix:
- `diff_panel.lua` - Diff content panel
- `file_panel.lua` - File tree panel
- `panel.lua` - Comments panel (in comments/ subdirectory, so the full name is implicit)

#### Renderer Files
Files that handle rendering logic should use the `*_renderer.lua` suffix:
- `card_renderer.lua` - Card rendering for comments

#### Navigator Files
Files that handle navigation logic should use the `*_navigator.lua` suffix:
- `card_navigator.lua` - Card-based navigation

#### Module Entry Points
Directories representing logical modules should have an `init.lua` file:
- `lua/mrreviewer/init.lua` - Plugin entry point
- `ui/diff/init.lua` - Diff view module
- `ui/diffview/init.lua` - Diffview module
- `ui/comments/init.lua` - Comments module

#### Integration Files
Integration files are named after the service they integrate with:
- `git.lua` - Git operations
- `glab.lua` - GitLab CLI (glab) integration
- `gitlab.lua` - GitLab-specific parsing (in parsers/ subdirectory)

#### Utility Files
Generic utility files use simple descriptive names:
- `utils.lua` - General utilities
- `ui.lua` - UI utilities
- `highlights.lua` - Highlight definitions
- `formatting.lua` - Formatting utilities

### Acceptable Duplicate Names

Some file names may appear multiple times across the codebase when they're in different modules:

#### `init.lua` (4 occurrences)
- `init.lua` - Plugin root
- `ui/diff/init.lua` - Diff module
- `ui/diffview/init.lua` - Diffview module
- `ui/comments/init.lua` - Comments module

**Rationale**: `init.lua` is a Lua convention for module entry points

#### `navigation.lua` (2 occurrences)
- `ui/diff/navigation.lua` - Navigation for inline diff view
- `ui/diffview/navigation.lua` - Navigation for split diffview

**Rationale**: Different modules with distinct navigation implementations

## Header Comment Conventions

Every Lua file must start with a header comment following this format:

```lua
-- lua/mrreviewer/<full/path/to/file.lua>
-- Brief description of the file's purpose
```

### Examples

```lua
-- lua/mrreviewer/api/commands.lua
-- Neovim command registration and handlers
```

```lua
-- lua/mrreviewer/lib/parsers/gitlab.lua
-- JSON parsers for GitLab MR data, comments, and position info
```

```lua
-- lua/mrreviewer/ui/diffview/comments/panel.lua
-- Comments panel with filtering and minimal formatting for diffview
```

### Header Comment Rules

1. **Path must be absolute** from `lua/mrreviewer/` root
2. **Path must match actual file location** exactly
3. **Description should be concise** (one line)
4. **Description should explain purpose**, not implementation details

## Module Require Path Conventions

Require paths should use dot notation matching the file structure:

```lua
-- Correct
require('mrreviewer.lib.parsers.gitlab')
require('mrreviewer.ui.diffview.comments.panel')
require('mrreviewer.api.commands')

-- Incorrect (outdated paths)
require('mrreviewer.lib.parsers')
require('mrreviewer.ui.comments.card_renderer')
require('mrreviewer.ui.diffview.comments_panel')
```

## Directory Structure Conventions

### Core Modules (`core/`)
Essential framework components:
- Configuration, state, logging, errors
- No UI or integration logic

### Library Modules (`lib/`)
Shared utilities and libraries:
- Generic utilities, parsers, position handling
- No module-specific logic

### Integration Modules (`integrations/`)
External service integrations:
- Git, GitLab CLI, project detection
- Encapsulate external dependencies

### UI Modules (`ui/`)
User interface components:
- Organized by feature (diff, diffview, comments)
- Panel, renderer, navigator components

### API Modules (`api/`)
User-facing command interface:
- Command registration and handlers
- Bridge between user and internal modules

## Verification Checklist

When adding or moving files, verify:

- [ ] File name follows conventions (snake_case, appropriate suffix)
- [ ] Header comment shows correct absolute path
- [ ] Header comment has brief description
- [ ] No unintended naming conflicts
- [ ] All require() paths updated to match new location
- [ ] Module can be loaded without errors

## Future Considerations

As the codebase evolves, consider:

1. **Specialized utility subdirectories**: `lib/utils/string.lua`, `lib/utils/table.lua`, etc.
2. **Component grouping**: Group related UI components in subdirectories
3. **Test file naming**: Use `*_spec.lua` or `*_test.lua` suffix for test files
4. **Documentation files**: Keep in `docs/` with kebab-case names

## Last Updated

This document reflects the codebase structure as of Task 1.4 (File Structure Reorganization - Naming Conventions).
