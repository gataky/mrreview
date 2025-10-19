# Tasks: Repository Cleanup and Optimization

**PRD Reference**: tasks/0005-prd-repository-cleanup-optimization.md

## High-Level Tasks

### Task 1.0: File Structure Reorganization
**Status**: Completed
**Description**: Reorganize the codebase into a clear module hierarchy following the proposed structure in the PRD. Create core/, lib/, ui/, and integrations/ directories with proper logical grouping of modules.
**Acceptance Criteria**:
- ✓ All files moved to new directory structure
- ✓ Consistent naming conventions applied across all modules
- ✓ No breaking changes to user-facing API
- ✓ All imports updated to reflect new paths

**Relevant Files**:
- All files in lua/mrreviewer/

#### Sub-tasks:

##### Task 1.1: Audit Current File Structure
**Status**: Completed
**Description**: Document the current file organization and create a migration plan for moving files to the new structure.
**Files**: All lua files in lua/mrreviewer/
**Details**:
- ✓ Create a mapping document showing old path → new path for all files
- ✓ Identify files that are already in correct locations (core/, lib/, integrations/)
- ✓ Identify files that need to be moved (mainly ui/ reorganization)
- ✓ Document all import statements across the codebase
**Completed**: Created comprehensive migration plan in docs/development/file-structure-migration.md with:
  - 30 total files audited
  - 11 files already correctly placed (37%)
  - 5 files identified for migration (17%)
  - Full import dependency analysis
  - Migration order recommendations
  - Post-migration verification checklist

##### Task 1.2: Move Parser Files to lib/parsers/
**Status**: Completed
**Description**: Move parsing-related files into lib/parsers/ directory.
**Files**:
- lua/mrreviewer/lib/parsers.lua → lua/mrreviewer/lib/parsers/gitlab.lua
**Details**:
- ✓ Create lib/parsers/ directory
- ✓ Move and rename parsers.lua to parsers/gitlab.lua
- ✓ Update all imports that reference parsers.lua
**Completed**:
  - Created lua/mrreviewer/lib/parsers/gitlab.lua with updated header comment
  - Updated import in lua/mrreviewer/api/commands.lua:6
  - Updated import in lua/mrreviewer/ui/comments/init.lua:6
  - Removed old lua/mrreviewer/lib/parsers.lua file
  - Verified module loads correctly

##### Task 1.3: Reorganize UI Comments Components
**Status**: Completed
**Description**: Consolidate all comment-related UI components under ui/diffview/comments/
**Files**:
- lua/mrreviewer/ui/comments/formatting.lua → lua/mrreviewer/ui/diffview/comments/formatting.lua
- lua/mrreviewer/ui/comments/card_renderer.lua → lua/mrreviewer/ui/diffview/comments/card_renderer.lua
- lua/mrreviewer/ui/comments/card_navigator.lua → lua/mrreviewer/ui/diffview/comments/card_navigator.lua
- lua/mrreviewer/ui/diffview/comments_panel.lua → lua/mrreviewer/ui/diffview/comments/panel.lua
**Details**:
- ✓ Create ui/diffview/comments/ directory
- ✓ Move all comment-related files into this directory
- ✓ Rename comments_panel.lua to panel.lua for consistency
- ✓ Update all imports across the codebase
**Completed**:
  - Created lua/mrreviewer/ui/diffview/comments/ directory
  - Moved and updated 4 comment component files with new header paths
  - Updated imports in panel.lua to use new paths for formatting, card_renderer, card_navigator
  - Updated imports in ui/diffview/init.lua:15 to use comments.panel
  - Updated lazy-loaded imports in card_navigator.lua (4 locations)
  - Updated import in ui/comments/init.lua:9 for formatting
  - Removed all 4 old files after verifying imports
  - Verified modules load correctly

##### Task 1.4: Standardize Naming Conventions
**Status**: Completed
**Description**: Apply consistent naming conventions across all modules.
**Files**: All renamed/moved files
**Details**:
- ✓ Ensure all panel files use *_panel.lua naming
- ✓ Ensure all renderer files use *_renderer.lua naming
- ✓ Update module names in file headers to match new paths
- ✓ Verify no naming conflicts exist
**Completed**:
  - Verified panel naming: panel.lua, diff_panel.lua, file_panel.lua (consistent ✓)
  - Verified renderer naming: card_renderer.lua (consistent ✓)
  - Updated header comment in api/commands.lua to reflect correct path
  - Updated header comment in ui/comments/init.lua to reflect correct path
  - Verified all other moved files have correct header paths
  - Documented acceptable duplicate names (init.lua, navigation.lua) with rationale
  - Created comprehensive naming conventions document at docs/development/naming-conventions.md
  - Verified no unintended naming conflicts exist

