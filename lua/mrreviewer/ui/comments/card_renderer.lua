-- lua/mrreviewer/ui/comments/card_renderer.lua
-- Card-based rendering logic for comments panel
--
-- This module transforms comments into visual card representations for display
-- in the comments panel. Each card represents either a single comment or a
-- comment thread (multiple related comments grouped by discussion_id).
--
-- Card structure:
--   ┌─────────────────────┐
--   │ L10-100 @username   │  <- Single comment
--   └─────────────────────┘
--
--   ┌─────────────────────┐
--   │ L10-100 @username   │  <- Thread with replies
--   │   - @username2      │
--   │   - @username3      │
--   └─────────────────────┘

local M = {}
local logger = require('mrreviewer.core.logger')

--- Card data structure
--- Represents a single comment or a threaded conversation as a visual card unit
--- @class Card
--- @field id string Unique identifier for the card (typically the discussion_id or comment id)
--- @field comments table List of comment objects in this card (single comment or thread)
--- @field file_path string|nil File path this card belongs to (from comment.position.new_path or old_path)
--- @field line_range string Display string for line range (e.g., "L10-100" or "L10")
--- @field is_thread boolean Whether this card contains multiple comments (a thread)
--- @field resolved boolean Whether all comments in this card are resolved

--- Create a new card object
--- @param id string Card identifier
--- @param comments table List of comment objects
--- @param file_path string|nil File path
--- @param line_range string Line range display string
--- @param is_thread boolean Whether this is a thread
--- @param resolved boolean Whether all comments are resolved
--- @return Card Card object
function M.create_card(id, comments, file_path, line_range, is_thread, resolved)
  return {
    id = id,
    comments = comments,
    file_path = file_path,
    line_range = line_range,
    is_thread = is_thread,
    resolved = resolved,
  }
end

--- Group comments into cards based on discussion_id
--- Single comments become single-comment cards, threaded comments are grouped
--- @param comments table List of comment objects
--- @return table List of Card objects
function M.group_comments_into_cards(comments)
  logger.debug('card_renderer', 'Grouping comments into cards', {
    comment_count = #comments,
  })

  if not comments or #comments == 0 then
    return {}
  end

  -- Group comments by discussion_id
  local discussion_groups = {}
  local orphaned_comments = {}

  for _, comment in ipairs(comments) do
    if comment.discussion_id and comment.discussion_id ~= '' then
      -- Add to discussion group
      if not discussion_groups[comment.discussion_id] then
        discussion_groups[comment.discussion_id] = {}
      end
      table.insert(discussion_groups[comment.discussion_id], comment)
    else
      -- Comments without discussion_id are orphaned (handled separately)
      table.insert(orphaned_comments, comment)
    end
  end

  -- Convert groups into cards
  local cards = {}

  -- Process discussion groups (threads)
  for discussion_id, group_comments in pairs(discussion_groups) do
    -- Sort comments by created_at timestamp to maintain chronological order
    table.sort(group_comments, function(a, b)
      if a.created_at and b.created_at then
        return a.created_at < b.created_at
      end
      return false
    end)

    -- Get file path from first comment
    local file_path = nil
    if group_comments[1].position then
      file_path = group_comments[1].position.new_path or group_comments[1].position.old_path
    end

    -- Extract line range from first comment
    local line_range = M.extract_line_range(group_comments[1])

    -- Determine if all comments in this card are resolved
    local all_resolved = true
    for _, comment in ipairs(group_comments) do
      if not comment.resolved then
        all_resolved = false
        break
      end
    end

    -- Create card
    local is_thread = #group_comments > 1
    local card = M.create_card(
      discussion_id,
      group_comments,
      file_path,
      line_range,
      is_thread,
      all_resolved
    )

    table.insert(cards, card)
  end

  -- Process orphaned comments (each becomes a single-comment card)
  for _, comment in ipairs(orphaned_comments) do
    -- Get file path
    local file_path = nil
    if comment.position then
      file_path = comment.position.new_path or comment.position.old_path
    end

    -- Extract line range
    local line_range = M.extract_line_range(comment)

    -- Create single-comment card using comment id as card id
    local card = M.create_card(
      comment.id or tostring(comment),
      { comment },
      file_path,
      line_range,
      false, -- Not a thread
      comment.resolved or false
    )

    table.insert(cards, card)
  end

  logger.debug('card_renderer', 'Grouped comments into cards', {
    card_count = #cards,
    discussion_groups = vim.tbl_count(discussion_groups),
    orphaned_count = #orphaned_comments,
  })

  return cards
