-- lua/mrreviewer/init.lua
-- Main module initialization and public API

local M = {}

-- Store plugin state
M.state = {
  initialized = false,
  current_mr = nil,
  current_diff_buffers = {},
}

--- Setup function to initialize the plugin with user configuration
--- @param opts table|nil User configuration options
function M.setup(opts)
  opts = opts or {}

  -- Initialize configuration
  local config = require('mrreviewer.config')
  config.setup(opts)

  -- Set up highlight groups
  local highlights = require('mrreviewer.highlights')
  highlights.setup()

  M.state.initialized = true
end

--- Get the current plugin state
--- @return table Current state
function M.get_state()
  return M.state
end

--- Check if plugin is initialized
--- @return boolean
function M.is_initialized()
  return M.state.initialized
end

--- Clear current MR state
function M.clear_state()
  M.state.current_mr = nil
  M.state.current_diff_buffers = {}
end

return M
