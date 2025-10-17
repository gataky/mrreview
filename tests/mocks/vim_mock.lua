-- tests/mocks/vim_mock.lua
-- Mock vim functions for testing

local M = {}

-- Store originals
M._originals = {}

-- Captured data
M.captured = {
    notify_calls = {},
}

--- Set up vim mocks
--- @param opts table|nil Optional configuration
function M.setup(opts)
    opts = opts or {}

    -- Mock vim.notify
    if not M._originals.notify then
        M._originals.notify = vim.notify
    end

    vim.notify = function(msg, level, opts_notify)
        table.insert(M.captured.notify_calls, {
            msg = msg,
            level = level,
            opts = opts_notify,
        })
    end
end

--- Restore original vim functions
function M.teardown()
    if M._originals.notify then
        vim.notify = M._originals.notify
    end

    -- Reset captured data
    M.captured = {
        notify_calls = {},
    }
end

--- Get all captured notify calls
--- @return table List of notify calls
function M.get_notify_calls()
    return M.captured.notify_calls
end

--- Get the last notify call
--- @return table|nil Last notify call
function M.get_last_notify()
    return M.captured.notify_calls[#M.captured.notify_calls]
end

--- Check if notify was called with a specific message
--- @param message string Message to search for
--- @return boolean True if message was found
function M.was_notified(message)
    for _, call in ipairs(M.captured.notify_calls) do
        if call.msg:match(message) then
            return true
        end
    end
    return false
end

--- Clear captured notify calls
function M.clear_notify_calls()
    M.captured.notify_calls = {}
end

return M
