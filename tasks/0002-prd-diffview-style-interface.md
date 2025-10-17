# PRD: Diffview-Style Interface with Integrated Comments

## Introduction/Overview

This feature transforms MRReviewer into an integrated diff viewing experience similar to diffview.nvim, with a three-pane layout that combines file navigation, side-by-side diff viewing, and comment browsing in a single unified interface. The goal is to provide developers with a comprehensive MR review experience where they can easily navigate between files, view changes, and interact with comments without switching between different views or windows.

**Problem it solves:** Currently, users must switch between different views or commands to see the diff and comments. This creates a fragmented review experience where it's difficult to understand the relationship between code changes and reviewer feedback. The new interface consolidates everything into a single, intuitive view.

## Goals

1. Create a three-pane layout (file tree | diff view | comments) that displays all MR information simultaneously
2. Enable seamless navigation from comments to their corresponding code locations
3. Provide visual indicators for comment density across changed files
4. Replace the current diff viewing experience with a more comprehensive solution
5. Maintain keyboard-driven navigation consistent with Vim/Neovim conventions
6. Support bidirectional navigation between diff view and comments

## User Stories

1. **As a code reviewer**, I want to see all changed files, the diffs, and comments in a single view so that I can efficiently review an MR without context switching.

2. **As a developer**, I want to navigate to a comment and immediately see its location in the code diff so that I can understand the reviewer's feedback in context.

3. **As a reviewer**, I want to see which files have the most comments at a glance so that I can prioritize reviewing files with more discussion.

4. **As a developer**, I want to navigate through the diff and see corresponding comments highlighted automatically so that I don't miss any feedback.

5. **As a reviewer**, I want to quickly filter between resolved and unresolved comments so that I can focus on outstanding items.

6. **As a developer**, I want to open detailed comment threads when needed while keeping the main view focused on the code so that I can read full discussions without cluttering the interface.

## Functional Requirements

### Layout & Window Management

1. The plugin must create a three-pane layout when reviewing an MR:
   - **Left pane (20% width):** File tree showing all changed files
   - **Center pane (60% width):** Side-by-side diff view (old version | new version)
   - **Right pane (20% width):** Comments list buffer

2. The layout must use fixed proportions (20% | 60% | 20%) for the three panes.

3. Users must be able to navigate between panes using standard Neovim window navigation commands (`<C-w>h`, `<C-w>l`, `<C-w>j`, `<C-w>k`).

4. The layout must be created automatically when a user reviews an MR (replacing the current diff view entirely).

### File Tree (Left Pane)

5. The file tree must display all files that have changes in the MR.

6. Each file entry must show a comment count indicator using the format: `💬 <resolved>/<total>` (e.g., "💬 3/5" meaning 3 resolved out of 5 total) if the file has comments.

7. Files without comments must be displayed without any comment indicator.

8. The file tree must match the visual style and behavior of diffview.nvim's file panel.

9. Users must be able to select a file in the tree to view its diff in the center pane.

10. The currently selected file must be visually highlighted in the file tree.

11. Files in the tree must be ordered using natural file system ordering (matching how file explorers like neotree or diffview.nvim order files).

### Diff View (Center Pane)

12. The diff view must display changes in a side-by-side format with:
    - Left side: Old version of the file
    - Right side: New version of the file

13. The diff view must use the same rendering approach as diffview.nvim (study and replicate their diff rendering method).

14. When a user selects a comment in the comments pane, the diff view must:
    - Navigate to the file containing that comment
    - Scroll to the line where the comment is located
    - Highlight the commented line(s) using a distinctive highlight color

15. The highlight duration must be configurable by users. The configuration must support:
    - A numeric value in milliseconds (e.g., `2000` for 2 seconds)
    - `nil` or `0` to keep the highlight permanently visible until the user navigates away

16. The diff view must support bidirectional navigation: when the user navigates to different locations in the diff, the corresponding comment in the comments pane must be highlighted (if one exists at that location).

17. The diff view must update immediately when a different file is selected from the file tree.

### Comments Pane (Right Pane)

18. The comments pane must display all comments for the current MR.

19. Comments must be grouped by file, matching the order in the file tree.