##### Task 1.5: Update All Import Statements
**Status**: Completed
**Description**: Update all require() statements to reflect the new file structure.
**Files**: All lua files that import moved modules
**Details**:
- ✓ Search for all require('mrreviewer.ui.comments.*')
- ✓ Search for all require('mrreviewer.lib.parsers')
- ✓ Update to new paths
- ✓ Test that all imports resolve correctly
**Completed**:
  - Verified all old import patterns have been removed (0 remaining references)
  - Confirmed parser imports use new path: mrreviewer.lib.parsers.gitlab (2 files)
  - Confirmed comment component imports use new paths (5 unique paths, ~15 statements total)
  - Tested all critical modules load successfully without errors
  - Created comprehensive import path changes documentation at docs/development/import-path-changes.md
  - Document includes migration guide for developers with local branches
  - All imports follow consistent patterns and conventions

##### Task 1.6: Verify No Breaking Changes
**Status**: Completed
**Description**: Test that user-facing API remains unchanged after reorganization.
**Files**: lua/mrreviewer/init.lua, lua/mrreviewer/api/commands.lua
**Details**:
- ✓ Verify all plugin commands still work
- ✓ Verify user configuration options still work
- ✓ Test all user-facing functions
- ✓ Ensure no changes to public API surface
**Completed**:
  - Verified plugin initialization: require('mrreviewer') loads successfully
  - Verified setup() function available and functional
  - Verified all 7 user commands registered correctly:
    * MRList, MRCurrent, MRReview, MRDebugJSON, MRComments, MRLogs, MRClearLogs
  - Verified all public API functions available:
    * setup(), get_state(), is_initialized(), clear_state()
  - Verified all reorganized modules load without errors
  - Confirmed 0 breaking changes for end users
  - Created comprehensive verification report at docs/development/reorganization-verification.md
  - All tests passed (5/5 - 100% pass rate)

---

### Task 2.0: Utility Consolidation and Plenary Integration
**Status**: Not Started
**Description**: Audit all modules for duplicate utility functions, consolidate them into shared modules in lib/utils/, and replace custom implementations with plenary.nvim utilities where appropriate.
**Acceptance Criteria**:
- All duplicate utility functions identified and consolidated
- Plenary.nvim utilities integrated for path, table, and async operations
- All modules updated to use consolidated utilities
- Plenary.nvim documented as required dependency

**Relevant Files**:
- lua/mrreviewer/lib/utils.lua
- All files using utility functions
- Plugin documentation

#### Sub-tasks:

##### Task 2.1: Audit for Duplicate Utility Functions
**Status**: Not Started
**Description**: Search all modules for duplicate utility patterns and document them.
**Files**: All lua files
**Details**:
- Search for duplicate string manipulation (trim, split, format)
- Search for duplicate table operations (merge, filter, map, insert loops)
- Search for duplicate path operations (concatenation, validation, exists checks)
- Search for duplicate UTF-8 handling (emoji finding, multi-byte char handling)
- Document all occurrences with file:line references

##### Task 2.2: Create Specialized Utility Modules
**Status**: Not Started
**Description**: Create focused utility modules in lib/utils/ for different concerns.
**Files**:
- lua/mrreviewer/lib/utils/string.lua (new)
- lua/mrreviewer/lib/utils/table.lua (new)
- lua/mrreviewer/lib/utils/utf8.lua (new)
**Details**:
- Create lib/utils/string.lua with: trim(), split(), escape_pattern(), format_*()
- Create lib/utils/table.lua with: merge(), filter(), map(), is_empty(), size()
- Create lib/utils/utf8.lua with: find_emoji(), find_utf8_char(), is_box_drawing(), get_char_width()
- Add comprehensive documentation to each function

