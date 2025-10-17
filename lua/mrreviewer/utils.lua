-- lua/mrreviewer/utils.lua
-- Common utility functions

local M = {}

--- Trim whitespace from start and end of string
--- @param str string
--- @return string
function M.trim(str)
  if not str then
    return ''
  end
  return str:match('^%s*(.-)%s*$')
end

--- Check if a string is empty or nil
--- @param str string|nil
--- @return boolean
function M.is_empty(str)
  return not str or str == '' or str:match('^%s*$') ~= nil
end

--- Check if a file exists
--- @param path string
--- @return boolean
function M.file_exists(path)
  local stat = vim.loop.fs_stat(path)
  return stat ~= nil and stat.type == 'file'
end

--- Check if a directory exists
--- @param path string
--- @return boolean
function M.dir_exists(path)
  local stat = vim.loop.fs_stat(path)
  return stat ~= nil and stat.type == 'directory'
end

--- Validate a file path
--- @param path string
--- @return boolean, string|nil Returns true if valid, or false and error message
function M.validate_path(path)
  if M.is_empty(path) then
    return false, 'Path is empty'
  end

  -- Check for invalid characters (basic validation)
  if path:match('[<>"|?*]') then
    return false, 'Path contains invalid characters'
  end

  return true, nil
end

--- Deep merge two tables
--- @param target table
--- @param source table
--- @return table
function M.merge_tables(target, source)
  for key, value in pairs(source) do
    if type(value) == 'table' and type(target[key]) == 'table' then
      target[key] = M.merge_tables(target[key], value)
    else
      target[key] = value
    end
  end
  return target
end

--- Check if a table is empty
--- @param tbl table
--- @return boolean
function M.is_table_empty(tbl)
  return next(tbl) == nil
end

--- Get table size (works for both arrays and dictionaries)
--- @param tbl table
--- @return number
function M.table_size(tbl)
  local count = 0
  for _ in pairs(tbl) do
    count = count + 1
  end
  return count
end

--- Safe JSON decode with error handling
--- @param json_str string
--- @return table|nil, string|nil Returns decoded table or nil and error message
function M.json_decode(json_str)
  if M.is_empty(json_str) then
    return nil, 'Empty JSON string'
  end

  local ok, result = pcall(vim.fn.json_decode, json_str)
  if not ok then
    return nil, 'Failed to decode JSON: ' .. tostring(result)
  end

  return result, nil
end

--- Notify user with a message
--- @param msg string Message to display
--- @param level string|nil Log level: 'error', 'warn', 'info', 'debug' (default: 'info')
function M.notify(msg, level)
  local config = require('mrreviewer.config')
  if not config.get_value('notifications.enabled') then
    return
  end

  local log_levels = {
    error = vim.log.levels.ERROR,
    warn = vim.log.levels.WARN,
    info = vim.log.levels.INFO,
    debug = vim.log.levels.DEBUG,
  }

  level = level or 'info'
  local vim_level = log_levels[level] or vim.log.levels.INFO

  vim.notify('[MRReviewer] ' .. msg, vim_level)
end

--- Split string by delimiter
--- @param str string
--- @param delimiter string
--- @return table
function M.split(str, delimiter)
  local result = {}
  local pattern = string.format('([^%s]+)', delimiter)

  for match in str:gmatch(pattern) do
    table.insert(result, match)
  end

  return result
end

--- Get current git branch
--- @return string|nil Branch name or nil if not in a git repo
function M.get_current_branch()
  local handle = io.popen('git rev-parse --abbrev-ref HEAD 2>/dev/null')
  if not handle then
    return nil
  end

  local branch = handle:read('*a')
  handle:close()

  if not branch or branch == '' then
    return nil
  end

  return M.trim(branch)
end

--- Check if currently in a git repository
--- @return boolean
function M.is_git_repo()
  local handle = io.popen('git rev-parse --is-inside-work-tree 2>/dev/null')
  if not handle then
    return false
  end

  local result = handle:read('*a')
  handle:close()

  return M.trim(result) == 'true'
end

--- Escape special characters for use in Lua patterns
--- @param str string
--- @return string
function M.escape_pattern(str)
  local special_chars = '([%.%+%-%*%?%[%]%^%$%(%)%%])'
  return str:gsub(special_chars, '%%%1')
end

return M
