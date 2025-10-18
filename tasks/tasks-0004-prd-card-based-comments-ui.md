## Relevant Files

- `lua/mrreviewer/ui/diffview/comments_panel.lua` - Primary integration point for card-based rendering and navigation
- `lua/mrreviewer/ui/comments/formatting.lua` - Comment formatting utilities, will need new card formatting functions
- `lua/mrreviewer/ui/highlights.lua` - Highlight groups, will need new groups for cards and selection states
- `lua/mrreviewer/core/state.lua` - State management for tracking selected card and collapsed sections
- `lua/mrreviewer/ui/comments/card_renderer.lua` - **[CREATED]** Card rendering module with complete implementation
- `lua/mrreviewer/ui/diffview/comments_panel.lua` - **[MODIFIED]** Updated render() function to use card-based rendering
- `lua/mrreviewer/ui/comments/card_navigator.lua` - New module for card-level navigation logic

### Notes

- The existing `comments_panel.lua` uses a line-based rendering approach with comment_map storing line->comment relationships
- Current navigation uses standard vim j/k movement
- Comments are already grouped by file using `group_by_file()` function
- Comment data structure includes `discussion_id` for threading, `resolved` for status, and position data for line ranges
- Highlight groups already exist for resolved/unresolved comments but will need card-specific additions

## Tasks

- [x] 1.0 Create card data structure and rendering module
  - [x] 1.1 Create `lua/mrreviewer/ui/comments/card_renderer.lua` module with basic structure and documentation
  - [x] 1.2 Define card data structure: `{id, comments, file_path, line_range, is_thread, resolved}`
  - [x] 1.3 Implement `group_comments_into_cards()` function to convert comment list into card list by grouping by `discussion_id`
  - [x] 1.4 Implement `extract_line_range()` helper to get line range from comment position data (new_line/old_line)
  - [x] 1.5 Implement `format_card_header()` to generate first line of card with line range and username (e.g., "L10-100 @username")
  - [x] 1.6 Implement `format_thread_replies()` to generate indented reply lines (e.g., "  - @username2")
  - [x] 1.7 Implement `render_card_with_borders()` to wrap card content in box-drawing characters (┌─┐ │ └─┘)
  - [x] 1.8 Add unit helper `get_card_height()` to calculate number of lines a card occupies in buffer

- [ ] 2.0 Implement card-based buffer rendering with visual card boundaries
  - [x] 2.1 Update `comments_panel.lua` `render()` function to use card-based rendering instead of line-based
  - [x] 2.2 Build card list from grouped comments using `card_renderer.group_comments_into_cards()`
  - [x] 2.3 Create new `card_map` structure mapping line ranges to card objects (replaces single-line comment_map)
  - [x] 2.4 Render file headers with comment count (e.g., "📁 src/main.lua (3 comments)")
  - [x] 2.5 Iterate through cards and render each with `card_renderer.render_card_with_borders()`
  - [x] 2.6 Store `card_map` in buffer variable `mrreviewer_card_map` for navigation lookup
  - [x] 2.7 Update `apply_highlighting()` to handle card-based structure (highlight entire cards, not individual lines)
  - [x] 2.8 Add special handling for cards with resolved status (dim entire card using dedicated highlight group)

- [ ] 3.0 Implement card-level navigation system (Tab/Shift+Tab, ]f/[f)
  - [ ] 3.1 Create `lua/mrreviewer/ui/comments/card_navigator.lua` module for navigation logic
  - [ ] 3.2 Implement `find_card_at_line()` to determine which card the cursor is currently in based on card_map
  - [ ] 3.3 Implement `move_to_next_card()` to find next card and move cursor to its first line
  - [ ] 3.4 Implement `move_to_prev_card()` to find previous card and move cursor to its first line
  - [ ] 3.5 Implement `find_next_file_section()` to locate the next file header in the buffer
  - [ ] 3.6 Implement `find_prev_file_section()` to locate the previous file header in the buffer
  - [ ] 3.7 Update `setup_keymaps()` in `comments_panel.lua` to add Tab keymap calling `move_to_next_card()`
  - [ ] 3.8 Update `setup_keymaps()` to add Shift+Tab (mapped as `<S-Tab>`) calling `move_to_prev_card()`
  - [ ] 3.9 Update `setup_keymaps()` to add `]f` keymap calling navigation to next file's first card
  - [ ] 3.10 Update `setup_keymaps()` to add `[f` keymap calling navigation to previous file's first card
  - [ ] 3.11 Update `get_comment_at_cursor()` to work with card_map (return the primary comment from the card)
  - [ ] 3.12 Ensure Enter key still works to jump to comment location in diff (should use first comment in card's thread)

- [ ] 4.0 Add collapsible file sections and orphaned comments handling
  - [ ] 4.1 Add `collapsed_sections` table to diffview state in `state.lua` to track which file sections are collapsed
  - [ ] 4.2 Implement `is_section_collapsed()` helper in `comments_panel.lua` to check collapse state
  - [ ] 4.3 Update file header rendering to show collapse indicator (e.g., "▼" expanded, "▶" collapsed)
  - [ ] 4.4 Implement `toggle_file_section()` function to collapse/expand file section at cursor
  - [ ] 4.5 When section is collapsed, render only the header with comment count, skip rendering cards
  - [ ] 4.6 Add keymap (e.g., `za` or `<Space>`) to toggle file section collapse at cursor position
  - [ ] 4.7 Implement `identify_orphaned_comments()` to find comments without `discussion_id` or with orphaned discussion_id
  - [ ] 4.8 Create special "Orphaned Comments" section header rendered at the end of the buffer
  - [ ] 4.9 Render orphaned comment cards under the "Orphaned Comments" section using same card rendering logic
  - [ ] 4.10 Handle missing author information: replace nil/empty author with "unknown" in `format_card_header()`
  - [ ] 4.11 Ensure file sections are expanded by default (collapsed_sections table starts empty)

- [ ] 5.0 Implement card selection persistence and visual feedback
  - [ ] 5.1 Add `selected_card_id` field to diffview state in `state.lua` to track currently selected card
  - [ ] 5.2 Update `card_navigator.move_to_next_card()` to update `selected_card_id` in state when navigating
  - [ ] 5.3 Update `card_navigator.move_to_prev_card()` to update `selected_card_id` in state when navigating
  - [ ] 5.4 Add new highlight groups to `highlights.lua`: `MRReviewerCardSelected`, `MRReviewerCardResolved`, `MRReviewerCardBorder`
  - [ ] 5.5 Implement `highlight_selected_card()` function to apply selection highlight to entire card (all lines)
  - [ ] 5.6 Call `highlight_selected_card()` after rendering buffer and after navigation to update visual feedback
  - [ ] 5.7 When switching from diff to comments buffer, read `selected_card_id` from state and move cursor to that card
  - [ ] 5.8 When switching from comments to diff buffer, ensure `selected_card_id` is saved in state
  - [ ] 5.9 Implement dimming for resolved cards: apply `MRReviewerCardResolved` highlight group to all lines of resolved cards
  - [ ] 5.10 Test card selection persistence by navigating between diff and comments buffers multiple times
