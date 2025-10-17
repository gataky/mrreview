# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **GitLab Integration**: Complete glab CLI wrapper with async execution using plenary.job
- **MR Discovery**: Browse and select open merge requests with Telescope integration
- **Diff View System**: Side-by-side diff view using Neovim's built-in diff
- **Comment System**: View MR comments inline with three display modes (float, split, virtual text)
  - Floating window mode (recommended)
  - Split buffer mode
  - Virtual text inline mode
- **State Management**: Centralized state management module with validation and dot notation access
- **Error Handling**: Standardized error handling with typed error objects (GitError, NetworkError, etc.)
- **Logging System**: File-based logging with automatic rotation and configurable log levels
- **Git Operations**: Safe git command wrapper using plenary.job (replaces unsafe io.popen)
- **Test Suite**: Comprehensive test coverage (207 tests) using plenary.busted
  - Tests for git, glab, project, config, state, logger, errors, comments, utils, parsers modules
  - 54% code coverage on core logic modules
- **Development Tools**:
  - StyLua configuration for consistent formatting
  - Luacheck configuration for linting
  - EditorConfig for cross-editor consistency
  - Pre-commit hooks (format, lint, test)
  - CONTRIBUTING.md with development guide

### Changed

- **Refactored Large Modules**: Split diff.lua (569→705 lines across 4 files) and comments.lua (526→480 lines across 2 files)
- **Eliminated Code Duplication**: Centralized git operations, position mapping, and table merging
- **Modernized API Usage**: Replaced deprecated `vim.api.nvim_buf_set_option` with `vim.bo[buf]` syntax
- **Module Organization**: Created focused submodules (diff/, comments/) with clear separation of concerns

### Commands

- `:MRList` - Browse and select from open merge requests
- `:MRCurrent` - Open MR for current git branch
- `:MRReview <number>` - Review specific MR by number
- `:MRComments` - List all comments in current MR with Telescope
- `:MRLogs` - View log file in split window
- `:MRClearLogs` - Clear all log files
- `:MRDebugJSON <number>` - Debug: dump raw JSON from glab

### Configuration Options

- `comment_display_mode` - Choose between 'float', 'split', or 'virtual_text'
- `window.comment_width` - Width of comment split (default: 40)
- `window.vertical_split` - Use vertical or horizontal split
- `window.sync_scroll` - Synchronized scrolling between diff buffers
- `keymaps.*` - Customizable keymaps for navigation
- `glab.path` - Path to glab executable
- `glab.timeout` - Timeout for glab commands (default: 30000ms)
- `logging.enabled` - Enable/disable file logging
- `logging.level` - Log level: DEBUG, INFO, WARN, ERROR
- `logging.file_path` - Custom log file path
- `logging.max_file_size` - Max log file size before rotation (default: 10MB)
- `logging.max_backups` - Number of old logs to keep (default: 3)

### Keymaps

Default keymaps in diff view:
- `]f` / `[f` - Navigate to next/previous file
- `]c` / `[c` - Navigate to next/previous comment
- `K` - Show comment for current line in floating window
- `<leader>tc` - Toggle comment display mode
- `<leader>cl` - List all comments in Telescope
- `q` - Close diff view

### Dependencies

- **Required**:
  - Neovim >= 0.8.0
  - [glab](https://gitlab.com/gitlab-org/cli) - GitLab CLI
  - [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) - Lua utilities

- **Optional**:
  - [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - Enhanced UI (falls back to vim.ui.select)

### Development

- **Phase 1 Complete**: Critical fixes (deprecated APIs, shell commands, test coverage)
- **Phase 2 Complete**: Code quality improvements (duplication, refactoring, errors, state, logging)
- **Phase 4 Partial**: Development infrastructure (tooling complete, documentation in progress)

### Internal Improvements

- Position mapping centralized in `position.lua`
- Error objects with context and wrapping for better debugging
- Logger integration with error handling system
- All git operations logged with DEBUG/INFO/ERROR levels
- All glab operations logged with INFO/ERROR levels
- Metatable-based dynamic state access for backward compatibility
- Strong type validation for state structure

---

## Release Notes Format

Future releases will follow this format:

## [X.Y.Z] - YYYY-MM-DD

### Added
- New features

### Changed
- Changes to existing functionality

### Deprecated
- Soon-to-be removed features

### Removed
- Removed features

### Fixed
- Bug fixes

### Security
- Security fixes

---

[Unreleased]: https://github.com/yourusername/mrreviewer/compare/v0.1.0...HEAD