20. Each comment entry must display (minimal format):
    - File name (if it's the first comment for that file, or as a group header)
    - Line number
    - Author username
    - First line of the comment body
    - Reply count if the comment has replies (e.g., "+3 replies")

21. The comments pane must visually distinguish between resolved and unresolved comments (e.g., using different colors or icons).

22. Users must be able to filter comments by resolved/unresolved status using a keyboard shortcut.

23. When a user presses `<Enter>` on a comment in the comments pane:
    - The diff view must navigate to the file and line of that comment
    - The commented line(s) must be highlighted according to the configured duration (requirement #15)
    - The cursor must remain in the comments pane

24. When a user presses `KK` while on a comment, the plugin must open the full comment window/floating window showing the complete comment thread (maintaining existing behavior for detailed comment viewing).

25. Empty lines or visual separators must be used to group comments by file for better readability.

26. When there are no comments to display, the comments pane must remain blank (no message).

### Navigation & Interaction

27. The plugin must support standard Neovim window navigation (`<C-w>h/j/k/l`) for moving between the three panes.

28. When the layout first opens, the file tree pane must have focus by default. This should be configurable via plugin setup options.

29. When the cursor is in the file tree:
    - `j`/`k` must move up/down through files
    - `<Enter>` must select a file and display its diff

30. When the cursor is in the comments pane:
    - `j`/`k` must move up/down through comments
    - `<Enter>` must jump to the comment location in the diff view
    - `KK` must open the full comment thread in a floating window

31. When the cursor is in the diff view:
    - Standard Vim navigation must work
    - If the cursor moves to a line with a comment, the corresponding comment in the comments pane must be automatically highlighted

32. Any keybinding conflicts with existing MRReviewer keybindings must be resolved in favor of the new diffview keybindings.

### Comment Indicators

33. The file tree must display comment count indicators using the format `💬 <resolved>/<total>` (e.g., "💬 3/5").

34. Files without comments must not display any indicator.

### Visual Feedback

35. When navigating to a comment location, the highlighted line(s) must use a distinctive highlight color (e.g., different from standard diff highlights).

36. The highlight behavior must follow the configured duration from requirement #15 (either timed or permanent).

37. The currently selected comment in the comments pane must be visually highlighted with a background color or indicator.

38. When bidirectional navigation highlights a comment in the comments pane, it must use the same visual style as manual selection.

### Error Handling

39. When errors occur during data fetching or diff rendering (e.g., `glab` API errors, missing files):
    - The plugin must display an error notification using `vim.notify` with level `ERROR`
    - The error message must be descriptive and include the operation that failed
    - The interface should gracefully degrade (e.g., show empty panes with error message rather than crashing)

40. All errors must be logged using the existing logger module for debugging purposes.

### Configuration Options

41. The following configuration options must be added to the plugin setup:
    - `diffview.highlight_duration`: Duration in milliseconds for comment highlight (number or `nil` for permanent)
    - `diffview.default_focus`: Which pane should have focus on open (`'files'`, `'diff'`, or `'comments'`)
    - `diffview.show_resolved`: Boolean to show resolved comments by default (default: `true`)

## Non-Goals (Out of Scope)

1. **Comment threading/replies:** For this initial implementation, we will not display threaded replies inline in the comments pane. This is a future enhancement.

2. **Performance optimization for large MRs:** The initial implementation will load all files and comments upfront. Lazy loading and pagination will be considered for future improvements.

3. **Adjustable window sizes:** Users will not be able to resize panes with keyboard shortcuts in the initial version. This is a future enhancement.

4. **Multiple grouping options for comments:** Only grouping by file will be supported initially. Additional grouping options (by status, chronological) are future enhancements.

5. **Advanced filtering:** Only resolved/unresolved filtering will be supported. Filtering by author, date, or file is a future enhancement.

6. **Inline comment creation:** This feature focuses on viewing and navigating existing comments, not creating new ones.

7. **Side-by-side comparison of multiple MRs:** The interface is designed for reviewing a single MR at a time.

8. **Integration with GitHub or other platforms:** This feature continues to focus exclusively on GitLab MRs via the `glab` CLI.

9. **Session persistence:** Selected file and comment positions will not be remembered across sessions. This may be added as a future enhancement.

## Design Considerations

### Layout Reference

The layout should closely match the visual style of diffview.nvim as shown in the reference image:

```
┌─────────────────┬────────────────────────────────────┬──────────────────┐
│                 │                                    │                  │
│   File Tree     │         Diff View                  │  Comments List   │
│   (20%)         │         (Side-by-side)             │  (20%)           │
│                 │         (60%)                      │                  │
│  📁 src/        │  Old Version    │  New Version     │  📝 Comments     │
│    file1.lua    │                 │                  │                  │
│    💬 3/5       │  - old line     │  + new line      │  File: file1.lua │
│    file2.lua    │  - old line     │  + new line      │  Line 45         │
│    💬 2/2       │                 │                  │  @author         │
│    file3.lua    │                 │                  │  "Comment text"  │
│                 │                 │                  │  +2 replies      │
│                 │                 │                  │                  │
│                 │                 │                  │  Line 102        │
│                 │                 │                  │  @reviewer       │
│                 │                 │                  │  "More feedback" │
└─────────────────┴────────────────────────────────────┴──────────────────┘
```

### Highlight Groups

- Define new highlight groups for:
  - Comment indicators in file tree (e.g., `MRReviewerCommentCount`)
  - Highlighted comment lines in diff view (e.g., `MRReviewerCommentHighlight`)
  - Selected comment in comments pane (e.g., `MRReviewerSelectedComment`)
  - Resolved vs unresolved comments (e.g., `MRReviewerResolvedComment`, `MRReviewerUnresolvedComment`)
  - File group headers in comments pane (e.g., `MRReviewerCommentFileHeader`)

### Keyboard Shortcuts

The following keybindings should be implemented:

| Key | Context | Action |
|-----|---------|--------|
| `<C-w>h/j/k/l` | Any pane | Navigate between windows |
| `<Enter>` | File tree | Select file and show diff |
| `<Enter>` | Comments pane | Jump to comment location |
| `KK` | Comments pane | Open full comment thread |
| `j`/`k` | File tree | Navigate files |
| `j`/`k` | Comments pane | Navigate comments |
| `[unresolved]`/`]unresolved` | Comments pane | Filter unresolved comments (suggested) |

## Technical Considerations

### Module Structure

Based on the new organized structure, the following modules will be affected or created:

- **`lua/mrreviewer/ui/diffview/` (new):** Main diffview interface logic
  - `init.lua` - Entry point and layout creation
  - `layout.lua` - Window/pane management
  - `file_panel.lua` - File tree implementation
  - `diff_panel.lua` - Diff view implementation
  - `comments_panel.lua` - Comments list implementation
  - `navigation.lua` - Navigation and highlighting logic

- **`lua/mrreviewer/ui/diff/` (existing):** May be refactored or deprecated
  - Current diff view code may be partially reused or completely replaced

- **`lua/mrreviewer/ui/comments/` (existing):** Will be extended
  - Comment formatting functions will be reused
  - New functions for minimal comment display format

- **`lua/mrreviewer/core/state.lua` (existing):** Will need to track:
  - Current selected file
  - Current selected comment
  - Window buffer IDs for the three panes
  - Highlight state for bidirectional navigation

### Dependencies

- Leverage existing `glab` integration to fetch MR data
- Reuse existing comment fetching and parsing logic
- Utilize Neovim's built-in diff mode or implement custom side-by-side diff rendering
- May need to integrate with or study diffview.nvim's approach (license permitting)

### Data Flow

1. User invokes MR review command
2. Plugin fetches MR data (files, diffs, comments) using `glab`
3. Layout manager creates three-pane window structure
4. File panel populates with changed files + comment counts
5. Diff panel renders side-by-side diff for selected file
6. Comments panel displays comments grouped by file
7. User navigation triggers state updates and cross-panel highlighting

### Integration Points

- **Commands API (`lua/mrreviewer/api/commands.lua`):** Update existing review commands to launch new diffview interface
- **State Management (`lua/mrreviewer/core/state.lua`):** Track diffview-specific state (selected file, selected comment, panel buffers)
- **Comment System (`lua/mrreviewer/ui/comments/`):** Extend to support minimal display format and grouping by file

## Success Metrics

1. **User Efficiency:** Users can review an MR without switching between multiple commands or views (measured by user feedback).

2. **Navigation Speed:** Users can jump from a comment to its code location in under 2 seconds (includes highlighting animation).

3. **Visual Clarity:** Comment indicators in the file tree accurately reflect comment counts (100% accuracy).

4. **Bidirectional Navigation:** When navigating in diff view, corresponding comments are highlighted within 100ms.

5. **Stability:** The new interface handles MRs with 50+ files and 100+ comments without crashing or significant lag (aim for <3 second initial load time).

6. **Adoption:** The new interface becomes the default and preferred way to review MRs (no user requests to revert to old view).

## Design Decisions (Previously Open Questions - Now Resolved)

All design decisions have been finalized based on user feedback:

1. **Highlight Duration:** ✓ Configurable by users via `diffview.highlight_duration` config option. Supports numeric values in milliseconds or `nil`/`0` for permanent highlighting.

2. **Comment Count Scope:** ✓ Display format is `💬 <resolved>/<total>` (e.g., "💬 3/5" = 3 resolved out of 5 total comments).

3. **Empty State Handling:** ✓ Leave the comments pane blank when there are no comments (no message displayed).

4. **Default Pane Focus:** ✓ File tree has focus by default. This is configurable via `diffview.default_focus` option.

5. **Diff Mode Preferences:** ✓ Study and replicate diffview.nvim's diff rendering approach for consistency and quality.

6. **Comment Threading:** ✓ Display reply count in the comments panel (e.g., "+3 replies") but not in the file tree indicator. Full threading display is deferred to future enhancement.

7. **Keyboard Shortcut Conflicts:** ✓ New diffview keybindings take precedence over any existing conflicting keybindings.

8. **Error Handling:** ✓ Display error notifications using `vim.notify` and log to the logger module. Interface degrades gracefully rather than crashing.

9. **File Tree Ordering:** ✓ Use natural file system ordering (matching how neotree and diffview.nvim order files).

10. **Persistence:** ✓ Not implemented in initial version. May be added as a future enhancement.

---

**Document Version:** 1.1
**Created:** 2025-10-17
**Last Updated:** 2025-10-17
**Status:** Finalized - Ready for Implementation

**Summary of Requirements:**
- 41 functional requirements covering layout, navigation, comments, and error handling
- 3 configuration options for customization
- 9 non-goals clearly defined for scope management
- All design decisions resolved and documented

**Next Steps:**
1. Create technical implementation plan breaking down work into phases
2. Design detailed component architecture for each module
3. Set up development branch for diffview feature
4. Begin implementation starting with layout management
5. Implement file panel with comment indicators
6. Implement diff rendering using diffview.nvim approach
7. Implement comments panel with filtering
8. Implement bidirectional navigation
9. Add configuration options and testing
