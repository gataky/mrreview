# MRReviewer - Improvement Roadmap

> Generated: 2025-01-17
> Status: Active Planning

## Priority 1: Critical Issues (Must Fix)

### 1.1 Replace Deprecated Neovim APIs ✅ COMPLETE
**Files:** `lua/mrreviewer/diff.lua`, `lua/mrreviewer/comments.lua`, `lua/mrreviewer/ui.lua`
**Estimated effort:** 2-3 hours
**Breaking changes:** None (backward compatible)
**Completed:** 2025-01-17

- [x] Replace all `vim.api.nvim_buf_set_option(buf, 'option', value)`
  - With: `vim.bo[buf].option = value`
- [x] Replace all `vim.api.nvim_win_set_option(win, 'option', value)`
  - With: `vim.wo[win].option = value`
- [x] Test with Neovim 0.10+ (tested on v0.11.3 ✓)

**Files to modify:**
- `lua/mrreviewer/diff.lua`: Lines 161-165, 396-412
- `lua/mrreviewer/comments.lua`: Lines 112-114, 133-134, 289-290
- `lua/mrreviewer/ui.lua`: Lines 128-129, 156-157

### 1.2 Refactor Shell Commands to Use plenary.job ✅ COMPLETE
**Files:** `lua/mrreviewer/utils.lua`, `lua/mrreviewer/project.lua`, `lua/mrreviewer/glab.lua`, `lua/mrreviewer/git.lua` (new)
**Estimated effort:** 4-6 hours
**Breaking changes:** None (internal refactor)
**Completed:** 2025-01-17

- [x] Create `lua/mrreviewer/git.lua` module with Job-based helpers
  - [x] `git.get_current_branch()`
  - [x] `git.get_repo_root()`
  - [x] `git.get_remote_url()`
  - [x] `git.is_git_repo()`
  - [x] `git.get_upstream_branch()` (bonus)
  - [x] `git.command_exists()` (for glab check)
- [x] Refactor `utils.lua` to use new git module
- [x] Refactor `project.lua` to use new git module
- [x] Refactor `glab.lua` to use new git module (bonus)
- [x] Remove all `io.popen()` calls - verified ✓ (7 calls removed)
- [x] Add proper error handling for failed git operations

### 1.3 Add Test Coverage for Core Modules
**Target:** 60% coverage minimum
**Estimated effort:** 8-12 hours

- [ ] `tests/glab_spec.lua` - Test glab CLI wrapper
- [ ] `tests/project_spec.lua` - Test git/project detection
- [ ] `tests/config_spec.lua` - Test configuration management
- [ ] `tests/comments_spec.lua` - Test comment filtering/sorting
- [ ] `tests/diff_spec.lua` - Test diff file operations
- [ ] `tests/commands_spec.lua` - Test command handlers
- [ ] Set up CI to enforce minimum coverage

---

## Priority 2: Code Quality (Should Fix)

### 2.1 Eliminate Code Duplication
**Estimated effort:** 2-3 hours

- [ ] Remove duplicate `merge_tables()` from `config.lua`
  - Use `utils.merge_tables()` everywhere
- [ ] Create `git.lua` to centralize git operations
  - Extract from `utils.lua` and `project.lua`
- [ ] Create `position.lua` to centralize line mapping
  - Extract from `comments.lua`

### 2.2 Refactor Large Modules
**Estimated effort:** 6-8 hours
**Breaking changes:** None (internal refactor)

**diff.lua (569 lines) → Split into:**
```
lua/mrreviewer/diff/
  ├── init.lua       # Public API (100 lines)
  ├── view.lua       # Diff view creation (200 lines)
  ├── navigation.lua # File/comment navigation (150 lines)
  └── keymaps.lua    # Keymap setup (120 lines)
```

**comments.lua (526 lines) → Split into:**
```
lua/mrreviewer/comments/
  ├── init.lua       # Public API (80 lines)
  ├── display.lua    # Display modes (split/float/virtual) (250 lines)
  ├── navigation.lua # Comment navigation (100 lines)
  └── formatting.lua # Comment formatting (100 lines)
```

- [ ] Create subdirectories
- [ ] Split modules maintaining backward compatibility
- [ ] Update all `require()` statements
- [ ] Test thoroughly

### 2.3 Standardize Error Handling
**Estimated effort:** 4-5 hours

- [ ] Create `lua/mrreviewer/errors.lua` module
  - [ ] Define error types (GitError, NetworkError, ParseError, etc.)
  - [ ] Implement `try()` helper for pcall wrapping
  - [ ] Implement centralized error logging
- [ ] Update all modules to use consistent error pattern:
  ```lua
  -- Standard pattern:
  local result, err = operation()
  if not result then
    return nil, errors.wrap("context message", err)
  end
  ```
- [ ] Add error recovery strategies where applicable

### 2.4 Centralize State Management
**Estimated effort:** 3-4 hours

- [ ] Create `lua/mrreviewer/state.lua` module
  ```lua
  State = {
    session = {
      initialized = false,
      current_mr = nil,
    },
    diff = {
      buffers = {},
      windows = {},
      current_file_index = 1,
      files = {},
    },
    comments = {
      displayed_comments = {},
      comment_buffer = nil,
      comment_window = nil,
      float_win = nil,
    }
  }
  ```
- [ ] Migrate state from `init.lua`, `diff.lua`, `comments.lua`
- [ ] Add state getter/setter methods
- [ ] Add state validation

---

## Priority 3: Enhancement (Nice to Have)

### 3.1 Reorganize Module Structure
**Estimated effort:** 4-6 hours
**Breaking changes:** Yes (require paths change)

