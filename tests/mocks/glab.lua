-- tests/mocks/glab.lua
-- Mock glab module for testing

local M = {}

-- Store original module
M._original = nil

-- Mock state
M.state = {
    installation_ok = true,
    async_responses = {},
    sync_responses = {},
    call_count = 0,
}

--- Set up glab mocks
--- @param opts table|nil Optional configuration
function M.setup(opts)
    opts = opts or {}

    -- Store original if not already stored
    if not M._original then
        M._original = require('mrreviewer.glab')
    end

    -- Merge options into state
    M.state = vim.tbl_deep_extend('force', M.state, opts)

    -- Create mock module
    local mock = {}

    --- Mock execute_async
    function mock.execute_async(args, callback, timeout, cwd)
        M.state.call_count = M.state.call_count + 1

        local cmd = table.concat(args, ' ')
        local response = M.state.async_responses[cmd] or {
            exit_code = 0,
            stdout = '{}',
            stderr = '',
        }

        -- Call callback asynchronously
        vim.schedule(function()
            callback(response.exit_code, response.stdout, response.stderr)
        end)
    end

    --- Mock execute_sync
    function mock.execute_sync(args, timeout, cwd)
        M.state.call_count = M.state.call_count + 1

        local cmd = table.concat(args, ' ')
        local response = M.state.sync_responses[cmd] or {
            exit_code = 0,
            stdout = '{}',
            stderr = '',
        }

        return response.exit_code, response.stdout, response.stderr, response.error
    end

    --- Mock check_installation
    function mock.check_installation()
        if M.state.installation_ok then
            return true, nil
        else
            local errors = require('mrreviewer.errors')
            return false, errors.validation_error('glab CLI is not installed')
        end
    end

    --- Mock build_mr_list_args
    function mock.build_mr_list_args(state)
        return M._original.build_mr_list_args(state)
    end

    --- Mock build_mr_view_args
    function mock.build_mr_view_args(mr_number, with_comments)
        return M._original.build_mr_view_args(mr_number, with_comments)
    end

    --- Mock build_mr_diff_args
    function mock.build_mr_diff_args(mr_number)
        return M._original.build_mr_diff_args(mr_number)
    end

    -- Replace the module
    package.loaded['mrreviewer.glab'] = mock

    return mock
end

--- Restore original glab module
function M.teardown()
    if M._original then
        package.loaded['mrreviewer.glab'] = M._original
    end

    -- Reset state
    M.state = {
        installation_ok = true,
        async_responses = {},
        sync_responses = {},
        call_count = 0,
    }
end

--- Add a mock response for async execution
--- @param command string Command string (space-separated args)
--- @param response table Response { exit_code, stdout, stderr }
function M.add_async_response(command, response)
    M.state.async_responses[command] = response
end

--- Add a mock response for sync execution
--- @param command string Command string (space-separated args)
--- @param response table Response { exit_code, stdout, stderr, error }
function M.add_sync_response(command, response)
    M.state.sync_responses[command] = response
end

--- Simulate glab not being installed
function M.simulate_not_installed()
    M.state.installation_ok = false
end

--- Simulate successful MR list response
--- @param mrs table List of MR data objects
function M.simulate_mr_list(mrs)
    local json = vim.json.encode(mrs)
    M.add_async_response('mr list --output json', {
        exit_code = 0,
        stdout = json,
        stderr = '',
    })
end

--- Simulate successful MR view response
--- @param mr_number number MR number
--- @param mr_data table MR data object
function M.simulate_mr_view(mr_number, mr_data)
    local json = vim.json.encode(mr_data)
    M.add_async_response(string.format('mr view %s --output json --comments', mr_number), {
        exit_code = 0,
        stdout = json,
        stderr = '',
    })
end

--- Simulate failed glab command
--- @param command string Command string
--- @param stderr string Error message
function M.simulate_error(command, stderr)
    M.add_async_response(command, {
        exit_code = 1,
        stdout = '',
        stderr = stderr or 'Command failed',
    })
end

--- Get the number of times glab was called
--- @return number Call count
function M.get_call_count()
    return M.state.call_count
end

--- Reset call count
function M.reset_call_count()
    M.state.call_count = 0
end

return M
