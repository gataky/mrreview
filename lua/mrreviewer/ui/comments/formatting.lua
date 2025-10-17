-- lua/mrreviewer/comments/formatting.lua
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

return M
