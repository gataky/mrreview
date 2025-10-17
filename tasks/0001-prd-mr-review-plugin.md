# Product Requirements Document: Neovim GitLab MR Review Plugin

## 1. Introduction/Overview

This document outlines the requirements for a Neovim plugin that enables developers to review GitLab Merge Requests (MRs) directly within their editor environment. The plugin addresses the need for seamless integration between code review workflows and development environments, eliminating context switching between the browser and editor.

The plugin will leverage the `glab` CLI tool to fetch MR data and comments from GitLab, and display them alongside a side-by-side diff view similar to existing tools like `diffview.nvim`. The goal is to provide developers with a complete MR review experience without leaving Neovim.

## 2. Goals

1. Enable developers to review entire GitLab MRs within Neovim without switching to a web browser
2. Display MR comments inline with code changes, maintaining full context
3. Provide an intuitive side-by-side diff view showing target branch vs. current branch changes
4. Integrate seamlessly with the `glab` CLI tool for GitLab API interactions
5. Create a fast, responsive review experience that enhances (not hinders) developer workflow

## 3. User Stories

1. **As a developer**, I want to review MRs without leaving Neovim, so that I can maintain my development flow and reduce context switching.

2. **As a code reviewer**, I want to see MR comments displayed directly on the relevant code lines, so that I understand the discussion context without searching through separate comment threads.

3. **As a team member**, I want to quickly browse open MRs and select one to review, so that I can easily find MRs that need my attention.

4. **As a developer working on a feature branch**, I want the plugin to automatically detect my current branch's MR, so that I can quickly review changes before requesting formal review.

5. **As a reviewer**, I want to see a clear side-by-side diff of changes between the target and source branches, so that I can easily understand what code has been added, removed, or modified.

## 4. Functional Requirements

### 4.1 MR Discovery and Selection

1. The plugin must provide a command to browse a list of open MRs in the current GitLab project.
2. The plugin must automatically detect if the current branch has an associated MR and offer to open it for review.
3. The plugin must display basic MR information in the selection interface (MR number, title, author, status).
4. The plugin must allow users to select an MR from the list to begin reviewing.

### 4.2 Diff View Display

5. The plugin must display a side-by-side diff view comparing the target branch and source branch versions of changed files.
6. The diff view must clearly indicate additions, deletions, and modifications using appropriate highlighting.
7. The plugin must support navigation between different files that have changes in the MR.
8. The diff view should function similarly to existing diff tools like `diffview.nvim` for consistent user experience.

### 4.3 Comment Integration

9. The plugin must fetch all comments for a selected MR using the `glab` CLI tool (via `glab mr view --comments --output json`).
10. The plugin must parse the JSON response from `glab` to extract comment data, including position information.
11. The plugin must display comments at their correct line positions based on the `position` field in the comment data.
12. The plugin must handle both old and new line positions for comments (`old_line`, `new_line`).
13. The plugin must handle comment line ranges (from `line_range.start` to `line_range.end`).
14. The plugin must support multiple display modes for comments:
    - Display comments in a separate split buffer adjacent to the diff
    - Display comments as virtual text inline with the code
15. The plugin must show comment metadata including author, timestamp, and body text.
16. The plugin must indicate resolved vs. unresolved comments visually.

### 4.4 GitLab Integration

17. The plugin must use the `glab` CLI tool for all GitLab API interactions.
18. The plugin must handle cases where `glab` is not installed or not authenticated, providing clear error messages.
19. The plugin must correctly identify the GitLab project based on the current working directory's git remote configuration.

### 4.5 Technical Implementation

20. The plugin must be implemented in Lua 5.1 (compatible with Neovim's Lua runtime).
21. The plugin must not block Neovim's UI during API calls or data fetching operations.
22. The plugin must handle error cases gracefully (network errors, missing MRs, invalid data).

## 5. Non-Goals (Out of Scope)

The following features are explicitly **not** included in this version:

1. **Creating new MRs** - Users must use `glab` CLI or GitLab web UI to create MRs
2. **Approving or merging MRs** - Approval and merge actions are out of scope
3. **Managing MR metadata** - Editing labels, assignees, milestones, or other MR properties is not supported
4. **Adding new comments or replies** - This version is read-only for comments
5. **Resolving/unresolving comment threads** - Comment thread management is not included
6. **Supporting platforms other than GitLab** - GitHub, Bitbucket, and other platforms are not supported
7. **Inline editing of code** - The diff view is for review only, not for making changes

## 6. Design Considerations

### 6.1 User Interface

- The plugin should follow Neovim UI conventions and integrate well with existing window management
- Comment display should be configurable to accommodate different user preferences
- Consider implementing both display modes (split buffer and virtual text) with user configuration to choose preferred mode
- Use appropriate highlight groups that respect user colorschemes

### 6.2 Layout Suggestions

**Option A: Separate Split Buffer**
```
+------------------+------------------+------------------+
|   Target Branch  |   Source Branch  |    Comments      |
|   (old file)     |   (new file)     |    Buffer        |
+------------------+------------------+------------------+
```

**Option B: Virtual Text Inline**
```
+------------------+------------------+
|   Target Branch  |   Source Branch  |
|   (old file)     |   (new file)     |
|                  | ~ Comment here   |
+------------------+------------------+
```

### 6.3 Commands

Suggested command names:
- `:MRReview [number]` - Open specific MR for review
- `:MRList` - Show list of open MRs
- `:MRCurrent` - Open MR for current branch

## 7. Technical Considerations

### 7.1 Dependencies

- Neovim (with Lua 5.1 support)
- `glab` CLI tool installed and authenticated
- Git repository with GitLab remote

### 7.2 Integration Points

- Must integrate with Neovim's buffer and window management APIs
- Should leverage existing diff rendering capabilities where possible
- Must parse and handle GitLab's comment position data structure correctly

### 7.3 Data Handling

- Comment position data includes `base_sha`, `head_sha`, `start_sha` for proper diff context
- Line codes (e.g., `93f54d427c28d2fee5772fddfc8d435240a80c0a_380_401`) may need parsing
- Handle both single-line comments and multi-line comment ranges

### 7.4 Performance

- Fetching MR data and comments should be asynchronous to avoid blocking
- Consider caching comment data to avoid repeated API calls
- Large diffs should be handled efficiently

## 8. Success Metrics

The feature will be considered successful when:

1. **Complete Browser-Free Review**: A user can review an entire MR including all changed files and comments without opening a web browser
2. **Contextual Comment Display**: All MR comments are displayed inline with their associated code changes, maintaining full context
3. **Fast and Responsive**: The plugin loads MR data and displays diffs without noticeable lag or UI blocking
4. **Reliable Comment Positioning**: Comments appear at the correct line positions based on GitLab's position data

## 9. Open Questions

1. **Comment Display Preference**: Which display mode should be the default - separate split buffer or virtual text inline? (Both should be implemented as configurable options)

2. **Navigation UX**: What's the best way to navigate between commented lines? Should there be a `:MRNextComment` command?

3. **Thread Visualization**: How should comment threads (parent comment + replies) be displayed? Should replies be nested or shown sequentially?

4. **Diff Context**: How much context (surrounding unchanged lines) should be shown in the diff view?

5. **Performance Limits**: What's an acceptable maximum MR size (number of files, comments) before performance degradation?

6. **Error Recovery**: How should the plugin handle MRs with outdated position data (e.g., when base_sha no longer matches)?

7. **Multi-file Comments**: Some comments may span multiple files or be general MR comments not tied to specific lines - how should these be displayed?
