# Task List: Diffview-Style Interface with Integrated Comments

Generated from: `0002-prd-diffview-style-interface.md`

## Current State Assessment

### Existing Infrastructure
- **State Management:** Centralized in `core/state.lua` with session, diff, and comments sections
- **Commands API:** `api/commands.lua` handles MR review workflow, calls `diff.open()` at line 185
- **Diff System:** `ui/diff/` provides unified diff view for single files
- **Comments System:** `ui/comments/` has formatting utilities for detailed comment display
- **Integrations:** `glab`, `parsers`, `utils`, `project` modules are functional
- **Configuration:** `core/config.lua` manages user settings

### Reusable Components
- `ui/diff/view.lua` functions: `get_changed_files()`, `fetch_file_versions()`
- `integrations/glab.lua` for MR data fetching
- `lib/parsers.lua` for parsing comments and MR details
- `ui/comments/formatting.lua` as base for new minimal formatting
- `lib/utils.lua` notification system
- `core/errors.lua` and `core/logger.lua` for error handling

### Architecture Pattern
- Modular structure with clear separation: core, integrations, api, lib, ui
- State accessed via `state_module.get_*()` functions
- Async operations via `glab.execute_async()`
- Backward compatibility via metatables where needed

---

## Relevant Files

### New Files Created

- `justfile` - Task runner for common development commands (test, lint, format) ✓ Created
- `lua/mrreviewer/ui/diffview/layout.lua` - Three-pane window layout management with create_layout(), create_three_pane_windows(), focus_pane(), and close() functions ✓ Created
- `lua/mrreviewer/ui/diffview/file_panel.lua` - File tree panel with render(), calculate_comment_counts(), natural sorting, highlighting, and keymap setup ✓ Created
- `lua/mrreviewer/ui/diffview/diff_panel.lua` - Side-by-side diff rendering with render(), update_file(), highlight_comment_line(), scrollbind/cursorbind support ✓ Created

### New Files to Create
- `lua/mrreviewer/ui/diffview/init.lua` - Main diffview API and entry point
- `lua/mrreviewer/ui/diffview/comments_panel.lua` - Comments list with filtering and minimal formatting
- `lua/mrreviewer/ui/diffview/navigation.lua` - Bidirectional navigation and comment highlighting
- `tests/diffview_spec.lua` - Unit tests for diffview module
- `tests/diffview_layout_spec.lua` - Unit tests for layout module
- `tests/diffview_file_panel_spec.lua` - Unit tests for file panel module
- `tests/diffview_diff_panel_spec.lua` - Unit tests for diff panel module
- `tests/diffview_comments_panel_spec.lua` - Unit tests for comments panel module
- `tests/diffview_navigation_spec.lua` - Unit tests for navigation module
- `tests/diffview_integration_spec.lua` - Integration tests for full diffview workflow

### Files Modified

- `lua/mrreviewer/core/state.lua` - Added `diffview` state section with panel_buffers, panel_windows, selected_file, selected_comment, highlight_timer, filter_resolved; added get_diffview(), clear_diffview(), updated validation and reset() ✓ Modified
- `lua/mrreviewer/core/config.lua` - Added `diffview` configuration options (highlight_duration, default_focus, show_resolved) ✓ Modified
- `lua/mrreviewer/ui/highlights.lua` - Added diffview-specific highlight groups (MRReviewerCommentCount, MRReviewerCommentHighlight, MRReviewerSelectedComment, MRReviewerCommentFileHeader) ✓ Modified
- `tests/state_spec.lua` - Added 11 comprehensive tests for diffview state management (getter, setters, validation, clear, timer cancellation) ✓ Modified
- `tests/config_spec.lua` - Added 6 comprehensive tests for diffview configuration (defaults, overrides, deep merge) ✓ Modified

### Files to Modify
- `lua/mrreviewer/api/commands.lua` - Update `review()` function to call `diffview.open()` instead of `diff.open()`
- `lua/mrreviewer/ui/comments/formatting.lua` - Add `format_minimal()` function for comments panel display