- [ ] Create new directory structure (see design above)
- [ ] Move files to appropriate subdirectories
- [ ] Update all `require()` statements
- [ ] Add backward compatibility shims
- [ ] Update documentation
- [ ] Create migration guide

### 3.2 Add Configuration Validation
**Estimated effort:** 2-3 hours

- [ ] Create `lua/mrreviewer/schema.lua` for config validation
- [ ] Validate user config in `config.setup()`
- [ ] Provide helpful error messages for invalid config
- [ ] Add config merge validation
- [ ] Document all valid config options

### 3.3 Implement Caching System
**Estimated effort:** 4-5 hours

- [ ] Create `lua/mrreviewer/cache.lua` module
- [ ] Cache MR details (expires after 5 minutes)
- [ ] Cache file diffs (expires after 2 minutes)
- [ ] Cache comment data (expires after 5 minutes)
- [ ] Add cache invalidation on refresh command
- [ ] Add cache statistics for debugging

### 3.4 Improve User Experience
**Estimated effort:** 6-8 hours

- [ ] Add loading indicators
  - [ ] Use vim.notify with timeout:false for operations
  - [ ] Clear notification on completion
- [ ] Add operation cancellation
  - [ ] Track running jobs
  - [ ] Add `:MRCancel` command
- [ ] Better error messages
  - [ ] Add suggestions to error messages
  - [ ] Link to docs for common errors
- [ ] Add progress bars for multi-file operations
  - [ ] Show "Loading file 3/10..." messages

### 3.5 Add Performance Optimizations
**Estimated effort:** 3-4 hours

- [ ] Debounce comment filtering
- [ ] Lazy load modules (don't require all at once)
- [ ] Cache parsed git URLs
- [ ] Implement virtual scrolling for large comment lists
- [ ] Profile critical paths and optimize

---

## Priority 4: Tooling & Documentation

### 4.1 Development Infrastructure
**Estimated effort:** 3-4 hours

- [ ] Add `.stylua.toml` for consistent formatting
  ```toml
  column_width = 100
  line_endings = "Unix"
  indent_type = "Spaces"
  indent_width = 2
  quote_style = "AutoPreferSingle"
  ```
- [ ] Add `.luacheckrc` for linting
- [ ] Add `.editorconfig`
- [ ] Set up GitHub Actions CI
  - [ ] Run tests on PR
  - [ ] Check formatting
  - [ ] Run linter
  - [ ] Generate coverage report
- [ ] Add pre-commit hooks
  - [ ] Format with stylua
  - [ ] Run luacheck
  - [ ] Run tests

### 4.2 Documentation
**Estimated effort:** 4-5 hours

- [ ] Create `CONTRIBUTING.md`
  - [ ] Development setup
  - [ ] Running tests
  - [ ] Code style guide
  - [ ] PR process
- [ ] Create `CHANGELOG.md`
  - [ ] Document all releases
  - [ ] Follow Keep a Changelog format
- [ ] Create `examples/` directory
  - [ ] Basic usage example
  - [ ] Custom configuration examples
  - [ ] Integration examples
- [ ] Improve API documentation
  - [ ] Document all public functions
  - [ ] Add usage examples
  - [ ] Generate API docs with ldoc

### 4.3 Testing Infrastructure
**Estimated effort:** 2-3 hours

- [ ] Document test running in `CONTRIBUTING.md`
- [ ] Add test helper utilities
- [ ] Set up mock framework
- [ ] Add integration test suite
- [ ] Add coverage reporting

---

## Implementation Plan

### Phase 1: Critical Fixes (Week 1)
1. Replace deprecated APIs (1.1)
2. Refactor shell commands (1.2)
3. Add core test coverage (1.3)

**Deliverable:** Stable, future-proof codebase

### Phase 2: Code Quality (Week 2-3)
1. Eliminate duplication (2.1)
2. Refactor large modules (2.2)
3. Standardize error handling (2.3)
4. Centralize state (2.4)

**Deliverable:** Maintainable, well-organized code

### Phase 3: Enhancements (Week 4-5)
1. Add config validation (3.2)
2. Implement caching (3.3)
3. Improve UX (3.4)
4. Optimize performance (3.5)

**Deliverable:** Polished user experience

### Phase 4: Infrastructure (Week 6)
1. Development tooling (4.1)
2. Documentation (4.2)
3. Testing infrastructure (4.3)

**Deliverable:** Professional project ready for community

### Phase 5: Optional Architecture Refactor (Future)
1. Reorganize modules (3.1)

**Deliverable:** Clean architecture (breaking change)

---

## Tracking Progress

- [ ] Phase 1 Complete (2/3 tasks) - IN PROGRESS
  - [x] 1.1 Replace Deprecated APIs
  - [x] 1.2 Refactor Shell Commands
  - [ ] 1.3 Add Test Coverage
- [ ] Phase 2 Complete (0/4 tasks)
- [ ] Phase 3 Complete (0/4 tasks)
- [ ] Phase 4 Complete (0/3 tasks)
- [ ] Phase 5 Complete (0/1 tasks)

**Overall Progress:** 2/15 major tasks complete (13%)

---

## Notes

- Each phase can be developed in parallel by different contributors
- Breaking changes should be avoided until Phase 5
- All changes should maintain backward compatibility where possible
- Tests should be written alongside refactoring (not after)
- Documentation should be updated with code changes

---

## Questions to Resolve

1. Should we maintain Neovim 0.8 compatibility or require 0.10+?
2. Do we want to support multiple GitLab instances?
3. Should we add GitHub PR support in the future?
4. What's the target test coverage percentage?
5. Should state persist across Neovim sessions?