##### Task 2.3: Integrate Plenary.nvim Path Utilities
**Status**: Not Started
**Description**: Replace custom path operations with plenary.path.
**Files**:
- lua/mrreviewer/lib/utils.lua
- lua/mrreviewer/integrations/git.lua
- lua/mrreviewer/integrations/project.lua
- lua/mrreviewer/core/state.lua
**Details**:
- Replace file_exists() with plenary.path methods
- Replace dir_exists() with plenary.path methods
- Replace path concatenation with plenary.path:joinpath()
- Replace validate_path() with plenary.path validation
- Add require('plenary.path') where needed

##### Task 2.4: Integrate Plenary.nvim Table Utilities
**Status**: Not Started
**Description**: Replace custom table operations with plenary.tbl functions.
**Files**:
- lua/mrreviewer/lib/utils.lua
- Files using merge_tables(), table_size(), is_table_empty()
**Details**:
- Replace merge_tables() with vim.tbl_deep_extend() or plenary equivalents
- Replace custom table utilities with plenary.tbl where appropriate
- Update all call sites to use new utilities

##### Task 2.5: Integrate Plenary.nvim Async Utilities
**Status**: Not Started
**Description**: Use plenary.async for I/O operations where appropriate.
**Files**:
- lua/mrreviewer/integrations/glab.lua
- lua/mrreviewer/integrations/git.lua
- Files using vim.defer_fn() for I/O
**Details**:
- Identify synchronous I/O operations that could be async
- Replace vim.defer_fn() with plenary.async where appropriate
- Use plenary.async.void for async function wrappers
- Test async operations don't block UI

##### Task 2.6: Consolidate Duplicate Implementations
**Status**: Not Started
**Description**: Replace all duplicate utility implementations with calls to consolidated modules.
**Files**: All files identified in Task 2.1
**Details**:
- Replace inline string trimming with utils.string.trim()
- Replace inline table operations with utils.table.*()
- Replace inline UTF-8 handling with utils.utf8.*()
- Remove duplicate code
- Test all replacements work correctly

##### Task 2.7: Document Plenary Dependency
**Status**: Not Started
**Description**: Update documentation to reflect plenary.nvim as required dependency.
**Files**:
- README.md
- doc/mrreviewer.txt (if exists)
- Plugin installation instructions
**Details**:
- Add plenary.nvim to dependencies list
- Document which plenary modules are used and why
- Update installation instructions for plugin managers
- Note minimum plenary version if applicable

---

### Task 3.0: Error Handling Standardization
**Status**: Not Started
**Description**: Implement consistent error handling patterns across all modules using the existing errors.lua framework. Enhance logging throughout the codebase with appropriate log levels.
**Acceptance Criteria**:
- All modules use consistent error return patterns
- Error context added to all error messages
- Debug, info, warn, and error logs added appropriately
- Error handling guidelines document created

**Relevant Files**:
- lua/mrreviewer/core/errors.lua
- lua/mrreviewer/core/logger.lua
- All modules with error handling

#### Sub-tasks:

##### Task 3.1: Audit Current Error Handling Patterns
**Status**: Not Started
**Description**: Document all current error handling patterns across the codebase.
**Files**: All lua files
**Details**:
- Identify functions that return nil on error vs error objects
- Identify functions that silently swallow errors
- Identify error messages without context
- Find uses of pcall/xpcall and their error handling
- Document inconsistencies in error return patterns

##### Task 3.2: Standardize Error Return Patterns
**Status**: Not Started
**Description**: Implement consistent error return pattern: `result, err` across all functions.
**Files**: All lua files with functions that can fail
**Details**:
- Update functions to return (result, nil) on success
- Update functions to return (nil, error_object) on failure
- Use errors.new() or errors.wrap() for all errors
- Ensure error types are appropriate (validation, git, api, etc.)
- Update all call sites to handle new return pattern

##### Task 3.3: Add Error Context Throughout Codebase
**Status**: Not Started
**Description**: Enhance all error messages with relevant context information.
**Files**: All files that create or wrap errors
**Details**:
- Add function name to error context
- Add input parameters to error context (excluding sensitive data)
- Add relevant state to error context
- Use errors.wrap() to add context when propagating errors
- Ensure error messages are actionable and helpful

