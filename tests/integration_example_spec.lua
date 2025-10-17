-- tests/integration_example_spec.lua
-- Example integration test demonstrating mock framework usage
-- This file serves as a template for writing integration tests

-- Add tests directory to package path for helper modules
local tests_dir = vim.fn.getcwd() .. '/tests'
package.path = package.path .. ';' .. tests_dir .. '/?.lua'
package.path = package.path .. ';' .. tests_dir .. '/?/init.lua'

local helpers = require('helpers')
local mocks = require('mocks')

describe('integration example', function()
    local env

    before_each(function()
        -- Create mock environment for each test
        env = mocks.create_env({
            git = {
                current_branch = 'feature/test',
                repo_root = '/test/repo',
                remote_url = 'git@gitlab.com:test/repo.git',
            },
            glab = {
                installation_ok = true,
            },
        })
    end)

    after_each(function()
        -- Clean up mocks after each test
        if env then
            env.teardown()
        end
    end)

    describe('project detection', function()
        it('should detect GitLab project from remote URL', function()
            local project = require('mrreviewer.integrations.project')

            local info, err = project.get_project_info()

            assert.is_not_nil(info)
            assert.is_nil(err)
            assert.equals('test/repo', info.full_path)
        end)

        it('should fail when not in a git repository', function()
            -- Simulate not being in a git repo
            env.git.simulate_no_repo()

            local project = require('mrreviewer.integrations.project')
            local info, err = project.get_project_info()

            assert.is_nil(info)
            assert.is_not_nil(err)
            helpers.assert_error(err, 'GitError')
        end)
    end)

    describe('glab integration', function()
        it('should check glab installation', function()
            local glab = require('mrreviewer.integrations.glab')

            local ok, err = glab.check_installation()

            assert.is_true(ok)
            assert.is_nil(err)
        end)

        it('should fail when glab is not installed', function()
            env.glab.simulate_not_installed()

            local glab = require('mrreviewer.integrations.glab')
            local ok, err = glab.check_installation()

            assert.is_false(ok)
            assert.is_not_nil(err)
            helpers.assert_error(err, 'ValidationError')
        end)

        it('should execute glab commands', function()
            -- Set up mock response for MR list
            local mock_mrs = {
                {
                    iid = 123,
                    title = 'Test MR',
                    state = 'opened',
                    source_branch = 'feature/test',
                },
            }
            env.glab.simulate_mr_list(mock_mrs)

            local glab = require('mrreviewer.integrations.glab')
            local args = glab.build_mr_list_args('opened')

            -- Execute async command
            local result = nil
            glab.execute_async(args, function(exit_code, stdout, stderr)
                result = { exit_code = exit_code, stdout = stdout, stderr = stderr }
            end)

            -- Wait for async operation
            helpers.wait_for(function()
                return result ~= nil
            end, 1000)

            assert.is_not_nil(result)
            assert.equals(0, result.exit_code)
            assert.matches('Test MR', result.stdout)
        end)
    end)

    describe('notification integration', function()
        it('should capture vim.notify calls', function()
            local utils = require('mrreviewer.lib.utils')

            utils.notify('Test message', 'info')

            local calls = env.vim.get_notify_calls()
            assert.equals(1, #calls)
            assert.equals('Test message', calls[1].msg)
        end)

        it('should check if specific notification was sent', function()
            local utils = require('mrreviewer.lib.utils')

            utils.notify('Operation successful', 'info')
            utils.notify('Warning message', 'warn')

            assert.is_true(env.vim.was_notified('Operation successful'))
            assert.is_true(env.vim.was_notified('Warning'))
            assert.is_false(env.vim.was_notified('Error'))
        end)
    end)

    describe('helpers usage examples', function()
        it('should use mock data helpers', function()
            local mr_data = helpers.mock_mr_data({ iid = 999, title = 'Custom MR' })

            assert.equals(999, mr_data.iid)
            assert.equals('Custom MR', mr_data.title)
            assert.equals('testuser', mr_data.author.username)
        end)

        it('should use mock comment helpers', function()
            local comment = helpers.mock_comment({
                body = 'Custom comment',
                resolved = true,
            })

            assert.equals('Custom comment', comment.body)
            assert.is_true(comment.resolved)
            assert.equals(10, comment.position.new_line)
        end)

        it('should create and clean up temp files', function()
            local path = helpers.create_temp_file('test content', 'txt')

            assert.equals(1, vim.fn.filereadable(path))

            local content = vim.fn.readfile(path)
            assert.equals(1, #content)
            assert.equals('test content', content[1])

            helpers.cleanup_temp(path)
            assert.equals(0, vim.fn.filereadable(path))
        end)

        it('should assert error tuples', function()
            local errors = require('mrreviewer.core.errors')

            -- Success case
            helpers.assert_tuple('result', nil, true)

            -- Error case
            local err = errors.git_error('Test error')
            helpers.assert_tuple(nil, err, false)
        end)
    end)
end)
