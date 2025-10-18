# PRD: Card-Based Comments UI

## Introduction/Overview

The current comments buffer displays comments as a simple line-by-line list grouped by filename. This PRD describes an enhancement to transform the comments display into a card-based UI, where each comment or comment thread is visually represented as a distinct card unit. This will improve visual hierarchy, make comment threads more apparent, and enable card-level navigation rather than line-by-line navigation.

**Problem:** The current line-based display makes it difficult to visually distinguish individual comments from comment threads, and navigation is limited to standard line-by-line vim movements which doesn't align well with the conceptual unit of a "comment" or "comment thread."

**Goal:** Create a card-based UI that treats each comment or comment thread as a visual and navigational unit, improving clarity and user experience when reviewing comments.

## Goals

1. Transform the comments buffer display from line-based to card-based visualization
2. Implement card-level navigation (Tab/Shift+Tab between cards)
3. Clearly distinguish single comments from comment threads using visual hierarchy
4. Maintain existing filename grouping while adding collapsible file sections
5. Support resolved/unresolved visual indicators on cards
6. Enable file-level navigation shortcuts (`]f` / `[f`)

## User Stories

1. As a code reviewer, I want to see each comment as a visually distinct card so that I can quickly scan and identify individual comments vs threads.

2. As a developer, I want to navigate between comment cards using Tab/Shift+Tab so that I can quickly move through comments without line-by-line navigation.

3. As a reviewer, I want comment threads to show all participating usernames in a hierarchical format so that I can see the conversation structure at a glance.

4. As a user, I want to press Enter on a selected card to jump to that comment's location in the diff so that I can see the code context.

5. As a developer, I want to collapse/expand filename sections so that I can focus on comments for specific files.

6. As a reviewer, I want visual indicators for comment status (resolved/unresolved) so that I can quickly identify which comments need attention.

## Functional Requirements

### Card Display

1. The system must render each comment or comment thread as a visually distinct card with borders.

2. Single comment cards must display:
   - Line range (e.g., "L10-100")
   - Username (e.g., "@username")
   - Format: `| L10-100 @username |`

3. Comment thread cards must display:
   - First comment with line range and username on the first line
   - Subsequent comments indented with a dash prefix (e.g., "  - @username2")
   - All usernames in the thread must be visible
   - Format:
     ```
     | L10-100 @username |
     |   - @username2    |
     |   - @username3    |
     ```

4. Cards must display metadata only (line ranges, usernames), not full comment text.

5. Cards must include visual indicators for resolved/unresolved status. Resolved comment cards must be dimmed to visually distinguish them from unresolved comments.

### Navigation

6. The system must support Tab key to navigate to the next comment card.

7. The system must support Shift+Tab to navigate to the previous comment card.

8. When a card is selected (focused), it must be visually highlighted.

9. The system must support Enter key on a selected card to jump to that comment's location in the diff view.

10. The system must support `]f` to jump to the next file's first comment card.

11. The system must support `[f` to jump to the previous file's first comment card.

12. Navigation must treat each card as a single unit (not line-by-line within the card).

13. The currently selected card must persist when switching between diff and comments buffer views.

### File Grouping

14. The system must maintain filename headers grouping comments by file.

15. The system must support collapsible/expandable filename sections.

16. Collapsed filename sections must show a count of comments within that file.

17. Filename sections must be expanded by default.

18. The system must preserve the current file tree order when displaying grouped comments.

### Special Cases

19. Comments without a `discussion_id` (orphaned comments) must be grouped together in a special "Orphaned Comments" section, similar to how other comments are grouped by filename.

20. Comments without author information must display the username as "unknown".

### Data Structure

21. The system must use existing comment data fields:
    - `id`, `discussion_id` (for threading)
    - `author.username` or `author.name`
    - `position.new_line` / `position.old_line` (for line ranges)
    - `resolved` (for status indicators)

22. The system must group comments by `discussion_id` to form threads.

23. The system must extract line ranges directly from the comment data provided by the MR (merge request).

## Non-Goals (Out of Scope)

1. **Comment Actions on Cards:** No inline reply, resolve, or copy link functionality on cards at this time.

2. **Expandable Comment Threads:** Comment threads will not be collapsible within a card (all usernames always visible).

3. **Full Comment Text Display:** Cards will not show the actual comment body text, only metadata.

4. **Additional Keyboard Shortcuts:** Beyond Tab/Shift+Tab, Enter, `]f`/`[f`, no new shortcuts will be added.

5. **Changing Comment Data Structure:** No modifications to how comments are fetched or stored, only how they are displayed.

## Design Considerations

### Visual Design

- **Card Borders:** Use ASCII box-drawing characters or simple dashes/pipes to create card boundaries
- **Thread Indentation:** Use 2-4 spaces with dash prefix for thread replies
- **Status Indicators:** Resolved cards should be dimmed using a dedicated highlight group (e.g., reduced opacity or gray color scheme)
- **Selection Highlighting:** Use a distinct highlight group for the currently selected card
- **Filename Headers:** Consider making them bold or using a different highlight group

### UI Components

- Build on existing `comments_panel.lua` implementation
- Maintain compatibility with existing display modes (split buffer is primary target)
- Leverage existing syntax highlighting system in `init.lua`

### Example Card Layout

```
src/utils/parser.lua (3 comments) [collapsible]
  ┌─────────────────────┐
  │ L45-50 @alice       │
  └─────────────────────┘

  ┌─────────────────────┐
  │ L120-125 @bob       │
  │   - @alice          │
  │   - @charlie        │
  └─────────────────────┘

src/main.lua (1 comment)
  ┌─────────────────────┐
  │ L10 @dave           │
  └─────────────────────┘
```

## Technical Considerations

1. **Integration Point:** Modify `lua/mrreviewer/ui/diffview/comments_panel.lua` as the primary integration point.

2. **Thread Grouping:** Use existing `discussion_id` field to group comments into threads.

3. **Line Range Extraction:** Line ranges come directly from the comment data provided by the MR API.

4. **Keymap Registration:** Add new keymaps (Tab, Shift+Tab, `]f`, `[f`) while preserving existing ones (Enter, KK, r, j/k).

5. **Buffer Management:** Cards will need custom rendering logic; consider using extmarks or virtual text for card boundaries if needed.

6. **State Management:** Track currently selected card index for navigation purposes. Card selection must persist when switching between diff and comments buffer.

7. **Performance:** With card rendering, ensure performance remains good with large numbers of comments (100+).

## Success Metrics

1. **User Adoption:** Existing users prefer the card-based UI over the line-based display in qualitative feedback.

2. **Navigation Efficiency:** Users can navigate to specific comments 20-30% faster using card-level navigation vs line-by-line.

3. **Visual Clarity:** Users report improved ability to distinguish single comments from threads in user testing.

4. **No Regressions:** All existing comment viewing and navigation functionality continues to work as expected.

5. **Performance:** Comments buffer renders cards within 100ms for up to 100 comments.

## Resolved Design Decisions

All open questions have been addressed:

1. **Line Range Determination:** Line ranges are extracted directly from the comment data provided by the MR (merge request).

2. **Card Selection Persistence:** The currently selected card must persist when switching between diff and comments buffer views.

3. **Resolved Comments Display:** Resolved comment cards should be dimmed to visually distinguish them from unresolved comments.

4. **File Section Collapse Default:** Filename sections should be expanded by default.

5. **Edge Cases:**
   - Comments without a `discussion_id` (orphaned comments) are grouped in a special "Orphaned Comments" section.
   - Comments without author information display the username as "unknown".

6. **Compatibility:** Card-based UI is the default display mode.