##### Task 3.4: Enhance Logging Coverage
**Status**: Not Started
**Description**: Add comprehensive logging at appropriate levels across all modules.
**Files**: All lua files, especially:
- lua/mrreviewer/integrations/glab.lua
- lua/mrreviewer/integrations/git.lua
- lua/mrreviewer/ui/diffview/comments_panel.lua
- lua/mrreviewer/core/state.lua
**Details**:
- Add logger.debug() for function entry/exit with parameters
- Add logger.info() for user-facing operations
- Add logger.warn() for recoverable issues
- Add logger.error() for failures with full context
- Ensure no duplicate logging of same events

##### Task 3.5: Review and Improve Error Handling in Critical Paths
**Status**: Not Started
**Description**: Focus on error handling in critical user-facing operations.
**Files**:
- lua/mrreviewer/integrations/glab.lua (API calls)
- lua/mrreviewer/integrations/git.lua (git operations)
- lua/mrreviewer/ui/diffview/init.lua (diffview creation)
- lua/mrreviewer/api/commands.lua (user commands)
**Details**:
- Ensure all API failures are properly handled
- Add retry logic where appropriate
- Add user-friendly error messages via vim.notify()
- Ensure errors don't leave UI in broken state
- Test error scenarios (network failure, invalid MR, etc.)

##### Task 3.6: Create Error Handling Guidelines Document
**Status**: Not Started
**Description**: Document error handling best practices for the codebase.
**Files**:
- docs/development/error-handling.md (new)
**Details**:
- Document the standard error return pattern
- Provide examples of good error handling
- Document when to use each error type
- Document how to add context to errors
- Document logging level guidelines
- Include code examples for common scenarios

##### Task 3.7: Remove Silent Error Swallowing
**Status**: Not Started
**Description**: Find and fix all places where errors are silently ignored.
**Files**: All lua files using pcall without error handling
**Details**:
- Search for pcall() calls that ignore return values
- Add proper error handling or logging
- Ensure critical errors are propagated
- Document why errors are ignored if intentional
- Add comments explaining error handling decisions

---

### Task 4.0: UI Module Refactoring
**Status**: Not Started
**Description**: Break down large UI modules (especially comments_panel.lua) into focused, smaller components. Reduce inter-component coupling and create consistent interfaces for UI components.
**Acceptance Criteria**:
- comments_panel.lua split into smaller, focused modules
- Standard lifecycle methods defined for UI components
- Component interfaces documented
- Reduced coupling between UI modules

**Relevant Files**:
- lua/mrreviewer/ui/diffview/comments_panel.lua (~980 lines)
- lua/mrreviewer/ui/diffview/diff_panel.lua
- lua/mrreviewer/ui/comments/card_renderer.lua
- lua/mrreviewer/ui/comments/card_navigator.lua

#### Sub-tasks:

##### Task 4.1: Analyze comments_panel.lua Responsibilities
**Status**: Not Started
**Description**: Document the distinct responsibilities within comments_panel.lua to determine split points.
**Files**:
- lua/mrreviewer/ui/diffview/comments_panel.lua
**Details**:
- Document comment grouping/filtering logic (lines 17-51, 311-334)
- Document card selection persistence logic (lines 468-660)
- Document rendering logic (lines 692-848)
- Document highlighting logic (lines 850-915)
- Document file section collapsing logic (lines 336-466)
- Document keymaps and autocmds (lines 102-291)
- Create a proposal for module split

##### Task 4.2: Extract Card Highlighting Module
**Status**: Not Started
**Description**: Move card highlighting logic into a separate module.
**Files**:
- lua/mrreviewer/ui/diffview/comments/panel.lua (existing)
- lua/mrreviewer/ui/diffview/comments/card_highlighting.lua (new)
**Details**:
- Move highlight_selected_card() function to card_highlighting.lua
- Move apply_highlighting() function to card_highlighting.lua
- Create a clean interface: setup(), highlight_card(buf, card_id), clear_highlights(buf)
- Update comments_panel.lua to use new module
- Test highlighting still works correctly

##### Task 4.3: Extract Section Collapse Module
**Status**: Not Started
**Description**: Move file section collapsing logic into a separate module.
**Files**:
- lua/mrreviewer/ui/diffview/comments/panel.lua (existing)
- lua/mrreviewer/ui/diffview/comments/section_collapse.lua (new)
**Details**:
- Move toggle_file_section() to section_collapse.lua
- Move is_section_collapsed() to section_collapse.lua
- Create interface: toggle_section(file_path), is_collapsed(file_path), get_collapsed_sections()
- Store collapsed state internally or in state module
- Update comments_panel.lua to use new module