### Notes

- Unit tests should be placed alongside the code files they are testing
- Use `nvim --headless -c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.lua' }"` to run all tests
- Use `nvim --headless -c "lua require('plenary.test_harness').test_file('tests/diffview_spec.lua', { minimal_init = 'tests/minimal_init.lua' })"` to run specific test files
- Follow existing patterns for async operations and state management
- Study diffview.nvim's diff rendering approach (license: diffview.nvim is under GPL-3.0, ensure compliance or implement independently)

---

## Tasks

- [x] 1.0 Set Up Diffview Infrastructure and Configuration
  - [x] 1.1 Add `diffview` state section to `lua/mrreviewer/core/state.lua` with fields: `panel_buffers` (table), `panel_windows` (table), `selected_file` (string|nil), `selected_comment` (table|nil), `highlight_timer` (number|nil), `filter_resolved` (boolean)
  - [x] 1.2 Update `state.lua` validation function to include diffview state validation
  - [x] 1.3 Add `clear_diffview()` function to `state.lua` for clearing diffview-specific state
  - [x] 1.4 Add diffview configuration options to `lua/mrreviewer/core/config.lua`: `diffview.highlight_duration` (default: 2000), `diffview.default_focus` (default: 'files'), `diffview.show_resolved` (default: true)
  - [x] 1.5 Add new highlight groups to `lua/mrreviewer/ui/highlights.lua`: `MRReviewerCommentCount`, `MRReviewerCommentHighlight`, `MRReviewerSelectedComment`, `MRReviewerResolvedComment`, `MRReviewerUnresolvedComment`, `MRReviewerCommentFileHeader`
  - [x] 1.6 Update `tests/state_spec.lua` to test new diffview state section (add 5-8 tests for getters, setters, validation, clear)
  - [x] 1.7 Update `tests/config_spec.lua` to test new diffview config options (add 3-5 tests for defaults and user overrides)

- [x] 2.0 Implement Three-Pane Layout System
  - [x] 2.1 Create `lua/mrreviewer/ui/diffview/layout.lua` module with `create_layout(mr_data)` function
  - [x] 2.2 Implement `layout.create_three_pane_windows()` to create 3 windows with proportions: 20% (file tree), 60% (diff), 20% (comments)
  - [x] 2.3 Store window and buffer IDs in `state.diffview.panel_windows` and `state.diffview.panel_buffers` (keys: 'files', 'diff_old', 'diff_new', 'comments')
  - [x] 2.4 Implement `layout.focus_pane(pane_name)` function to switch focus between panes based on config option
  - [x] 2.5 Implement `layout.close()` function to safely close all diffview windows and clean up state
  - [x] 2.6 Add buffer options for each pane: `buftype='nofile'`, `bufhidden='wipe'`, `swapfile=false`
  - [x] 2.7 Set window options: `wrap=false`, `cursorline=true`, appropriate buffer names ('MRReviewer Files', 'MRReviewer Diff', 'MRReviewer Comments')

- [x] 3.0 Build File Panel with Comment Indicators
  - [x] 3.1 Create `lua/mrreviewer/ui/diffview/file_panel.lua` module
  - [x] 3.2 Implement `file_panel.render(files, comments)` function that populates the file tree buffer
  - [x] 3.3 Implement `file_panel.calculate_comment_counts(file_path, comments)` helper function returning `{resolved: number, total: number}`
  - [x] 3.4 Format each file line as: `"  <filename>  💬 <resolved>/<total>"` (or just `"  <filename>"` if no comments)
  - [x] 3.5 Implement natural file system ordering using Lua's `table.sort()` with path comparison (directories before files, alphabetical within each)
  - [x] 3.6 Apply highlighting to currently selected file using extmarks (highlight group: `MRReviewerSelectedComment`)
  - [x] 3.7 Implement `file_panel.setup_keymaps(buf)` for `j`/`k` navigation and `<Enter>` to select file
  - [x] 3.8 Implement `file_panel.get_file_at_cursor()` helper to extract file path from current cursor line
  - [x] 3.9 Implement `file_panel.on_file_selected(file_path)` callback that updates selected file state and triggers diff panel update

