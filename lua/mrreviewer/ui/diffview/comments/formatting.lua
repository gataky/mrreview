-- lua/mrreviewer/ui/diffview/comments/formatting.lua
-- Comment formatting utilities

local M = {}

--- Format comment for display
--- @param comment table Comment data
--- @return table Lines for display
function M.format_comment(comment)
  local lines = {}
  local resolved_marker = comment.resolved and '✓' or '•'
  local resolved_text = comment.resolved and '(resolved)' or '(unresolved)'

  -- Header line
  table.insert(lines, string.format(
    '%s %s %s',
    resolved_marker,
    comment.author.name or comment.author.username,
    resolved_text
  ))

  -- Timestamp
  if comment.created_at then
    local date = comment.created_at:match('(%d%d%d%d%-%d%d%-%d%d)')
    if date then
      table.insert(lines, string.format('  %s', date))
    end
  end

  -- Empty line for spacing
  table.insert(lines, '')

  -- Comment body (indented)
  for line in comment.body:gmatch('[^\r\n]+') do
    table.insert(lines, '  ' .. line)
  end

  -- Separator
  table.insert(lines, '')
  table.insert(lines, string.rep('─', 40))
  table.insert(lines, '')

  return lines
end

--- Format comment in minimal single-line format for comments panel
--- Format: "Line <line>  @<author>  <first_line_of_body>  [+N replies]"
--- @param comment table Comment data
--- @return string Single-line formatted comment
function M.format_minimal(comment)
  local line_number = comment.position and (comment.position.new_line or comment.position.old_line) or '?'
  local author = comment.author and (comment.author.username or comment.author.name) or 'unknown'

  -- Get first line of body
  local first_line = comment.body and comment.body:match('[^\r\n]+') or ''
  -- Truncate if too long
  if #first_line > 60 then
    first_line = first_line:sub(1, 57) .. '...'
  end

  -- Count replies (notes in the comment)
  local reply_count = 0
  if comment.notes and type(comment.notes) == 'table' then
    reply_count = #comment.notes
  end

  -- Build the formatted line
  local parts = {
    'Line ' .. line_number,
    '@' .. author,
    first_line
  }

  -- Add reply count if there are replies
  if reply_count > 0 then
    table.insert(parts, '[+' .. reply_count .. ' replies]')
  end

  return '  ' .. table.concat(parts, '  ')
end

return M
