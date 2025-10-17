-- lua/mrreviewer/errors.lua
-- Standardized error handling and reporting

local M = {}

--- Error types
M.ErrorType = {
  GIT = 'GitError',
  NETWORK = 'NetworkError',
  PARSE = 'ParseError',
  CONFIG = 'ConfigError',
  VALIDATION = 'ValidationError',
  IO = 'IOError',
  UNKNOWN = 'UnknownError',
}

--- Create a new error object
--- @param type string Error type from ErrorType enum
--- @param message string Error message
--- @param context table|nil Optional context data
--- @return table Error object
function M.new(type, message, context)
  return {
    type = type or M.ErrorType.UNKNOWN,
    message = message or 'An unknown error occurred',
    context = context or {},
    timestamp = os.time(),
    traceback = debug.traceback('', 2),
  }
end

--- Create a GitError
--- @param message string Error message
--- @param context table|nil Optional context data
--- @return table Error object
function M.git_error(message, context)
  return M.new(M.ErrorType.GIT, message, context)
end

--- Create a NetworkError
--- @param message string Error message
--- @param context table|nil Optional context data
--- @return table Error object
function M.network_error(message, context)
  return M.new(M.ErrorType.NETWORK, message, context)
end

--- Create a ParseError
--- @param message string Error message
--- @param context table|nil Optional context data
--- @return table Error object
function M.parse_error(message, context)
  return M.new(M.ErrorType.PARSE, message, context)
end

--- Create a ConfigError
--- @param message string Error message
--- @param context table|nil Optional context data
--- @return table Error object
function M.config_error(message, context)
  return M.new(M.ErrorType.CONFIG, message, context)
end

--- Create a ValidationError
--- @param message string Error message
--- @param context table|nil Optional context data
--- @return table Error object
function M.validation_error(message, context)
  return M.new(M.ErrorType.VALIDATION, message, context)
end

--- Create an IOError
--- @param message string Error message
--- @param context table|nil Optional context data
--- @return table Error object
function M.io_error(message, context)
  return M.new(M.ErrorType.IO, message, context)
end

--- Wrap an existing error with additional context
--- @param context_message string Additional context
--- @param err table|string Existing error or error message
--- @return table Wrapped error object
function M.wrap(context_message, err)
  if type(err) == 'table' and err.type then
    -- Already an error object, add context
    local wrapped = vim.deepcopy(err)
    wrapped.message = context_message .. ': ' .. wrapped.message
    if not wrapped.context.wrapped then
      wrapped.context.wrapped = {}
    end
    table.insert(wrapped.context.wrapped, {
      message = context_message,
      timestamp = os.time(),
    })
    return wrapped
  else
    -- Plain string error, create new error object
    return M.new(M.ErrorType.UNKNOWN, context_message .. ': ' .. tostring(err))
  end
end

--- Try to execute a function with error handling
--- @param fn function Function to execute
--- @param error_context string|nil Context message for errors
--- @return any, table|nil Result on success, or nil and error object on failure
function M.try(fn, error_context)
  local ok, result = pcall(fn)

  if ok then
    return result, nil
  else
    local err = result
    if error_context then
      err = M.wrap(error_context, err)
    elseif type(err) == 'string' then
      err = M.new(M.ErrorType.UNKNOWN, err)
    end
    return nil, err
  end
end

--- Log an error (uses vim.notify for now, can be extended with logger module)
--- @param err table|string Error object or error message
--- @param level string|nil Log level ('error', 'warn', 'info'), defaults to 'error'
function M.log(err, level)
  level = level or 'error'

  local message
  if type(err) == 'table' and err.message then
    message = string.format('[%s] %s', err.type or 'Error', err.message)
  else
    message = tostring(err)
  end

  -- Map our level to vim.log.levels
  local vim_level = vim.log.levels.ERROR
  if level == 'warn' then
    vim_level = vim.log.levels.WARN
  elseif level == 'info' then
    vim_level = vim.log.levels.INFO
  end

  vim.notify(message, vim_level)

  -- If we have context, log it at debug level
  if type(err) == 'table' and err.context and next(err.context) then
    local context_str = vim.inspect(err.context)
    -- For now, we'll skip debug output unless we have a logger
    -- When logger module is implemented, add: logger.debug(context_str)
  end
end

--- Check if a value is an error object
--- @param value any Value to check
--- @return boolean True if value is an error object
function M.is_error(value)
  if type(value) ~= 'table' then
    return false
  end
  return value.type ~= nil and value.message ~= nil
end

--- Format an error for display to users
--- @param err table|string Error object or error message
--- @return string Formatted error message
function M.format(err)
  if type(err) == 'table' and err.message then
    local msg = err.message

    -- Add type prefix for non-unknown errors
    if err.type and err.type ~= M.ErrorType.UNKNOWN then
      msg = string.format('[%s] %s', err.type, msg)
    end

    -- Add context hints if available
    if err.context and err.context.suggestion then
      msg = msg .. '\n  → ' .. err.context.suggestion
    end

    return msg
  else
    return tostring(err)
  end
end

--- Create a standard error handler that logs and returns nil, err
--- @param error_type string Error type from ErrorType enum
--- @param context_message string Context message
--- @return function Error handler function
function M.handler(error_type, context_message)
  return function(err)
    local error_obj = M.new(error_type, context_message .. ': ' .. tostring(err))
    M.log(error_obj)
    return nil, error_obj
  end
end

return M
