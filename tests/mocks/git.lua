-- tests/mocks/git.lua
-- Mock git module for testing

local M = {}

-- Store original module
M._original = nil

-- Mock state
M.state = {
    is_git_repo = true,
    current_branch = 'main',
    repo_root = '/mock/repo',
    remote_url = 'git@gitlab.com:test/repo.git',
    upstream_branch = 'origin/main',
    command_exists = {},
}

--- Set up git mocks
--- @param opts table|nil Optional configuration
function M.setup(opts)
    opts = opts or {}

    -- Store original if not already stored
    if not M._original then
        M._original = require('mrreviewer.integrations.git')
    end

    -- Merge options into state
    M.state = vim.tbl_deep_extend('force', M.state, opts)

    -- Create mock module
    local mock = {}

    --- Mock get_current_branch
    function mock.get_current_branch(cwd)
        if M.state.current_branch then
            return M.state.current_branch, nil
        else
            local errors = require('mrreviewer.core.errors')
            return nil, errors.git_error('Not in a git repository')
        end
    end

    --- Mock is_git_repo
    function mock.is_git_repo(cwd)
        return M.state.is_git_repo
    end

    --- Mock get_repo_root
    function mock.get_repo_root(cwd)
        if M.state.repo_root then
            return M.state.repo_root, nil
        else
            local errors = require('mrreviewer.core.errors')
            return nil, errors.git_error('Not in a git repository')
        end
    end

    --- Mock get_remote_url
    function mock.get_remote_url(remote_name, cwd)
        remote_name = remote_name or 'origin'
        if M.state.remote_url then
            return M.state.remote_url, nil
        else
            local errors = require('mrreviewer.core.errors')
            return nil, errors.git_error('Remote not found: ' .. remote_name)
        end
    end

    --- Mock get_upstream_branch
    function mock.get_upstream_branch(cwd)
        return M.state.upstream_branch, nil
    end

    --- Mock command_exists
    function mock.command_exists(command)
        if M.state.command_exists[command] ~= nil then
            return M.state.command_exists[command]
        end
        return true -- Default to true
    end

    -- Replace the module
    package.loaded['mrreviewer.git'] = mock

    return mock
end

--- Restore original git module
function M.teardown()
    if M._original then
        package.loaded['mrreviewer.git'] = M._original
    end

    -- Reset state
    M.state = {
        is_git_repo = true,
        current_branch = 'main',
        repo_root = '/mock/repo',
        remote_url = 'git@gitlab.com:test/repo.git',
        upstream_branch = 'origin/main',
        command_exists = {},
    }
end

--- Configure mock to simulate not being in a git repo
function M.simulate_no_repo()
    M.state.is_git_repo = false
    M.state.current_branch = nil
    M.state.repo_root = nil
    M.state.upstream_branch = nil
end

--- Configure mock to simulate a specific branch
function M.simulate_branch(branch_name)
    M.state.current_branch = branch_name
end

--- Configure mock to simulate a specific remote URL
function M.simulate_remote_url(url)
    M.state.remote_url = url
end

return M
