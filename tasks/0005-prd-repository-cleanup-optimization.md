# PRD: Repository Cleanup and Optimization

## Introduction/Overview

This PRD outlines a comprehensive cleanup and optimization initiative for the mrreviewer repository. The audit revealed several opportunities to improve code organization, reduce duplication, enhance error handling, and better leverage external packages (specifically plenary.nvim). This work will improve maintainability, reduce technical debt, and make the codebase easier to understand and extend.

The cleanup will be executed in a phased approach, starting with quick wins (utility consolidation, duplication removal) before moving to larger architectural improvements.

## Goals

1. **Improve Code Organization**: Restructure files and modules for better logical grouping and discoverability
2. **Reduce Code Duplication**: Consolidate repeated patterns and utilities into shared modules
3. **Enhance External Package Usage**: Leverage more plenary.nvim utilities to avoid reinventing the wheel
4. **Improve Error Handling**: Implement consistent, robust error handling and logging across all modules
5. **Optimize Performance**: Identify and eliminate performance bottlenecks
6. **Maintain Stability**: Ensure all changes are backward compatible for users (breaking internal API changes are acceptable)

## User Stories

1. **As a developer**, I want a well-organized file structure so that I can quickly find and understand the code I need to modify
2. **As a developer**, I want consistent utility functions so that I don't have to reimplement common patterns
3. **As a developer**, I want comprehensive error handling so that I can debug issues quickly when they occur
4. **As a maintainer**, I want to use well-tested external libraries so that I spend less time maintaining custom implementations
5. **As a user**, I want better performance so that the plugin responds faster during code reviews

## Functional Requirements

### Phase 1: Quick Wins (Foundation)

#### 1.1 File Structure Reorganization
1. Create a clear module hierarchy in `lua/mrreviewer/`:
   - `core/` - Core modules (state, config, logger, errors)
   - `lib/` - Shared utilities
   - `ui/` - All UI components
   - `integrations/` - External service integrations (glab, git)
   - `api/` - Internal API layer (if needed)

2. Consolidate related files:
   - Move all parsing logic to `lib/parsers/`
   - Group all UI components logically (diffview, comments, file tree)
   - Ensure consistent naming conventions (e.g., `*_panel.lua`, `*_renderer.lua`)

#### 1.2 Utility Consolidation
3. Audit all modules for duplicate utility functions:
   - String manipulation (trimming, splitting, formatting)
   - Table operations (merge, filter, map)
   - File path operations
   - UTF-8 handling

4. Create or enhance utility modules:
   - `lib/utils/string.lua` - String utilities
   - `lib/utils/table.lua` - Table operations
   - `lib/utils/utf8.lua` - UTF-8 handling (emoji patterns, multi-byte chars)
   - `lib/utils/path.lua` - File path operations (or use plenary)

5. Replace all duplicate implementations with calls to consolidated utilities

#### 1.3 Plenary.nvim Integration
6. Identify areas where plenary.nvim can replace custom code:
   - Path operations: Use `plenary.path` instead of custom path handling
   - Async operations: Use `plenary.async` for I/O operations
   - Functional utilities: Use `plenary.tbl` for table operations
   - Scandir: Use `plenary.scandir` for directory operations

7. Replace custom implementations with plenary utilities:
   - Document which plenary modules are being used
   - Add plenary.nvim to dependencies if not already present
   - Ensure proper error handling when using plenary functions

#### 1.4 Error Handling Enhancement
8. Standardize error handling patterns across all modules:
   - Use the existing `errors.lua` module consistently
   - Add error type for each failure scenario
   - Include context in all error messages

9. Enhance logging throughout the codebase:
   - Add debug logs for major function entry/exit
   - Add info logs for user-facing operations
   - Add warn logs for recoverable issues
   - Add error logs for failures

10. Create error handling guidelines document:
    - When to use error objects vs simple returns
    - How to add context to errors
    - Logging best practices

### Phase 2: Major Refactoring (Architecture)

#### 2.1 UI Module Restructuring
11. Break down complex UI modules into focused components:
    - `ui/diffview/comments_panel.lua` is very large - split into:
      - `comments_panel.lua` - Main panel logic
      - `card_highlighting.lua` - Card selection and highlighting
      - `card_navigation.lua` - Already exists, ensure clean interface
      - `section_collapse.lua` - File section collapse logic

12. Create consistent interfaces for UI components:
    - Define standard lifecycle methods (setup, render, cleanup)
    - Standardize state management patterns
    - Document component interfaces

13. Reduce inter-component coupling:
    - Use dependency injection where appropriate
    - Create clear module boundaries
    - Minimize direct state access across modules

#### 2.2 Code Duplication Elimination
14. Identify and consolidate duplicate code patterns:
    - Comment filtering logic
    - Buffer manipulation patterns
    - Highlight application
    - Keymap setup

15. Create reusable components:
    - Generic panel renderer
    - Generic keymap handler
    - Generic state persistence

#### 2.3 Performance Optimization
16. Optimize rendering performance:
    - Cache expensive computations (card grouping, line counts)
    - Debounce/throttle frequent operations (cursor movement handlers)
    - Use incremental updates where possible

17. Optimize state management:
    - Reduce unnecessary state copies
    - Use references where appropriate
    - Clear unused state promptly

18. Optimize I/O operations:
    - Use plenary.async for file operations
    - Batch multiple operations
    - Cache file reads when appropriate

### Phase 3: Documentation & Testing

#### 3.1 Documentation
19. Create architecture documentation:
    - Module dependency diagram
    - Data flow documentation
    - State management guide

20. Document all utility modules:
    - Function signatures with types
    - Usage examples
    - Edge cases and error conditions

