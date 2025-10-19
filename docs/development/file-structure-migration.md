# File Structure Migration Plan

This document maps the current file structure to the proposed reorganized structure for the repository cleanup initiative (PRD 0005).

## Overview

**Goal**: Reorganize the codebase into a clear module hierarchy with logical grouping:
- `core/` - Core modules (state, config, logger, errors)
- `lib/` - Shared utilities and libraries
- `ui/` - All UI components
- `integrations/` - External service integrations (glab, git)
- `api/` - Internal API layer

## File Migration Mapping

### Files Already in Correct Locations ✓

These files are already properly organized and don't need to be moved:

#### Core Modules (5 files)
- ✓ `lua/mrreviewer/core/config.lua` - Configuration management
- ✓ `lua/mrreviewer/core/errors.lua` - Error types and handling
- ✓ `lua/mrreviewer/core/logger.lua` - Logging framework
- ✓ `lua/mrreviewer/core/state.lua` - Global state management

#### Integration Modules (4 files)
- ✓ `lua/mrreviewer/integrations/git.lua` - Git operations
- ✓ `lua/mrreviewer/integrations/glab.lua` - GitLab CLI integration
- ✓ `lua/mrreviewer/integrations/mock_data.lua` - Mock data for testing
- ✓ `lua/mrreviewer/integrations/project.lua` - Project/repository management

#### API Modules (1 file)
- ✓ `lua/mrreviewer/api/commands.lua` - User-facing commands

#### Root Files (1 file)
- ✓ `lua/mrreviewer/init.lua` - Plugin entry point

**Total: 11 files already correctly placed**

---

### Files That Need to Be Moved

#### Parser Files (1 file)

| Current Path | New Path | Reason |
|--------------|----------|--------|
| `lua/mrreviewer/lib/parsers.lua` | `lua/mrreviewer/lib/parsers/gitlab.lua` | Better organization, room for additional parsers |

**Import changes required:**
- Current: `require('mrreviewer.lib.parsers')`
- New: `require('mrreviewer.lib.parsers.gitlab')`
- **Affected files**: 2 files
  - `lua/mrreviewer/api/commands.lua:6`
  - `lua/mrreviewer/ui/comments/init.lua:6`

---

#### Comment UI Component Files (4 files)

These files should be consolidated under `ui/diffview/comments/` for better cohesion:

| Current Path | New Path | Reason |
|--------------|----------|--------|
| `lua/mrreviewer/ui/comments/formatting.lua` | `lua/mrreviewer/ui/diffview/comments/formatting.lua` | Co-locate with comments panel |
| `lua/mrreviewer/ui/comments/card_renderer.lua` | `lua/mrreviewer/ui/diffview/comments/card_renderer.lua` | Co-locate with comments panel |
| `lua/mrreviewer/ui/comments/card_navigator.lua` | `lua/mrreviewer/ui/diffview/comments/card_navigator.lua` | Co-locate with comments panel |
| `lua/mrreviewer/ui/diffview/comments_panel.lua` | `lua/mrreviewer/ui/diffview/comments/panel.lua` | Consistent naming (*_panel.lua) |

**Import changes required:**
- Current: `require('mrreviewer.ui.comments.formatting')`
- New: `require('mrreviewer.ui.diffview.comments.formatting')`
- **Affected files**: 2 files
  - `lua/mrreviewer/ui/diffview/comments_panel.lua:9`
  - `lua/mrreviewer/ui/comments/init.lua:9`

- Current: `require('mrreviewer.ui.comments.card_renderer')`
- New: `require('mrreviewer.ui.diffview.comments.card_renderer')`
- **Affected files**: 1 file
  - `lua/mrreviewer/ui/diffview/comments_panel.lua:10`

- Current: `require('mrreviewer.ui.comments.card_navigator')`
- New: `require('mrreviewer.ui.diffview.comments.card_navigator')`
- **Affected files**: 1 file
  - `lua/mrreviewer/ui/diffview/comments_panel.lua:11`

- Current: `require('mrreviewer.ui.diffview.comments_panel')`
- New: `require('mrreviewer.ui.diffview.comments.panel')`
- **Affected files**: 5 files
  - `lua/mrreviewer/ui/diffview/init.lua:15`
  - `lua/mrreviewer/ui/comments/card_navigator.lua:100`
  - `lua/mrreviewer/ui/comments/card_navigator.lua:124`
  - `lua/mrreviewer/ui/comments/card_navigator.lua:209`
  - `lua/mrreviewer/ui/comments/card_navigator.lua:244`

---

#### Generic Comments UI Files (1 file)

| Current Path | New Path | Reason |
|--------------|----------|--------|
| `lua/mrreviewer/ui/comments/init.lua` | Keep as is | This is a generic comments module used by diff view, should stay at top level |

**Note**: After moving card-related files, verify if `ui/comments/init.lua` still serves a distinct purpose or if it should be refactored.

