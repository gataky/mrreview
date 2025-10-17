-- lua/mrreviewer/position.lua
-- Position mapping utilities for GitLab diff comments

local M = {}

--- Map comment position to buffer line number
--- @param comment table Comment with position data
--- @param buffer number Buffer number
--- @return number|nil Line number in buffer (1-indexed) or nil
function M.map_comment_to_line(comment, buffer)
  if not comment or type(comment) ~= 'table' then
    return nil
  end

  if not comment.position then
    return nil
  end

  -- Use new_line for the source/head branch (the buffer we're displaying)
  local line = comment.position.new_line

  if not line or line <= 0 then
    return nil
  end

  -- Ensure line is within buffer bounds
  local line_count = vim.api.nvim_buf_line_count(buffer)
  if line > line_count then
    return nil
  end

  return line
end

--- Check if a line number is valid for a buffer
--- @param line number Line number (1-indexed)
--- @param buffer number Buffer number
--- @return boolean True if line is valid
function M.is_valid_line(line, buffer)
  if not line or type(line) ~= 'number' or line <= 0 then
    return false
  end

  local line_count = vim.api.nvim_buf_line_count(buffer)
  return line <= line_count
end

--- Get line number from position data
--- Extracts the new_line from a GitLab position object
--- @param position table Position data from GitLab comment
--- @return number|nil Line number or nil
function M.get_line_from_position(position)
  if not position or type(position) ~= 'table' then
    return nil
  end

  return position.new_line
end

return M
