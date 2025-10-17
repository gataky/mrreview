-- lua/mrreviewer/init.lua
-- Main entry point for the MR Reviewer plugin

local M = {}
local state_module = require('mrreviewer.core.state')

-- Expose state dynamically for backward compatibility
setmetatable(M, {
    __index = function(t, key)
        if key == 'state' then
            return state_module.get_session()
        end
        return rawget(t, key)
    end,
})

--- Setup the plugin with user configuration
--- @param opts table|nil User configuration options
function M.setup(opts)
    opts = opts or {}

    -- Initialize configuration
    local config = require('mrreviewer.core.config')
    config.setup(opts)

    -- Initialize logger with user config
    local logger = require('mrreviewer.core.logger')
    local logging_config = config.get_value('logging')
    if logging_config then
        logger.setup(logging_config)
    end

    -- Setup highlights
    local highlights = require('mrreviewer.ui.highlights')
    highlights.setup()

    -- Mark plugin as initialized
    state_module.set_initialized(true)
end

--- Get the current session state
--- @return table Session state
function M.get_state()
    return state_module.get_session()
end

--- Check if the plugin is initialized
--- @return boolean True if initialized
function M.is_initialized()
    return state_module.is_initialized()
end

--- Clear the current session state
function M.clear_state()
    state_module.clear_session()
end

return M