##### Task 4.4: Extract Card Selection Persistence Module
**Status**: Not Started
**Description**: Move card selection persistence logic into a separate module.
**Files**:
- lua/mrreviewer/ui/diffview/comments/panel.lua (existing)
- lua/mrreviewer/ui/diffview/comments/card_selection.lua (new)
**Details**:
- Move save_selected_card() to card_selection.lua
- Move restore_selected_card_position() to card_selection.lua
- Create interface: save_selection(buf), restore_selection(buf, win), get_selected_card_id()
- Handle state management for selected card
- Update comments_panel.lua to use new module

##### Task 4.5: Extract Comment Filtering and Grouping Module
**Status**: Not Started
**Description**: Create a focused module for comment filtering and grouping operations.
**Files**:
- lua/mrreviewer/ui/diffview/comments/panel.lua (existing)
- lua/mrreviewer/ui/diffview/comments/filtering.lua (new)
**Details**:
- Move group_by_file() to filtering.lua
- Move filter_by_status() to filtering.lua
- Move identify_orphaned_comments() to filtering.lua (if still needed)
- Create interface: group_comments(comments, files), filter_comments(comments, options)
- Make functions pure (no side effects)
- Update comments_panel.lua to use new module

##### Task 4.6: Simplify comments_panel.lua Core
**Status**: Not Started
**Description**: Reduce comments_panel.lua to be a thin orchestration layer.
**Files**:
- lua/mrreviewer/ui/diffview/comments/panel.lua
**Details**:
- Keep only render() and setup_keymaps() as main public functions
- Delegate to specialized modules for all logic
- Ensure render() orchestrates but doesn't implement details
- Keep module under 300 lines total
- Add comprehensive module documentation

##### Task 4.7: Define Standard UI Component Interface
**Status**: Not Started
**Description**: Create a standard interface pattern for UI components.
**Files**:
- docs/development/ui-components.md (new)
- All UI component modules
**Details**:
- Define standard lifecycle: setup(), render(), update(), cleanup()
- Define standard state management pattern
- Define standard event handling pattern
- Document component communication patterns
- Create example template component
- Update existing components to follow interface where appropriate

##### Task 4.8: Reduce UI Component Coupling
**Status**: Not Started
**Description**: Minimize direct dependencies between UI components.
**Files**:
- All UI modules
**Details**:
- Identify direct cross-component state access
- Replace with callback/event patterns
- Use dependency injection for shared services
- Document component boundaries and interfaces
- Ensure components can be tested in isolation

---

### Task 5.0: Performance Optimization and Documentation
**Status**: Not Started
**Description**: Optimize rendering performance through caching and incremental updates. Create comprehensive documentation for the new architecture, including module dependencies and data flow.
**Acceptance Criteria**:
- Expensive computations cached appropriately
- Frequent operations debounced/throttled
- Architecture documentation created with module dependency diagram
- All utility modules documented with function signatures and examples
- Performance benchmarks showing improvements

**Relevant Files**:
- lua/mrreviewer/ui/diffview/comments_panel.lua
- lua/mrreviewer/ui/comments/card_renderer.lua
- lua/mrreviewer/ui/diffview/diff_panel.lua
- docs/ directory

#### Sub-tasks:

##### Task 5.1: Profile Current Performance
**Status**: Not Started
**Description**: Establish baseline performance metrics for key operations.
**Files**:
- lua/mrreviewer/ui/diffview/comments_panel.lua
- lua/mrreviewer/ui/comments/card_renderer.lua
**Details**:
- Measure comment panel render time with varying comment counts (10, 50, 100, 500 comments)
- Measure card navigation time (Tab key responsiveness)
- Measure file section toggle time
- Measure cursor movement handler execution time
- Document baseline metrics for comparison after optimization

##### Task 5.2: Implement Caching for Card Grouping
**Status**: Not Started
**Description**: Cache expensive card grouping and comment organization computations.
**Files**:
- lua/mrreviewer/ui/diffview/comments/panel.lua (or filtering.lua after refactor)
- lua/mrreviewer/ui/comments/card_renderer.lua
**Details**:
- Cache group_comments_into_cards() results keyed by comment list hash
- Cache comment grouping by file results
- Invalidate cache only when comments actually change
- Add cache hit/miss logging for debugging
- Measure performance improvement