---

### Files That Stay in Current Location

These files are properly organized and should not be moved:

#### Library Files (3 files)
- `lua/mrreviewer/lib/position.lua` - Position/line utilities
- `lua/mrreviewer/lib/utils.lua` - General utilities

#### UI Files (18 files)
- `lua/mrreviewer/ui/ui.lua` - UI utilities
- `lua/mrreviewer/ui/highlights.lua` - Highlight definitions
- `lua/mrreviewer/ui/diff/init.lua` - Diff view module
- `lua/mrreviewer/ui/diff/keymaps.lua` - Diff view keymaps
- `lua/mrreviewer/ui/diff/navigation.lua` - Diff view navigation
- `lua/mrreviewer/ui/diff/view.lua` - Diff rendering
- `lua/mrreviewer/ui/diffview/init.lua` - Diffview orchestration
- `lua/mrreviewer/ui/diffview/layout.lua` - Diffview layout
- `lua/mrreviewer/ui/diffview/diff_panel.lua` - Diff panel component
- `lua/mrreviewer/ui/diffview/file_panel.lua` - File panel component
- `lua/mrreviewer/ui/diffview/file_tree.lua` - File tree rendering
- `lua/mrreviewer/ui/diffview/navigation.lua` - Diffview navigation

---

## Summary Statistics

- **Total files**: 30 Lua files
- **Files already correct**: 11 files (37%)
- **Files to move**: 5 files (17%)
- **Files to keep**: 14 files (46%)
- **Total import statements to update**: ~15 locations

---

## Import Dependency Analysis

### Core Module Imports
Most commonly imported core modules (in order):
1. `mrreviewer.core.state` - 8 files
2. `mrreviewer.core.logger` - 10 files
3. `mrreviewer.core.config` - 11 files
4. `mrreviewer.core.errors` - 5 files

### Library Module Imports
Most commonly imported library modules:
1. `mrreviewer.lib.utils` - 10 files
2. `mrreviewer.lib.parsers` - 2 files
3. `mrreviewer.lib.position` - 1 file

### UI Module Imports
Most commonly imported UI modules:
1. `mrreviewer.ui.highlights` - 7 files
2. `mrreviewer.ui.comments` - 3 files (navigation, keymaps, view)
3. `mrreviewer.ui.comments.formatting` - 2 files

### Integration Module Imports
Most commonly imported integration modules:
1. `mrreviewer.integrations.git` - 4 files (3 lazy-loaded)
2. `mrreviewer.integrations.project` - 4 files (all lazy-loaded)
3. `mrreviewer.integrations.glab` - 1 file
4. `mrreviewer.integrations.mock_data` - 2 files (conditional)

---

## Circular Dependency Risks

Potential circular dependencies to watch for:
1. ✓ No circular dependencies detected in core modules
2. ✓ No circular dependencies detected between integrations
3. ⚠️ `card_navigator.lua` requires `comments_panel.lua` within functions (lazy load) - acceptable pattern
4. ✓ All other dependencies are properly layered

---

## Migration Order Recommendation

To minimize disruption, migrate in this order:

1. **Phase 1**: Move parser files (low impact, 2 import updates)
   - Move `lib/parsers.lua` → `lib/parsers/gitlab.lua`
   - Update 2 import statements

2. **Phase 2**: Move comment components (higher impact, ~13 import updates)
   - Create `ui/diffview/comments/` directory
   - Move 4 comment-related files
   - Update all import statements
   - Verify card_navigator lazy loads still work

3. **Phase 3**: Verify and test
   - Run full test suite
   - Verify no broken imports
   - Test all user-facing features

---

## Post-Migration Verification Checklist

After migration, verify:
- [ ] All require statements resolve correctly
- [ ] No broken imports (check with grep for old paths)
- [ ] Plugin loads without errors (`:lua require('mrreviewer')`  )
- [ ] All commands work (`:MRReviewerDiffview`, etc.)
- [ ] Lazy-loaded requires still work (card_navigator callbacks)
- [ ] No runtime errors in logs

---

## Future Refactoring Opportunities

After this migration, consider:
1. Split `ui/comments/init.lua` if card-specific code remains after card file moves
2. Consider creating `lib/utils/` subdirectory for specialized utilities (will be done in Task 2.0)
3. Review if `ui/ui.lua` should be renamed to `ui/utils.lua` for clarity
4. Consider splitting large files like `comments_panel.lua` (will be done in Task 4.0)

---

## Notes

- All paths assume the repository root is `/Users/jeffor/Documents/mrreviewer/`
- Import paths use Lua dot notation: `mrreviewer.module.submodule`
- File paths use filesystem notation: `lua/mrreviewer/module/submodule.lua`
- This migration maintains backward compatibility for user-facing APIs
- Internal API changes are acceptable per PRD guidelines
