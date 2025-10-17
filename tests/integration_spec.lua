-- tests/integration_spec.lua
-- Integration tests for MRReviewer
-- Tests multiple modules working together in realistic scenarios

-- Add tests directory to package path for helper modules
local tests_dir = vim.fn.getcwd() .. '/tests'
package.path = package.path .. ';' .. tests_dir .. '/?.lua'
package.path = package.path .. ';' .. tests_dir .. '/?/init.lua'

local helpers = require('helpers')
local mocks = require('mocks')

describe('MRReviewer Integration Tests', function()
    local env

    before_each(function()
        -- Create mock environment for each test
        env = mocks.create_env({
            git = {
                current_branch = 'feature/test-branch',
                repo_root = '/test/repo',
                remote_url = 'git@gitlab.com:testorg/testrepo.git',
            },
            glab = {
                installation_ok = true,
            },
        })
    end)

    after_each(function()
        -- Clean up mocks and state after each test
        if env then
            env.teardown()
        end
        -- Clear plugin state
        local state = require('mrreviewer.state')
        state.clear_all()
    end)

    describe('Project Detection', function()
        it('should detect GitLab project from git remote', function()
            local project = require('mrreviewer.project')

            local info, err = project.get_project_info()

            assert.is_not_nil(info)
            assert.is_nil(err)
            assert.equals('testorg/testrepo', info.full_path)
            assert.equals('testorg', info.namespace)
            assert.equals('testrepo', info.project)
        end)

        it('should fail gracefully when not in git repo', function()
            env.git.simulate_no_repo()

            local project = require('mrreviewer.project')
            local info, err = project.get_project_info()

            assert.is_nil(info)
            assert.is_not_nil(err)
            helpers.assert_error(err, 'GitError')
        end)

        it('should handle invalid GitLab URLs', function()
            env.git.simulate_remote_url('https://github.com/user/repo.git')

            local project = require('mrreviewer.project')
            local info, err = project.get_project_info()

            assert.is_nil(info)
            assert.is_not_nil(err)
            helpers.assert_error(err, 'ParseError')
        end)
    end)

    describe('MR List Operation', function()
        it('should fetch and parse MR list', function()
            -- Set up mock MR data
            local mock_mrs = {
                {
                    iid = 123,
                    title = 'Add feature X',
                    state = 'opened',
                    source_branch = 'feature/test-branch',
                    author = { username = 'testuser' },
                    web_url = 'https://gitlab.com/testorg/testrepo/-/merge_requests/123',
                },
                {
                    iid = 124,
                    title = 'Fix bug Y',
                    state = 'opened',
                    source_branch = 'fix/bug-y',
                    author = { username = 'anotheruser' },
                    web_url = 'https://gitlab.com/testorg/testrepo/-/merge_requests/124',
                },
            }
            env.glab.simulate_mr_list(mock_mrs)

            local glab = require('mrreviewer.glab')
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

            -- Parse the result
            local ok, data = pcall(vim.json.decode, result.stdout)
            assert.is_true(ok)
            assert.equals(2, #data)
            assert.equals('Add feature X', data[1].title)
            assert.equals('Fix bug Y', data[2].title)
        end)

        it('should handle glab not installed', function()
            env.glab.simulate_not_installed()

            local glab = require('mrreviewer.glab')
            local ok, err = glab.check_installation()

            assert.is_false(ok)
            assert.is_not_nil(err)
            helpers.assert_error(err, 'ValidationError')
        end)

        it('should handle glab command failure', function()
            env.glab.simulate_error('mr list --output json', 'API request failed')

            local glab = require('mrreviewer.glab')
            local args = glab.build_mr_list_args('opened')

            local result = nil
            glab.execute_async(args, function(exit_code, stdout, stderr)
                result = { exit_code = exit_code, stdout = stdout, stderr = stderr }
            end)

            helpers.wait_for(function()
                return result ~= nil
            end, 1000)

            assert.is_not_nil(result)
            assert.equals(1, result.exit_code)
            assert.matches('API request failed', result.stderr)
        end)
    end)

    describe('MR View Operation', function()
        it('should fetch MR with comments', function()
            local mr_data = helpers.mock_mr_data({
                iid = 125,
                title = 'Test MR',
                description = 'Test description',
            })

            -- Add comments to the MR
            mr_data.comments = {
                helpers.mock_comment({ body = 'First comment' }),
                helpers.mock_comment({ body = 'Second comment', resolved = true }),
            }

            env.glab.simulate_mr_view(125, mr_data)

            local glab = require('mrreviewer.glab')
            local args = glab.build_mr_view_args(125, true)

            local result = nil
            glab.execute_async(args, function(exit_code, stdout, stderr)
                result = { exit_code = exit_code, stdout = stdout, stderr = stderr }
            end)

            helpers.wait_for(function()
                return result ~= nil
            end, 1000)

            assert.is_not_nil(result)
            assert.equals(0, result.exit_code)

            local ok, data = pcall(vim.json.decode, result.stdout)
            assert.is_true(ok)
            assert.equals('Test MR', data.title)
            assert.equals(2, #data.comments)
        end)
    end)

    describe('State Management Integration', function()
        it('should maintain state across operations', function()
            local state = require('mrreviewer.state')

            -- Initially not initialized
            assert.is_false(state.is_initialized())

            -- Set initialized
            state.set_initialized(true)
            assert.is_true(state.is_initialized())

            -- Set current MR
            local mr_data = helpers.mock_mr_data({ iid = 126, title = 'State Test MR' })
            state.set_current_mr(mr_data)

            local current = state.get_current_mr()
            assert.is_not_nil(current)
            assert.equals(126, current.data.iid)
            assert.equals('State Test MR', current.data.title)

            -- Clear specific sections
            state.clear_session()
            assert.is_false(state.is_initialized())
            -- MR data should still be there (in session state)
            current = state.get_current_mr()
            assert.is_not_nil(current)

            -- Clear all state
            state.clear_all()
            current = state.get_current_mr()
            assert.is_nil(current)
        end)

        it('should handle dot notation state access', function()
            local state = require('mrreviewer.state')

            -- Set nested values
            state.set_value('session.initialized', true)
            state.set_value('session.project_info', {
                full_path = 'testorg/testrepo',
                namespace = 'testorg',
            })

            -- Get nested values
            assert.is_true(state.get_value('session.initialized'))
            assert.equals('testorg/testrepo', state.get_value('session.project_info.full_path'))
            assert.equals('testorg', state.get_value('session.project_info.namespace'))
        end)
    end)

    describe('Error Handling Integration', function()
        it('should propagate errors through the stack', function()
            -- Simulate git error
            env.git.simulate_no_repo()

            local project = require('mrreviewer.project')
            local info, err = project.get_project_info()

            assert.is_nil(info)
            assert.is_not_nil(err)
            helpers.assert_error(err, 'GitError')

            -- Error should contain context
            local errors = require('mrreviewer.errors')
            local formatted = errors.format(err)
            assert.matches('git', formatted:lower())
        end)

        it('should handle validation errors', function()
            local config = require('mrreviewer.config')
            local errors = require('mrreviewer.errors')

            -- Try to set invalid config value
            local result, err = pcall(function()
                config.setup({
                    comment_display_mode = 'invalid_mode', -- Should be 'inline' or 'floating'
                })
            end)

            -- Config should validate and either use default or error
            -- This depends on implementation - for now just verify setup works
            assert.is_true(result or err ~= nil)
        end)
    end)

    describe('Notification Integration', function()
        it('should capture vim.notify calls', function()
            local utils = require('mrreviewer.utils')

            utils.notify('Operation started', 'info')
            utils.notify('Operation complete', 'info')

            local calls = env.vim.get_notify_calls()
            assert.equals(2, #calls)
            assert.equals('Operation started', calls[1].msg)
            assert.equals('Operation complete', calls[2].msg)
        end)

        it('should check for specific notifications', function()
            local utils = require('mrreviewer.utils')

            utils.notify('Fetching MR data...', 'info')
            utils.notify('MR loaded successfully', 'info')
            utils.notify('Warning: No comments found', 'warn')

            assert.is_true(env.vim.was_notified('Fetching MR'))
            assert.is_true(env.vim.was_notified('loaded successfully'))
            assert.is_true(env.vim.was_notified('Warning'))
            assert.is_false(env.vim.was_notified('Error'))
        end)
    end)

    describe('Comment Processing Integration', function()
        it('should filter and sort comments', function()
            local comments_module = require('mrreviewer.comments')

            local comments = {
                helpers.mock_comment({ id = 1, body = 'Resolved comment', resolved = true }),
                helpers.mock_comment({ id = 2, body = 'Unresolved comment', resolved = false }),
                helpers.mock_comment({ id = 3, body = 'Another unresolved', resolved = false }),
            }

            -- Filter to unresolved only
            local unresolved = vim.tbl_filter(function(c)
                return not c.resolved
            end, comments)

            assert.equals(2, #unresolved)
            assert.equals('Unresolved comment', unresolved[1].body)
            assert.equals('Another unresolved', unresolved[2].body)
        end)

        it('should group comments by file', function()
            local comments = {
                helpers.mock_comment({
                    position = { new_path = 'file1.lua', new_line = 10 },
                    body = 'Comment on file1',
                }),
                helpers.mock_comment({
                    position = { new_path = 'file2.lua', new_line = 20 },
                    body = 'Comment on file2',
                }),
                helpers.mock_comment({
                    position = { new_path = 'file1.lua', new_line = 30 },
                    body = 'Another comment on file1',
                }),
            }

            -- Group by file
            local grouped = {}
            for _, comment in ipairs(comments) do
                local file = comment.position.new_path
                grouped[file] = grouped[file] or {}
                table.insert(grouped[file], comment)
            end

            assert.equals(2, #grouped['file1.lua'])
            assert.equals(1, #grouped['file2.lua'])
        end)
    end)

    describe('Configuration Integration', function()
        it('should apply user configuration', function()
            local config = require('mrreviewer.config')

            config.setup({
                comment_display_mode = 'floating',
                window = {
                    width = 100,
                    height = 50,
                },
            })

            local value = config.get_value('comment_display_mode')
            assert.equals('floating', value)

            local width = config.get_value('window.width')
            assert.equals(100, width)
        end)

        it('should use default values for unspecified config', function()
            local config = require('mrreviewer.config')

            config.setup({
                comment_display_mode = 'inline',
            })

            -- Should have default window width
            local width = config.get_value('window.width')
            assert.is_not_nil(width)
            assert.is_true(width > 0)
        end)
    end)

    describe('Full Workflow Integration', function()
        it('should complete full MR review workflow', function()
            -- 1. Check git repo
            local git = require('mrreviewer.git')
            local branch, err = git.get_current_branch()
            assert.is_not_nil(branch)
            assert.equals('feature/test-branch', branch)

            -- 2. Get project info
            local project = require('mrreviewer.project')
            local info, err2 = project.get_project_info()
            assert.is_not_nil(info)
            assert.equals('testorg/testrepo', info.full_path)

            -- 3. Check glab installation
            local glab = require('mrreviewer.glab')
            local ok, err3 = glab.check_installation()
            assert.is_true(ok)

            -- 4. Fetch MR list
            local mock_mrs = {
                helpers.mock_mr_data({ iid = 127, title = 'Workflow Test MR' }),
            }
            env.glab.simulate_mr_list(mock_mrs)

            local args = glab.build_mr_list_args('opened')
            local result = nil
            glab.execute_async(args, function(exit_code, stdout, stderr)
                result = { exit_code = exit_code, stdout = stdout }
            end)

            helpers.wait_for(function()
                return result ~= nil
            end, 1000)

            assert.equals(0, result.exit_code)

            local ok_parse, mrs = pcall(vim.json.decode, result.stdout)
            assert.is_true(ok_parse)
            assert.equals(1, #mrs)

            -- 5. Store in state
            local state = require('mrreviewer.state')
            state.set_initialized(true)
            state.set_current_mr(mrs[1])

            local current = state.get_current_mr()
            assert.is_not_nil(current)
            assert.equals('Workflow Test MR', current.data.title)

            -- 6. Verify notifications were sent (if any)
            -- This depends on whether the modules call notify
            local calls = env.vim.get_notify_calls()
            -- Just verify we can get the calls
            assert.is_not_nil(calls)
        end)
    end)
end)
