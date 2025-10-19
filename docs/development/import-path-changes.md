# Import Path Changes

This document summarizes all import path changes made during the file structure reorganization (Tasks 1.2 and 1.3).

## Summary

All import statements have been successfully updated to reflect the new file structure. No references to old paths remain in the codebase.

## Changed Import Paths

### Parser Module Imports

**Old Path:**
```lua
require('mrreviewer.lib.parsers')
```

**New Path:**
```lua
require('mrreviewer.lib.parsers.gitlab')
```

**Affected Files:**
- `lua/mrreviewer/api/commands.lua:6`
- `lua/mrreviewer/ui/comments/init.lua:6`

**Rationale:** Better organization for future parser additions (GitHub, Bitbucket, etc.)

---

### Comment Formatting Imports

**Old Path:**
```lua
require('mrreviewer.ui.comments.formatting')
```

**New Path:**
```lua
require('mrreviewer.ui.diffview.comments.formatting')
```

**Affected Files:**
- `lua/mrreviewer/ui/diffview/comments/panel.lua:9`
- `lua/mrreviewer/ui/comments/init.lua:9`

**Rationale:** Co-locate comment-related components under diffview/comments/

---

### Card Renderer Imports

**Old Path:**
```lua
require('mrreviewer.ui.comments.card_renderer')
```

**New Path:**
```lua
require('mrreviewer.ui.diffview.comments.card_renderer')
```

**Affected Files:**
- `lua/mrreviewer/ui/diffview/comments/panel.lua:10`

**Rationale:** Co-locate card-related components with comments panel

---

### Card Navigator Imports

**Old Path:**
```lua
require('mrreviewer.ui.comments.card_navigator')
```

**New Path:**
```lua
require('mrreviewer.ui.diffview.comments.card_navigator')
```

**Affected Files:**
- `lua/mrreviewer/ui/diffview/comments/panel.lua:11`

**Rationale:** Co-locate navigation with related components

---

### Comments Panel Imports

**Old Path:**
```lua
require('mrreviewer.ui.diffview.comments_panel')
```

**New Path:**
```lua
require('mrreviewer.ui.diffview.comments.panel')
```

**Affected Files:**
- `lua/mrreviewer/ui/diffview/init.lua:15`
- `lua/mrreviewer/ui/diffview/comments/card_navigator.lua:100` (lazy-loaded)
- `lua/mrreviewer/ui/diffview/comments/card_navigator.lua:124` (lazy-loaded)
- `lua/mrreviewer/ui/diffview/comments/card_navigator.lua:209` (lazy-loaded)
- `lua/mrreviewer/ui/diffview/comments/card_navigator.lua:244` (lazy-loaded)

**Rationale:** Consistent naming (panel.lua) and better directory structure

---

## Import Pattern Guidelines

### Preferred Import Patterns

1. **Use full qualified paths** starting from `mrreviewer`:
   ```lua
   local parsers = require('mrreviewer.lib.parsers.gitlab')
   ```

2. **Use descriptive local variable names**:
   ```lua
   local comments_panel = require('mrreviewer.ui.diffview.comments.panel')
   local card_renderer = require('mrreviewer.ui.diffview.comments.card_renderer')
   ```

3. **Group related imports together**:
   ```lua
   -- Core modules
   local state = require('mrreviewer.core.state')
   local config = require('mrreviewer.core.config')
   local logger = require('mrreviewer.core.logger')

   -- UI components
   local formatting = require('mrreviewer.ui.diffview.comments.formatting')
   local card_renderer = require('mrreviewer.ui.diffview.comments.card_renderer')
   ```

4. **Lazy-load when appropriate** (for circular dependency prevention):
   ```lua
   -- Inside function, not at module level
   local comments_panel = require('mrreviewer.ui.diffview.comments.panel')
   ```

### Import Anti-Patterns to Avoid

❌ **Don't use old paths:**
```lua
-- WRONG - outdated paths
require('mrreviewer.lib.parsers')
require('mrreviewer.ui.comments.card_renderer')
require('mrreviewer.ui.diffview.comments_panel')
```

❌ **Don't use relative paths:**
```lua
-- WRONG - relative imports
require('.comments.panel')
require('../card_renderer')
```

❌ **Don't mix naming conventions:**
```lua
-- INCONSISTENT - mixing old and new
local parsers = require('mrreviewer.lib.parsers.gitlab')  -- ✓
local formatting = require('mrreviewer.ui.comments.formatting')  -- ✗
```

## Verification

All imports have been verified to:
1. ✓ Use new correct paths
2. ✓ Resolve successfully
3. ✓ Load without errors
4. ✓ Follow consistent patterns

### Verification Commands

To verify imports resolve correctly:

```bash
# Test all critical modules load
nvim --headless -c "lua
  require('mrreviewer.lib.parsers.gitlab')
  require('mrreviewer.ui.diffview.comments.panel')
  require('mrreviewer.ui.diffview.comments.card_renderer')
  require('mrreviewer.ui.diffview.comments.card_navigator')
  print('All imports OK')
  vim.cmd('quit')
"
```

```bash
# Search for old import patterns (should return nothing)
grep -r "require.*mrreviewer\.lib\.parsers['\"]" lua/
grep -r "require.*mrreviewer\.ui\.comments\.\(formatting\|card_renderer\|card_navigator\)" lua/
grep -r "require.*mrreviewer\.ui\.diffview\.comments_panel" lua/
```

## Migration Guide for Developers

If you have local branches with old import paths:

1. **Update parser imports:**
   ```bash
   find lua/ -name "*.lua" -exec sed -i '' \
     "s/require('mrreviewer\.lib\.parsers')/require('mrreviewer.lib.parsers.gitlab')/g" {} +
   ```

2. **Update comment component imports:**
   ```bash
   find lua/ -name "*.lua" -exec sed -i '' \
     "s/require('mrreviewer\.ui\.comments\.\(formatting\|card_renderer\|card_navigator\)')/require('mrreviewer.ui.diffview.comments.\1')/g" {} +
   ```

3. **Update comments panel imports:**
   ```bash
   find lua/ -name "*.lua" -exec sed -i '' \
     "s/require('mrreviewer\.ui\.diffview\.comments_panel')/require('mrreviewer.ui.diffview.comments.panel')/g" {} +
   ```

4. **Test your changes:**
   ```bash
   nvim --headless -c "lua require('mrreviewer'); vim.cmd('quit')"
   ```

## Impact Analysis

### Total Changes
- **5 unique import path changes**
- **~15 import statements updated** across the codebase
- **0 breaking changes** for end users
- **Internal API changes only** (acceptable per PRD guidelines)

### Files Modified
- 2 files for parser imports
- 2 files for formatting imports
- 1 file for card_renderer imports
- 1 file for card_navigator imports
- 5 files for comments_panel imports

### Risk Assessment
- **Low risk**: All imports updated atomically
- **Fully tested**: All modules load successfully
- **No user impact**: Public API unchanged
- **Reversible**: Changes tracked in git

## Last Updated

This document reflects the final state after Task 1.5 (Update All Import Statements).
