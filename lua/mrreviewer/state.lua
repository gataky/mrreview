-- lua/mrreviewer/state.lua
-- Centralized state management for the MRReviewer plugin
-- Consolidates state from init.lua, diff.lua, and comments.lua

local M = {}
local errors = require('mrreviewer.errors')

-- Central state structure
M._state = {
  -- Session state (from init.lua)
  session = {
    initialized = false,
    current_mr = nil,
    current_diff_buffers = {},
  },

  -- Diff view state (from diff/init.lua)
  diff = {
    buffers = {},
    windows = {},
    current_file_index = 1,
    files = {},
  },

  -- Comment display state (from comments/init.lua)
  comments = {
    displayed_comments = {},
    comment_buffer = nil,
    comment_window = nil,
    comment_float_win = nil,
    comment_float_buf = nil,
    namespace_id = vim.api.nvim_create_namespace('mrreviewer_comments'),
  },
}

--- Get the entire state object
--- @return table Current state
function M.get()
  return M._state
end

--- Get session state
--- @return table Session state
function M.get_session()
  return M._state.session
end

--- Get diff state
--- @return table Diff state
function M.get_diff()
  return M._state.diff
end

--- Get comments state
--- @return table Comments state
function M.get_comments()
  return M._state.comments
end

--- Get a specific state value using dot notation
--- @param path string Path to value (e.g., 'session.initialized', 'diff.current_file_index')
--- @return any|nil Value at path or nil if not found
function M.get_value(path)
  if not path or type(path) ~= 'string' then
    return nil
  end

  local keys = vim.split(path, '.', { plain = true })
  local current = M._state

  for _, key in ipairs(keys) do
    if type(current) ~= 'table' then
      return nil
    end
    current = current[key]
  end

  return current
end

--- Set a specific state value using dot notation
--- @param path string Path to value (e.g., 'session.initialized')
--- @param value any Value to set
--- @return boolean, table|nil Success status and error object if failed
function M.set_value(path, value)
  if not path or type(path) ~= 'string' then
    return false, errors.validation_error('Invalid path: must be a non-empty string')
  end

  local keys = vim.split(path, '.', { plain = true })
  if #keys == 0 then
    return false, errors.validation_error('Invalid path: cannot be empty')
  end

  local current = M._state
  local last_key = keys[#keys]

  -- Navigate to the parent
  for i = 1, #keys - 1 do
    local key = keys[i]
    if type(current) ~= 'table' then
      return false, errors.validation_error('Cannot set value: parent is not a table', {
        path = path,
        failed_at_key = key,
      })
    end
    if not current[key] then
      return false, errors.validation_error('Invalid path: key does not exist', {
        path = path,
        missing_key = key,
      })
    end
    current = current[key]
  end

  -- Set the value
  if type(current) ~= 'table' then
    return false, errors.validation_error('Cannot set value: parent is not a table', {
      path = path,
    })
  end

  current[last_key] = value
  return true, nil
end

--- Check if the plugin is initialized
--- @return boolean
function M.is_initialized()
  return M._state.session.initialized
end

--- Set the initialized flag
--- @param value boolean
function M.set_initialized(value)
  M._state.session.initialized = value
end

--- Get current MR data
--- @return table|nil Current MR or nil
function M.get_current_mr()
  return M._state.session.current_mr
end

--- Set current MR data
--- @param mr_data table|nil MR data or nil to clear
function M.set_current_mr(mr_data)
  M._state.session.current_mr = mr_data
end

--- Clear all session state
function M.clear_session()
  M._state.session.current_mr = nil
  M._state.session.current_diff_buffers = {}
end

--- Clear all diff state
function M.clear_diff()
  M._state.diff.buffers = {}
  M._state.diff.windows = {}
  M._state.diff.current_file_index = 1
  M._state.diff.files = {}
end

--- Clear all comments state
function M.clear_comments()
  M._state.comments.displayed_comments = {}
  M._state.comments.comment_buffer = nil
  M._state.comments.comment_window = nil
  M._state.comments.comment_float_win = nil
  M._state.comments.comment_float_buf = nil
end

--- Clear all state
function M.clear_all()
  M.clear_session()
  M.clear_diff()
  M.clear_comments()
end

--- Validate state structure
--- @param state table|nil State object to validate (defaults to current state)
--- @return boolean, table|nil Valid status and error object if invalid
function M.validate(state)
  state = state or M._state

  -- Check top-level structure
  if type(state) ~= 'table' then
    return false, errors.validation_error('State must be a table')
  end

  if type(state.session) ~= 'table' then
    return false, errors.validation_error('state.session must be a table')
  end

  if type(state.diff) ~= 'table' then
    return false, errors.validation_error('state.diff must be a table')
  end

  if type(state.comments) ~= 'table' then
    return false, errors.validation_error('state.comments must be a table')
  end

  -- Validate session fields
  if type(state.session.initialized) ~= 'boolean' then
    return false, errors.validation_error('state.session.initialized must be a boolean')
  end

  if state.session.current_mr ~= nil and type(state.session.current_mr) ~= 'table' then
    return false, errors.validation_error('state.session.current_mr must be a table or nil')
  end

  if type(state.session.current_diff_buffers) ~= 'table' then
    return false, errors.validation_error('state.session.current_diff_buffers must be a table')
  end

  -- Validate diff fields
  if type(state.diff.buffers) ~= 'table' then
    return false, errors.validation_error('state.diff.buffers must be a table')
  end

  if type(state.diff.windows) ~= 'table' then
    return false, errors.validation_error('state.diff.windows must be a table')
  end

  if type(state.diff.current_file_index) ~= 'number' then
    return false, errors.validation_error('state.diff.current_file_index must be a number')
  end

  if type(state.diff.files) ~= 'table' then
    return false, errors.validation_error('state.diff.files must be a table')
  end

  -- Validate comments fields
  if type(state.comments.displayed_comments) ~= 'table' then
    return false, errors.validation_error('state.comments.displayed_comments must be a table')
  end

  if
    state.comments.comment_buffer ~= nil
    and type(state.comments.comment_buffer) ~= 'number'
  then
    return false,
      errors.validation_error('state.comments.comment_buffer must be a number or nil')
  end

  if
    state.comments.comment_window ~= nil
    and type(state.comments.comment_window) ~= 'number'
  then
    return false,
      errors.validation_error('state.comments.comment_window must be a number or nil')
  end

  if
    state.comments.comment_float_win ~= nil
    and type(state.comments.comment_float_win) ~= 'number'
  then
    return false,
      errors.validation_error('state.comments.comment_float_win must be a number or nil')
  end

  if
    state.comments.comment_float_buf ~= nil
    and type(state.comments.comment_float_buf) ~= 'number'
  then
    return false,
      errors.validation_error('state.comments.comment_float_buf must be a number or nil')
  end

  if type(state.comments.namespace_id) ~= 'number' then
    return false, errors.validation_error('state.comments.namespace_id must be a number')
  end

  return true, nil
end

--- Reset state to initial values
function M.reset()
  M._state = {
    session = {
      initialized = false,
      current_mr = nil,
      current_diff_buffers = {},
    },
    diff = {
      buffers = {},
      windows = {},
      current_file_index = 1,
      files = {},
    },
    comments = {
      displayed_comments = {},
      comment_buffer = nil,
      comment_window = nil,
      comment_float_win = nil,
      comment_float_buf = nil,
      namespace_id = vim.api.nvim_create_namespace('mrreviewer_comments'),
    },
  }
end

return M