##### Task 5.3: Implement Incremental Rendering
**Status**: Not Started
**Description**: Update only changed portions of the UI instead of full re-render.
**Files**:
- lua/mrreviewer/ui/diffview/comments/panel.lua
**Details**:
- Track which comments have changed since last render
- Only re-render affected file sections
- Preserve unchanged buffer sections
- Update line/card mappings incrementally
- Test with various update scenarios

##### Task 5.4: Debounce/Throttle Frequent Operations
**Status**: Not Started
**Description**: Add debouncing to high-frequency operations.
**Files**:
- lua/mrreviewer/ui/diffview/comments/panel.lua
- lua/mrreviewer/lib/utils.lua (add debounce utility)
**Details**:
- Create debounce() utility function
- Debounce CursorMoved autocmd handler (50ms)
- Debounce card highlight updates (50ms)
- Ensure responsiveness is maintained
- Test navigation feels instant

##### Task 5.5: Optimize State Access Patterns
**Status**: Not Started
**Description**: Reduce unnecessary state copies and access.
**Files**:
- lua/mrreviewer/core/state.lua
- All modules accessing state
**Details**:
- Identify modules making repeated state.get_diffview() calls
- Cache state references in local variables
- Use references instead of copies where safe
- Ensure state mutations are still tracked
- Measure impact on performance

##### Task 5.6: Create Architecture Documentation
**Status**: Not Started
**Description**: Document the overall system architecture and module dependencies.
**Files**:
- docs/development/architecture.md (new)
- docs/development/module-dependencies.md (new)
**Details**:
- Create module dependency diagram (ASCII art or mermaid)
- Document data flow from API → State → UI
- Document event flow (user actions → state updates → UI updates)
- Document core abstractions (cards, panels, state)
- Include diagrams for major features (diffview, comments, navigation)

##### Task 5.7: Document All Utility Modules
**Status**: Not Started
**Description**: Add comprehensive documentation to all utility functions.
**Files**:
- lua/mrreviewer/lib/utils/string.lua
- lua/mrreviewer/lib/utils/table.lua
- lua/mrreviewer/lib/utils/utf8.lua
- lua/mrreviewer/lib/utils.lua
**Details**:
- Add LuaLS/EmmyLua annotations for all functions
- Document parameters with types
- Document return values with types
- Add usage examples for each function
- Document edge cases and error conditions

##### Task 5.8: Create Developer Onboarding Guide
**Status**: Not Started
**Description**: Create comprehensive guide for new contributors.
**Files**:
- docs/development/getting-started.md (new)
- docs/development/contributing.md (update)
**Details**:
- Document codebase structure and organization
- Provide "where to find X" guide
- Document common development tasks
- Add troubleshooting guide
- Document testing procedures
- Link to architecture and component documentation

##### Task 5.9: Performance Benchmarking Suite
**Status**: Not Started
**Description**: Create automated benchmarks to track performance over time.
**Files**:
- tests/benchmarks/rendering.lua (new)
- tests/benchmarks/navigation.lua (new)
**Details**:
- Create benchmark for comment rendering with various sizes
- Create benchmark for card navigation
- Create benchmark for filtering operations
- Create benchmark for state operations
- Document how to run benchmarks
- Compare before/after optimization results

##### Task 5.10: Document Breaking Changes and Migration
**Status**: Not Started
**Description**: Create migration guide for internal API changes.
**Files**:
- docs/development/migration-guide.md (new)
- CHANGELOG.md (update)
**Details**:
- Document all internal API changes
- Provide before/after code examples
- Document new import paths after reorganization
- Document new utility function locations
- Note any behavior changes
- Add migration checklist for developers

---

## Notes
- Tasks will be executed in phases as outlined in the PRD
- Phase 1 (Tasks 1.0, 2.0) focuses on quick wins: file structure and utilities
- Phase 2 (Tasks 3.0, 4.0) focuses on major refactoring: error handling and UI
- Phase 3 (Task 5.0) focuses on optimization and documentation
- All changes maintain backward compatibility for users
- Breaking internal API changes are acceptable and will be documented
- Performance improvements should be measured and documented
