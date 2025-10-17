# Task List: Neovim GitLab MR Review Plugin

Generated from: `0001-prd-mr-review-plugin.md`

---

## Relevant Files

### Core Plugin Files
- `plugin/mrreviewer.lua` - Main plugin entry point, registers commands and sets up plugin
- `lua/mrreviewer/init.lua` - Main module initialization and public API
- `lua/mrreviewer/config.lua` - Configuration management with user settings and defaults
- `lua/mrreviewer/utils.lua` - Common utility functions (string helpers, validation, etc.)

### GitLab Integration
- `lua/mrreviewer/glab.lua` - Wrapper for glab CLI tool with async execution
- `lua/mrreviewer/parsers.lua` - JSON parsers for MR data, comments, and position info
- `lua/mrreviewer/project.lua` - Git/GitLab project detection and metadata

### User Interface
- `lua/mrreviewer/commands.lua` - Neovim command registration and handlers
- `lua/mrreviewer/ui.lua` - Selection interfaces and user prompts
- `lua/mrreviewer/diff.lua` - Diff view creation, layout, and buffer management
- `lua/mrreviewer/comments.lua` - Comment fetching, parsing, and display logic
- `lua/mrreviewer/highlights.lua` - Highlight group definitions for diff and comments

### Testing
- `tests/init_spec.lua` - Tests for main module initialization
- `tests/glab_spec.lua` - Tests for glab CLI wrapper and async execution
- `tests/parsers_spec.lua` - Tests for JSON parsing functions
- `tests/comments_spec.lua` - Tests for comment position mapping
- `tests/utils_spec.lua` - Tests for utility functions

### Documentation
- `README.md` - Project overview, installation, and usage instructions
- `doc/mrreviewer.txt` - Vim help documentation
- `.luarc.json` - Lua language server configuration for development

### Notes
- Tests use [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) for async testing
- Run tests with `:PlenaryBustedDirectory tests/` or `nvim --headless -c "PlenaryBustedDirectory tests/"`
- Plugin follows standard Neovim plugin structure for easy installation with plugin managers

---

## Tasks

- [x] 1.0 **Project Setup and Infrastructure**
  - [x] 1.1 Create standard Neovim plugin directory structure (`plugin/`, `lua/mrreviewer/`, `doc/`, `tests/`)
  - [x] 1.2 Create `plugin/mrreviewer.lua` as the main entry point with command registration
  - [x] 1.3 Create `lua/mrreviewer/init.lua` with setup() function and module initialization
  - [x] 1.4 Create `lua/mrreviewer/config.lua` with default configuration options (comment_display_mode, keymaps, etc.)
  - [x] 1.5 Create `lua/mrreviewer/utils.lua` with common helper functions (table merge, string trim, path validation)
  - [x] 1.6 Create `lua/mrreviewer/highlights.lua` to define highlight groups for diff and comments
  - [x] 1.7 Add `.luarc.json` for Lua LSP configuration and development

- [x] 2.0 **GitLab Integration Layer**
  - [x] 2.1 Create `lua/mrreviewer/glab.lua` module for CLI interactions
  - [x] 2.2 Implement `glab.check_installation()` to verify glab is installed and authenticated
  - [x] 2.3 Implement `glab.execute_async()` using `vim.loop` (libuv) for non-blocking command execution
  - [x] 2.4 Create `lua/mrreviewer/project.lua` with `get_project_info()` to detect GitLab project from git remote
  - [x] 2.5 Create `lua/mrreviewer/parsers.lua` module for JSON parsing
  - [x] 2.6 Implement `parsers.parse_mr_list()` to parse output from `glab mr list --output json`
  - [x] 2.7 Implement `parsers.parse_mr_details()` to parse output from `glab mr view <id> --output json`
  - [x] 2.8 Implement `parsers.parse_comments()` to parse output from `glab mr view <id> --comments --output json`
  - [x] 2.9 Add comprehensive error handling for network failures, invalid JSON, and authentication errors
  - [x] 2.10 Implement error notification system using `vim.notify()` with appropriate log levels

- [x] 3.0 **MR Discovery and Selection Interface**
  - [x] 3.1 Create `lua/mrreviewer/commands.lua` module to register Neovim commands
  - [x] 3.2 Implement `:MRList` command to fetch and display list of open MRs
  - [x] 3.3 Implement `:MRCurrent` command to detect and open MR for current branch
  - [x] 3.4 Implement `:MRReview <number>` command to open specific MR by number
  - [x] 3.5 Create `lua/mrreviewer/ui.lua` module for selection interfaces
  - [x] 3.6 Implement `ui.select_mr()` using `vim.ui.select()` to display MR list with metadata
  - [x] 3.7 Format MR entries for display (number, title, author, status, created_at)
  - [x] 3.8 Implement current branch detection using git commands
  - [x] 3.9 Add loading indicators and status messages during MR fetching