21. Update existing documentation:
    - Reflect new file structure
    - Update developer guide
    - Document breaking API changes

#### 3.2 Testing Enhancement
22. Add unit tests for utility modules:
    - Test all edge cases
    - Test error conditions
    - Test UTF-8 handling

23. Add integration tests for critical paths:
    - Comment rendering
    - Navigation
    - State persistence

## Non-Goals (Out of Scope)

1. **UI Framework Migration**: Will NOT migrate to nui.nvim in this phase (may be future work)
2. **User-Facing Changes**: Will NOT change user-facing features or commands
3. **New Features**: Will NOT add new functionality (only cleanup/optimization)
4. **External API Changes**: Will NOT modify the public plugin API that users depend on
5. **Complete Rewrite**: Will NOT do a ground-up rewrite of any major component

## Design Considerations

### File Structure (Proposed)
```
lua/mrreviewer/
├── core/              # Core functionality
│   ├── state.lua
│   ├── config.lua
│   ├── logger.lua
│   └── errors.lua
├── lib/               # Shared utilities
│   ├── utils/
│   │   ├── string.lua
│   │   ├── table.lua
│   │   ├── utf8.lua
│   │   └── path.lua
│   └── parsers/
│       └── gitlab.lua
├── integrations/      # External services
│   ├── glab/
│   │   ├── init.lua
│   │   └── api.lua
│   └── git/
│       └── init.lua
├── ui/                # UI components
│   ├── diffview/
│   │   ├── init.lua
│   │   ├── layout.lua
│   │   ├── diff_panel.lua
│   │   ├── file_panel.lua
│   │   ├── navigation.lua
│   │   └── comments/
│   │       ├── panel.lua
│   │       ├── card_renderer.lua
│   │       ├── card_navigator.lua
│   │       ├── card_highlighting.lua
│   │       └── section_collapse.lua
│   ├── comments/
│   │   ├── init.lua
│   │   └── formatting.lua
│   └── highlights.lua
└── init.lua           # Plugin entry point
```

### UTF-8 Handling Module
Create `lib/utils/utf8.lua`:
- `find_emoji(str, emoji)` - Find emoji position in string
- `find_utf8_char(str, char)` - Find any UTF-8 character
- `is_box_drawing(char)` - Check if character is box-drawing
- `get_char_width(char)` - Get byte width of UTF-8 character

### Error Handling Pattern
```lua
-- Standard pattern
local result, err = module.function(args)
if err then
  logger.error('module', 'Operation failed', { error = err, context = args })
  return nil, errors.wrap(err, 'Additional context')
end
```

## Technical Considerations

1. **Backward Compatibility**: All changes must maintain the same user-facing API
2. **Dependencies**: Ensure plenary.nvim is properly documented as a required dependency
3. **Migration Path**: Create migration guide for any breaking internal API changes
4. **Performance Testing**: Benchmark before/after for rendering and navigation operations
5. **Code Review**: All refactoring should be reviewed in manageable PRs (not one massive change)

## Success Metrics

### Code Quality Metrics
1. **Lines of Code**: Reduce total LOC by 10-15% through deduplication
2. **Module Coupling**: Reduce cross-module dependencies by 30%
3. **Function Complexity**: Reduce average function length from X to Y lines
4. **Code Duplication**: Eliminate 80%+ of identified duplicate code

### Performance Metrics
1. **Render Time**: Reduce comment panel render time by 20%
2. **Navigation Speed**: Tab navigation should feel instant (<50ms)
3. **Memory Usage**: No increase in memory footprint

### Maintainability Metrics
1. **Test Coverage**: Achieve 60%+ coverage on utility modules
2. **Documentation**: 100% of public functions documented
3. **Onboarding Time**: Reduce time for new contributor to understand codebase

## Open Questions - ANSWERED

1. **Plenary Version**: ✅ Target latest version of plenary.nvim
2. **Breaking Changes**: ✅ No compatibility layer needed - breaking changes are acceptable as project is in development
3. **Testing Strategy**: ✅ Use plenary.busted for testing (already integrated)
4. **Migration Timing**: ✅ Single major release with all changes
5. **User Communication**: ✅ Not needed for internal changes

## Implementation Notes

### Phased Rollout
- **Phase 1 (Quick Wins)**: 2-3 weeks
  - Can be done incrementally
  - Low risk of breaking changes
  - Immediate benefits

- **Phase 2 (Major Refactoring)**: 3-4 weeks
  - Requires more careful planning
  - Higher risk, needs thorough testing
  - Significant long-term benefits

- **Phase 3 (Documentation)**: 1-2 weeks
  - Can be done in parallel with Phase 2
  - Ongoing maintenance

### Review Process
1. Each phase should be broken into smaller PRs
2. Each PR should be independently testable
3. Performance benchmarks should be included for optimization PRs
4. Documentation updates should accompany code changes

## Appendix: Audit Findings Summary

### File Structure Issues
- Inconsistent naming conventions across modules
- Some files are in non-intuitive locations
- Deep nesting in some areas (ui/diffview/)

### Code Duplication Examples
- String trimming/whitespace handling (multiple implementations)
- Table utility functions (merge, filter, map) scattered across files
- UTF-8 character handling repeated in multiple places
- Buffer highlight application patterns

### External Package Opportunities
- Path operations could use `plenary.path`
- Async file operations could use `plenary.async`
- Table utilities could use `plenary.tbl`
- Directory scanning could use `plenary.scandir`

### Performance Issues Identified
- Card rendering recalculates everything on each render
- No caching of expensive operations
- Some synchronous operations could be async
- Repeated buffer line reads in tight loops

### Error Handling Gaps
- Inconsistent error return patterns
- Missing error context in many places
- Some errors silently swallowed
- Logging gaps in critical paths