- [x] 4.0 Implement Side-by-Side Diff Rendering
  - [x] 4.1 Create `lua/mrreviewer/ui/diffview/diff_panel.lua` module
  - [x] 4.2 Research diffview.nvim's diff rendering approach (check their GitHub repo for implementation details, respecting GPL-3.0 license)
  - [x] 4.3 Implement `diff_panel.render(mr_data, file_path)` function that creates side-by-side diff in two buffers
  - [x] 4.4 Reuse `view.fetch_file_versions()` from `ui/diff/view.lua` to get old and new file content
  - [x] 4.5 Set up vertical split for diff windows with `vim.api.nvim_open_win()` and configure diff mode using `vim.wo[win].diff = true`
  - [x] 4.6 Implement `diff_panel.highlight_comment_line(line_number, duration)` function using extmarks
  - [x] 4.7 Handle highlight duration: if `duration` is nil/0, keep permanent; otherwise, use `vim.defer_fn()` to clear after duration
  - [x] 4.8 Implement `diff_panel.update_file(mr_data, file_path)` to reload diff when file selection changes
  - [x] 4.9 Handle error cases: missing files, fetch failures (use `utils.notify()` and `logger.log_error()`)

- [ ] 5.0 Create Comments Panel with Filtering
  - [ ] 5.1 Create `lua/mrreviewer/ui/diffview/comments_panel.lua` module
  - [ ] 5.2 Implement `comments_panel.render(comments, show_resolved)` function that populates comments buffer
  - [ ] 5.3 Group comments by file matching file tree order using `comments_panel.group_by_file(comments, files)`
  - [ ] 5.4 Add `format_minimal(comment)` function to `ui/comments/formatting.lua` returning: `"Line <line>  @<author>  <first_line_of_body>  [+N replies]"` format
  - [ ] 5.5 Apply visual separators between file groups (empty line or `---` separator)
  - [ ] 5.6 Apply highlighting: resolved comments use `MRReviewerResolvedComment`, unresolved use `MRReviewerUnresolvedComment`, file headers use `MRReviewerCommentFileHeader`
  - [ ] 5.7 Implement `comments_panel.filter_by_status(show_resolved)` to toggle resolved/unresolved filter (update state and re-render)
  - [ ] 5.8 Implement `comments_panel.setup_keymaps(buf)` for: `j`/`k` navigation, `<Enter>` jump to comment, `KK` open full thread, filter toggle keybind
  - [ ] 5.9 Implement `comments_panel.get_comment_at_cursor()` helper to extract comment data from current cursor line
  - [ ] 5.10 Handle empty state: leave buffer blank when no comments match filter

- [ ] 6.0 Implement Bidirectional Navigation and Highlighting
  - [ ] 6.1 Create `lua/mrreviewer/ui/diffview/navigation.lua` module
  - [ ] 6.2 Implement `navigation.jump_to_comment(comment, highlight_duration)` function that: switches to correct file in diff panel, scrolls to line, highlights line with configured duration
  - [ ] 6.3 Implement `navigation.highlight_comment_in_panel(comment_id)` to highlight corresponding comment in comments panel
  - [ ] 6.4 Implement `navigation.setup_diff_cursor_moved()` autocmd that detects when cursor moves in diff view and highlights matching comment (use `vim.api.nvim_create_autocmd('CursorMoved')`)
  - [ ] 6.5 Implement `navigation.find_comment_at_line(file_path, line_number, comments)` helper to find comment for given file/line
  - [ ] 6.6 Implement `navigation.open_full_comment_thread(comment)` that reuses existing `ui/comments` floating window logic (call `comments.show_float()` with comment data)
  - [ ] 6.7 Handle highlight timer cleanup: store timer in `state.diffview.highlight_timer`, cancel previous timer before creating new one using `vim.fn.timer_stop()`
  - [ ] 6.8 Ensure cursor remains in comments pane after jump (use `vim.api.nvim_set_current_win()` to restore focus)

