-- lua/mrreviewer/logger.lua
-- Logging system with file output and log rotation

local M = {}

-- Log levels
M.levels = {
  DEBUG = 1,
  INFO = 2,
  WARN = 3,
  ERROR = 4,
}

-- Default configuration
M.config = {
  enabled = true,
  level = M.levels.INFO,
  file_path = nil, -- Will be set to default on first use
  max_file_size = 10 * 1024 * 1024, -- 10MB
  max_backups = 3,
}

--- Get default log file path
--- @return string Log file path
local function get_default_log_path()
  local data_path = vim.fn.stdpath('data')
  return data_path .. '/mrreviewer.log'
end

--- Get current log file path
--- @return string Log file path
function M.get_log_path()
  if not M.config.file_path then
    M.config.file_path = get_default_log_path()
  end
  return M.config.file_path
end

--- Configure logger
--- @param opts table Configuration options
function M.setup(opts)
  opts = opts or {}

  if opts.enabled ~= nil then
    M.config.enabled = opts.enabled
  end

  if opts.level then
    if type(opts.level) == 'string' then
      M.config.level = M.levels[opts.level:upper()] or M.levels.INFO
    else
      M.config.level = opts.level
    end
  end

  if opts.file_path then
    M.config.file_path = opts.file_path
  end

  if opts.max_file_size then
    M.config.max_file_size = opts.max_file_size
  end

  if opts.max_backups then
    M.config.max_backups = opts.max_backups
  end
end

--- Get level name from level number
--- @param level number Log level number
--- @return string Level name
local function get_level_name(level)
  for name, num in pairs(M.levels) do
    if num == level then
      return name
    end
  end
  return 'UNKNOWN'
end

--- Format timestamp for log entry
--- @return string Formatted timestamp
local function format_timestamp()
  return os.date('%Y-%m-%d %H:%M:%S')
end

--- Rotate log files
--- Keep max_backups old log files
local function rotate_logs()
  local log_path = M.get_log_path()

  -- Remove oldest backup if we're at max_backups
  local oldest_backup = log_path .. '.' .. M.config.max_backups
  if vim.fn.filereadable(oldest_backup) == 1 then
    os.remove(oldest_backup)
  end

  -- Rotate existing backups
  for i = M.config.max_backups - 1, 1, -1 do
    local old_path = log_path .. '.' .. i
    local new_path = log_path .. '.' .. (i + 1)
    if vim.fn.filereadable(old_path) == 1 then
      os.rename(old_path, new_path)
    end
  end

  -- Rotate current log to .1
  if vim.fn.filereadable(log_path) == 1 then
    os.rename(log_path, log_path .. '.1')
  end
end

--- Check if log rotation is needed
--- @return boolean True if rotation needed
local function needs_rotation()
  local log_path = M.get_log_path()

  if vim.fn.filereadable(log_path) ~= 1 then
    return false
  end

  local size = vim.fn.getfsize(log_path)
  return size >= M.config.max_file_size
end

--- Write log entry to file
--- @param level number Log level
--- @param module string Module name
--- @param message string Log message
--- @param context table|nil Optional context data
local function write_log(level, module, message, context)
  -- Check if logging is enabled
  if not M.config.enabled then
    return
  end

  -- Check log level
  if level < M.config.level then
    return
  end

  -- Check if rotation is needed
  if needs_rotation() then
    rotate_logs()
  end

  local log_path = M.get_log_path()

  -- Ensure directory exists
  local dir = vim.fn.fnamemodify(log_path, ':h')
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, 'p')
  end

  -- Format log entry
  local timestamp = format_timestamp()
  local level_name = get_level_name(level)
  local log_entry = string.format('[%s] [%s] [%s] %s', timestamp, level_name, module, message)

  -- Add context if provided
  if context and next(context) then
    log_entry = log_entry .. '\n  Context: ' .. vim.inspect(context)
  end

  -- Write to file
  local file = io.open(log_path, 'a')
  if file then
    file:write(log_entry .. '\n')
    file:close()
  end
end

--- Log debug message
--- @param module string Module name
--- @param message string Log message
--- @param context table|nil Optional context data
function M.debug(module, message, context)
  write_log(M.levels.DEBUG, module, message, context)
end

--- Log info message
--- @param module string Module name
--- @param message string Log message
--- @param context table|nil Optional context data
function M.info(module, message, context)
  write_log(M.levels.INFO, module, message, context)
end

--- Log warning message
--- @param module string Module name
--- @param message string Log message
--- @param context table|nil Optional context data
function M.warn(module, message, context)
  write_log(M.levels.WARN, module, message, context)
end

--- Log error message
--- @param module string Module name
--- @param message string Log message
--- @param context table|nil Optional context data
function M.error(module, message, context)
  write_log(M.levels.ERROR, module, message, context)
end

--- Log an error object from the errors module
--- @param module string Module name
--- @param err table Error object
function M.log_error(module, err)
  if type(err) == 'table' and err.type and err.message then
    M.error(module, err.message, err.context)
  else
    M.error(module, tostring(err))
  end
end

--- Get recent log entries
--- @param count number|nil Number of entries to get (default: 50)
--- @return table List of log entries
function M.get_recent_logs(count)
  count = count or 50
  local log_path = M.get_log_path()

  if vim.fn.filereadable(log_path) ~= 1 then
    return {}
  end

  -- Read file
  local lines = {}
  local file = io.open(log_path, 'r')
  if file then
    for line in file:lines() do
      table.insert(lines, line)
    end
    file:close()
  end

  -- Return last N lines
  local start = math.max(1, #lines - count + 1)
  local result = {}
  for i = start, #lines do
    table.insert(result, lines[i])
  end

  return result
end

--- Clear log files
function M.clear_logs()
  local log_path = M.get_log_path()

  -- Remove main log
  if vim.fn.filereadable(log_path) == 1 then
    os.remove(log_path)
  end

  -- Remove backups
  for i = 1, M.config.max_backups do
    local backup_path = log_path .. '.' .. i
    if vim.fn.filereadable(backup_path) == 1 then
      os.remove(backup_path)
    end
  end
end

--- Open log file in a split window
--- @param split_cmd string|nil Split command (default: 'split')
function M.open_logs(split_cmd)
  split_cmd = split_cmd or 'split'
  local log_path = M.get_log_path()

  if vim.fn.filereadable(log_path) ~= 1 then
    vim.notify('No log file found at: ' .. log_path, vim.log.levels.WARN)
    return
  end

  -- Open in split
  vim.cmd(split_cmd .. ' ' .. vim.fn.fnameescape(log_path))

  -- Set buffer options
  vim.bo.bufhidden = 'wipe'
  vim.bo.buftype = 'nowrite'
  vim.bo.swapfile = false

  -- Jump to end of file
  vim.cmd('normal! G')
end

return M
