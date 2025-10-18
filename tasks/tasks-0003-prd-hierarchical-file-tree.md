# Task List: Hierarchical File Tree for File Panel

Generated from: `0003-prd-hierarchical-file-tree.md`

## Current State Assessment

### Existing Infrastructure
- **File Panel:** `ui/diffview/file_panel.lua` currently renders a flat list of files
- **State Management:** `core/state.lua` manages diffview state
- **Configuration:** `core/config.lua` handles user settings
- **Rendering:** File panel uses simple line-by-line rendering with indentation
- **Navigation:** Basic j/k/Enter navigation already implemented

### Reusable Components
- `calculate_comment_counts()` - Can be reused for file nodes
- `get_file_at_cursor()` - Needs enhancement to extract from tree format
- `on_file_selected()` - Can be reused with minor modifications
- `setup_keymaps()` - Needs enhancement for directory collapse/expand
- `highlight_selected_file()` - Needs update for tree format parsing

### Architecture Pattern
- Modular structure with clear separation of concerns
- State accessed via `state.get_*()` functions
- Configuration via `config.get_value()`
- Logger for debugging with `logger.info/warn/error()`

---

## Tasks

### 1.0 Create Node-Based Tree Data Structure ✓
- [x] 1.1 Create new file `lua/mrreviewer/ui/diffview/file_tree.lua`
- [x] 1.2 Define Node class/table structure with fields: name, path, kind, parent, children, depth, collapsed, comment_count
- [x] 1.3 Implement `Node.new(name, path, kind, parent, depth)` constructor function
- [x] 1.4 Implement `Node:add_child(child_node)` method to add children
- [x] 1.5 Implement `Node:is_file()` and `Node:is_dir()` helper methods
- [x] 1.6 Implement `Node:get_full_path()` method to return complete path
- [x] 1.7 Add logger integration for debugging node operations

### 2.0 Implement Tree Building from Flat File List
- [x] 2.1 Implement `build_tree(file_paths)` function in `file_tree.lua`
- [x] 2.2 Add logic to parse file paths and extract directory components
- [x] 2.3 Implement directory node creation for intermediate directories
- [x] 2.4 Add logic to attach file nodes to appropriate parent directories
- [x] 2.5 Implement depth calculation based on path hierarchy
- [x] 2.6 Add sorting logic within directories (dirs before files, alphabetical)
- [x] 2.7 Add comment count integration for file nodes using `calculate_comment_counts()`
- [ ] 2.8 Add unit tests for tree building with various file path structures

### 3.0 Add Collapse/Expand State Management ✓
- [x] 3.1 Add `collapsed_dirs` field to diffview state in `core/state.lua`
- [x] 3.2 Implement `toggle_directory(dir_path)` function in `file_panel.lua`
- [x] 3.3 Update state when directory is collapsed/expanded
- [x] 3.4 Implement `is_directory_collapsed(dir_path)` helper function
- [x] 3.5 Add state persistence across re-renders
- [x] 3.6 Implement `collapse_all()` and `expand_all()` utility functions
- [x] 3.7 Update `clear_diffview()` in state.lua to clear collapsed_dirs

### 4.0 Implement Tree Rendering with Visual Hierarchy
- [x] 4.1 Implement `flatten_visible_nodes(tree, collapsed_state)` function
- [x] 4.2 Add depth-first traversal that skips children of collapsed directories
- [ ] 4.3 Update `render()` function in `file_panel.lua` to use tree rendering
- [ ] 4.4 Implement indentation based on node depth (configurable spaces)
- [ ] 4.5 Add visual indicators: ▾ (expanded), ▸ (collapsed), • (file)
- [ ] 4.6 Preserve comment count display for files: "💬 resolved/total"
- [ ] 4.7 Update `highlight_selected_file()` to parse tree format lines
- [ ] 4.8 Store node metadata in buffer variables for cursor operations

### 5.0 Enhance Navigation for Tree Structure
- [ ] 5.1 Update `get_file_at_cursor()` to detect both files and directories
- [ ] 5.2 Add `get_node_at_cursor()` function returning {type, path, node}
- [ ] 5.3 Update `<CR>` keymap to handle directory toggle vs file selection
- [ ] 5.4 Add `<Tab>` keymap alternative for toggling directories
- [ ] 5.5 Add `za` keymap (vim-style fold toggle) for directories
- [ ] 5.6 Update `on_file_selected()` to only trigger for file nodes
- [ ] 5.7 Implement re-render after directory toggle
- [ ] 5.8 Preserve cursor position after re-render

### 6.0 Add Configuration Options
- [ ] 6.1 Add `diffview.file_tree` section to `core/config.lua` defaults
- [ ] 6.2 Add `indent` config option (default: 2 spaces)
- [ ] 6.3 Add `collapse_dirs` config option (default: true)
- [ ] 6.4 Add `dir_collapsed_icon` config option (default: "▸")
- [ ] 6.5 Add `dir_expanded_icon` config option (default: "▾")
- [ ] 6.6 Add `file_icon` config option (default: "•")
- [ ] 6.7 Update rendering logic to use config values for icons and indentation
- [ ] 6.8 Add configuration validation in setup

### 7.0 Add Tests and Documentation
- [ ] 7.1 Create `tests/ui/diffview/file_tree_spec.lua` for Node and tree building tests
- [ ] 7.2 Add tests for tree building with nested directories
- [ ] 7.3 Add tests for tree building with edge cases (root files, deep nesting)
- [ ] 7.4 Add tests for collapse/expand state management
- [ ] 7.5 Add tests for visible node flattening
- [ ] 7.6 Add integration test for full file panel rendering with tree
- [ ] 7.7 Update README with file tree feature description
- [ ] 7.8 Add inline documentation/comments for tree-related functions

---

**Status:** Detailed sub-tasks generated. Ready for implementation.

All sub-tasks have been generated with specific implementation details. Each task is actionable and references the specific files and functions that need to be created or modified.