end

--- Extract line range string from comment position data
--- @param comment table Comment object with position data
--- @return string Line range string (e.g., "L10-100" or "L10")
function M.extract_line_range(comment)
  if not comment or not comment.position then
    return "L?"
  end

  local position = comment.position

  -- Prefer new_line over old_line (for source/head branch)
  local start_line = position.new_line or position.old_line
  local end_line = position.new_line_end or position.old_line_end

  if not start_line then
    return "L?"
  end

  -- If there's no end line or it's the same as start line, show single line
  if not end_line or end_line == start_line then
    return "L" .. start_line
  end

  -- Show range for multi-line comments
  return "L" .. start_line .. "-" .. end_line
end

--- Format the header line of a card with line range and username
--- @param card table Card object
--- @return string Formatted header line (e.g., "L10-100 @username")
function M.format_card_header(card)
  if not card or not card.comments or #card.comments == 0 then
    return ""
  end

  -- Get the first comment (the root of the thread or the single comment)
  local first_comment = card.comments[1]

  -- Extract username, handle missing author info per PRD requirement
  local username = "unknown"
  if first_comment.author then
    username = first_comment.author.username or first_comment.author.name or "unknown"
  end

  -- Format: "L10-100 @username"
  return card.line_range .. " @" .. username
end

--- Format thread reply lines with indentation
--- Returns empty table for single-comment cards
--- @param card table Card object
--- @return table List of formatted reply lines (e.g., {"  - @username2", "  - @username3"})
function M.format_thread_replies(card)
  if not card or not card.is_thread or not card.comments or #card.comments <= 1 then
    return {}
  end

  local reply_lines = {}

  -- Skip the first comment (already shown in header), format the rest as replies
  for i = 2, #card.comments do
    local comment = card.comments[i]

    -- Extract username, handle missing author info per PRD requirement
    local username = "unknown"
    if comment.author then
      username = comment.author.username or comment.author.name or "unknown"
    end

    -- Format: "  - @username" (2 spaces, dash, space, @username)
    table.insert(reply_lines, "  - @" .. username)
  end

  return reply_lines
end

--- Render a complete card with borders
--- @param card table Card object
--- @return table List of lines representing the full card with borders
function M.render_card_with_borders(card)
  if not card then
    return {}
  end

  local lines = {}

  -- Get card content (header and replies)
  local header = M.format_card_header(card)
  local replies = M.format_thread_replies(card)

  -- Calculate card width (find longest line, minimum 20 characters)
  local max_width = 20
  if #header > max_width then
    max_width = #header
  end
  for _, reply in ipairs(replies) do
    if #reply > max_width then
      max_width = #reply
    end
  end

  -- Add padding (2 spaces on each side for the border characters)
  local content_width = max_width

  -- Top border: ┌─────────┐
  table.insert(lines, "┌" .. string.rep("─", content_width + 2) .. "┐")

  -- Header line: │ L10-100 @username │
  table.insert(lines, "│ " .. header .. string.rep(" ", content_width - #header) .. " │")

  -- Reply lines: │   - @username2    │
  for _, reply in ipairs(replies) do
    table.insert(lines, "│ " .. reply .. string.rep(" ", content_width - #reply) .. " │")
  end

  -- Bottom border: └─────────┘
  table.insert(lines, "└" .. string.rep("─", content_width + 2) .. "┘")

  return lines
end

--- Calculate the height (number of lines) a card will occupy in the buffer
--- @param card table Card object
--- @return number Number of lines
function M.get_card_height(card)
  if not card then
    return 0
  end

  -- Card structure:
  -- 1 line: top border
  -- 1 line: header
  -- N lines: replies (0 for single comment, N-1 for thread with N comments)
  -- 1 line: bottom border

  local height = 3 -- top border + header + bottom border

  if card.is_thread and card.comments then
    -- Add reply lines (all comments except the first one)
    height = height + (#card.comments - 1)
  end

  return height
end

return M
