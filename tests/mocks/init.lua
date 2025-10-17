-- tests/mocks/init.lua
-- Main mock framework loader

local M = {}

-- Load sub-modules
M.git = require('tests.mocks.git')
M.glab = require('tests.mocks.glab')
M.vim = require('tests.mocks.vim_mock')

--- Set up all mocks
--- @param opts table|nil Optional configuration { git = {...}, glab = {...}, vim = {...} }
function M.setup(opts)
    opts = opts or {}

    if opts.git ~= false then
        M.git.setup(opts.git or {})
    end

    if opts.glab ~= false then
        M.glab.setup(opts.glab or {})
    end

    if opts.vim ~= false then
        M.vim.setup(opts.vim or {})
    end
end

--- Tear down all mocks
function M.teardown()
    M.git.teardown()
    M.glab.teardown()
    M.vim.teardown()
end

--- Create a complete mock environment for testing
--- Useful in before_each() blocks
--- @param opts table|nil Optional configuration
--- @return table Mock environment with helpers
function M.create_env(opts)
    M.setup(opts)

    local env = {
        git = M.git,
        glab = M.glab,
        vim = M.vim,
        teardown = function()
            M.teardown()
        end,
    }

    return env
end

return M