- [x] 4.0 **Diff View System**
  - [x] 4.1 Create `lua/mrreviewer/diff.lua` module for diff view management
  - [x] 4.2 Implement `diff.get_changed_files()` to extract file list from MR data
  - [x] 4.3 Implement `diff.fetch_file_versions()` to get target and source branch versions using git show
  - [x] 4.4 Create `diff.create_side_by_side_layout()` to set up vsplit with two buffers
  - [x] 4.5 Implement buffer population with target (left) and source (right) file contents
  - [x] 4.6 Apply diff highlighting using `vim.diff()` and extmarks/highlights
  - [x] 4.7 Set buffer options (readonly, buftype=nofile, filetype for syntax highlighting)
  - [x] 4.8 Implement file navigation keymaps (next file, previous file, file list)
  - [x] 4.9 Create `diff.close()` function to clean up buffers and windows
  - [x] 4.10 Add scrollbind/cursorbind for synchronized scrolling between buffers

- [x] 5.0 **Comment Fetching and Display System**
  - [x] 5.1 Create `lua/mrreviewer/comments.lua` module for comment handling
  - [x] 5.2 Implement `comments.fetch()` to get comments for current MR using glab
  - [x] 5.3 Parse comment position data structure (base_sha, head_sha, new_path, old_path, line_range)
  - [x] 5.4 Implement `comments.map_to_line()` to convert position data to buffer line numbers
  - [x] 5.5 Handle both single-line comments (new_line field) and multi-line comments (line_range)
  - [x] 5.6 Filter comments by current file path to show only relevant comments
  - [x] 5.7 Implement split buffer display mode: create vertical split with comment list
  - [x] 5.8 Format comment display with author, timestamp, body, and resolved status
  - [x] 5.9 Implement virtual text display mode using `vim.api.nvim_buf_set_extmark()` with virt_text
  - [x] 5.10 Add configuration option to toggle between display modes (config.comment_display_mode)
  - [x] 5.11 Create highlight groups for resolved (dimmed) vs unresolved (prominent) comments
  - [x] 5.12 Implement comment navigation keymaps (next comment, previous comment)
  - [x] 5.13 Add visual indicator (sign column) for lines with comments

- [x] 6.0 **Documentation and Testing**
  - [x] 6.1 Create `README.md` with project description, features, and installation instructions
  - [x] 6.2 Document prerequisites (Neovim version, glab CLI, git)
  - [x] 6.3 Add configuration examples showing all available options
  - [x] 6.4 Document all commands (`:MRList`, `:MRCurrent`, `:MRReview`)
  - [x] 6.5 Document default keymaps and how to customize them
  - [x] 6.6 Create `doc/mrreviewer.txt` in Vim help format
  - [x] 6.7 Set up `tests/` directory with plenary.nvim test structure
  - [x] 6.8 Write `tests/glab_spec.lua` for async execution and command building
  - [x] 6.9 Write `tests/parsers_spec.lua` for JSON parsing with sample GitLab responses
  - [x] 6.10 Write `tests/comments_spec.lua` for comment position mapping logic
  - [x] 6.11 Write `tests/utils_spec.lua` for utility functions
  - [x] 6.12 Add usage examples and screenshots/GIFs to README
  - [x] 6.13 Document common issues and troubleshooting steps

---

## Implementation Notes

### Architecture Overview
The plugin follows a modular architecture:
1. **Entry Layer** (`plugin/mrreviewer.lua`) - Registers commands
2. **Core Layer** (`init.lua`, `config.lua`) - Manages plugin state and configuration
3. **Integration Layer** (`glab.lua`, `parsers.lua`, `project.lua`) - Handles external GitLab interactions
4. **UI Layer** (`diff.lua`, `comments.lua`, `ui.lua`) - Manages display and user interaction
5. **Support Layer** (`utils.lua`, `highlights.lua`) - Provides common utilities

### Key Technical Decisions

**Async Execution:**
Use `vim.loop` (libuv) for non-blocking execution:
```lua
local handle
handle = vim.loop.spawn('glab', {
  args = {'mr', 'list', '--output', 'json'},
}, function(code, signal)
  -- Handle completion
end)
```

**Comment Position Mapping:**
GitLab provides position data with SHAs and line numbers. Key fields:
- `new_line` - Line number in source/head branch
- `old_line` - Line number in target/base branch
- `line_range.start` and `line_range.end` - For multi-line comments
- `new_path` / `old_path` - File paths (may differ if file was renamed)

**Display Modes:**
1. **Split Buffer**: Separate window showing all comments for current file
2. **Virtual Text**: Inline comments using extmarks at correct line positions

### Testing Strategy
- Unit tests for parsing logic with fixed JSON fixtures
- Mock glab responses to test error handling
- Integration tests for command execution flow
- Manual testing with real GitLab MRs

### Future Enhancements (Out of Scope for v1)
- Adding new comments
- Resolving/unresolving threads
- MR approval and merge
- Support for other platforms (GitHub, Bitbucket)
