-- lua/mrreviewer/init.lua
-- Main module initialization and public API

local M = {}
local state_module = require('mrreviewer.state')

-- Expose state dynamically for backward compatibility
-- This ensures code accessing mrreviewer.state.current_mr gets the latest value
setmetatable(M, {
  __index = function(t, key)
    if key == 'state' then
      return state_module.get_session()
    end
    return rawget(t, key)
  end,
})

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

  state_module.set_initialized(true)
end

--- Get the current plugin state
--- @return table Current state
function M.get_state()
  return state_module.get_session()
end

--- Check if plugin is initialized
--- @return boolean
function M.is_initialized()
  return state_module.is_initialized()
end

--- Clear current MR state
function M.clear_state()
  state_module.clear_session()
end

return M