- [ ] 7.0 Integrate Diffview into Commands API
  - [ ] 7.1 Create `lua/mrreviewer/ui/diffview/init.lua` as main entry point
  - [ ] 7.2 Implement `diffview.open(mr_data)` function that: validates mr_data, calls layout.create_layout(), populates all three panels, sets up navigation
  - [ ] 7.3 Implement `diffview.close()` function that calls layout.close() and state.clear_diffview()
  - [ ] 7.4 Add error handling wrapper using `errors.try()` for all major operations
  - [ ] 7.5 Update `lua/mrreviewer/api/commands.lua` line 185: change `diff.open(mr_data)` to `require('mrreviewer.ui.diffview').open(mr_data)`
  - [ ] 7.6 Implement graceful degradation: if diffview errors occur, log error and optionally fall back to old diff view (configurable)
  - [ ] 7.7 Add `vim.notify()` notifications for loading states: "Opening diffview...", "Diffview ready"
  - [ ] 7.8 Ensure all errors are logged using `logger.log_error()`

- [ ] 8.0 Add Tests and Documentation
  - [x] 8.1 Create `justfile` (or `Makefile` if preferred) in project root with test commands:
    - `just test` or `make test` - Run all tests
    - `just test-file <file>` or `make test-file FILE=<file>` - Run specific test file (e.g., `just test-file tests/diffview_spec.lua`)
    - `just test-watch` or `make test-watch` - Run tests in watch mode (if feasible)
    - `just lint` or `make lint` - Run luacheck
    - `just format` or `make format` - Run stylua
  - [ ] 8.2 Create `tests/diffview_spec.lua` with unit tests for diffview/init.lua (test open, close, error handling - 8-10 tests)
  - [ ] 8.3 Create `tests/diffview_layout_spec.lua` with tests for layout.lua (test window creation, proportions, focus management - 6-8 tests)
  - [ ] 8.4 Create `tests/diffview_file_panel_spec.lua` with tests for file_panel.lua (test rendering, comment counts, file selection - 8-10 tests)
  - [ ] 8.5 Create `tests/diffview_diff_panel_spec.lua` with tests for diff_panel.lua (test rendering, highlighting, file updates - 6-8 tests)
  - [ ] 8.6 Create `tests/diffview_comments_panel_spec.lua` with tests for comments_panel.lua (test rendering, filtering, formatting - 10-12 tests)
  - [ ] 8.7 Create `tests/diffview_navigation_spec.lua` with tests for navigation.lua (test jump, highlight, bidirectional nav - 8-10 tests)
  - [ ] 8.8 Create `tests/diffview_integration_spec.lua` with full workflow integration tests: open diffview, select file, jump to comment, filter, close (5-8 tests)
  - [ ] 8.9 Update `tests/comments_spec.lua` to test new `format_minimal()` function (add 3-4 tests)
  - [ ] 8.10 Add inline documentation (LuaCATS annotations) to all public functions in diffview modules
  - [ ] 8.11 Update `CHANGELOG.md` with new diffview feature description and usage examples

---

**Status:** Detailed sub-tasks generated. Ready for implementation.

**Total:** 8 parent tasks with 64 detailed sub-tasks

**Implementation Order Recommendation:**
1. Start with tasks 1.0 (infrastructure) - sets foundation
2. Then 2.0 (layout) - creates the UI structure
3. Then 3.0, 4.0, 5.0 (panels) - can be done in parallel
4. Then 6.0 (navigation) - ties panels together
5. Then 7.0 (integration) - makes it usable
6. Finally 8.0 (tests & tooling) - validates everything & improves DX

**Quick Start After Implementation:**
- `just test` - Run all tests
- `just test-file tests/diffview_spec.lua` - Run specific test
- `just lint` - Check code quality
- `just format` - Format code

**Estimated Effort:** ~40-60 hours for full implementation
