-- tests/helpers.lua
-- Test helper utilities for mrreviewer test suite

local M = {}

--- Create a mock MR data structure
--- @param overrides table|nil Optional field overrides
--- @return table MR data object
function M.mock_mr_data(overrides)
    overrides = overrides or {}
    return vim.tbl_deep_extend('force', {
        iid = 123,
        title = 'Test MR',
        description = 'Test MR description',
        author = {
            username = 'testuser',
            name = 'Test User',
        },
        source_branch = 'feature/test',
        target_branch = 'main',
        web_url = 'https://gitlab.com/test/repo/-/merge_requests/123',
        state = 'opened',
        created_at = '2025-01-01T00:00:00Z',
        updated_at = '2025-01-01T12:00:00Z',
    }, overrides)
end

--- Create a mock comment structure
--- @param overrides table|nil Optional field overrides
--- @return table Comment object
function M.mock_comment(overrides)
    overrides = overrides or {}
    return vim.tbl_deep_extend('force', {
        id = 1,
        body = 'Test comment',
        author = {
            username = 'testuser',
            name = 'Test User',
        },
        created_at = '2025-01-01T00:00:00Z',
        resolved = false,
        position = {
            new_path = 'test.lua',
            new_line = 10,
            old_path = 'test.lua',
            old_line = 10,
        },
    }, overrides)
end

--- Create a mock file change structure
--- @param overrides table|nil Optional field overrides
--- @return table File change object
function M.mock_file_change(overrides)
    overrides = overrides or {}
    return vim.tbl_deep_extend('force', {
        new_path = 'test.lua',
        old_path = 'test.lua',
        new_file = false,
        deleted_file = false,
        renamed_file = false,
    }, overrides)
end

--- Create a temporary file with content
--- @param content string File content
--- @param extension string|nil File extension (default: 'txt')
--- @return string File path
function M.create_temp_file(content, extension)
    extension = extension or 'txt'
    local path = vim.fn.tempname() .. '.' .. extension
    local file = io.open(path, 'w')
    if file then
        file:write(content)
        file:close()
    end
    return path
end

--- Create a temporary directory
--- @return string Directory path
function M.create_temp_dir()
    local path = vim.fn.tempname()
    vim.fn.mkdir(path, 'p')
    return path
end

--- Clean up a temporary file or directory
--- @param path string Path to remove
function M.cleanup_temp(path)
    if vim.fn.isdirectory(path) == 1 then
        vim.fn.delete(path, 'rf')
    elseif vim.fn.filereadable(path) == 1 then
        os.remove(path)
    end
end

--- Create a test buffer with content
--- @param lines table List of lines
--- @return number Buffer number
function M.create_test_buffer(lines)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    return buf
end

--- Delete a test buffer
--- @param buf number Buffer number
function M.delete_test_buffer(buf)
    if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
    end
end

--- Assert that a value is a valid error object
--- @param err any Value to check
--- @param expected_type string|nil Expected error type
function M.assert_error(err, expected_type)
    assert.is_table(err, 'Expected error to be a table')
    assert.is_string(err.type, 'Expected error.type to be a string')
    assert.is_string(err.message, 'Expected error.message to be a string')

    if expected_type then
        assert.equals(expected_type, err.type, 'Error type mismatch')
    end
end

--- Assert that a tuple follows the (result, error) pattern
--- @param result any First return value
--- @param err any Second return value
--- @param should_succeed boolean Whether operation should succeed
function M.assert_tuple(result, err, should_succeed)
    if should_succeed then
        assert.is_not_nil(result, 'Expected result to be non-nil on success')
        assert.is_nil(err, 'Expected error to be nil on success')
    else
        assert.is_nil(result, 'Expected result to be nil on failure')
        assert.is_not_nil(err, 'Expected error to be non-nil on failure')
        M.assert_error(err)
    end
end

--- Wait for a condition to be true (with timeout)
--- @param condition function Function that returns boolean
--- @param timeout number Timeout in milliseconds
--- @param interval number|nil Check interval in milliseconds (default: 10)
--- @return boolean Whether condition was met
function M.wait_for(condition, timeout, interval)
    interval = interval or 10
    local start = vim.loop.now()

    while vim.loop.now() - start < timeout do
        if condition() then
            return true
        end
        vim.wait(interval)
    end

    return false
end

--- Capture vim.notify calls
--- @return function Restore function
function M.capture_notify()
    local original = vim.notify
    local captured = {}

    vim.notify = function(msg, level)
        table.insert(captured, { msg = msg, level = level })
    end

    return function()
        vim.notify = original
        return captured
    end
end

--- Mock a function and track its calls
--- @param module table Module to mock
--- @param func_name string Function name to mock
--- @param return_value any Value to return
--- @return function Restore function
function M.mock_function(module, func_name, return_value)
    local original = module[func_name]
    local calls = {}

    module[func_name] = function(...)
        table.insert(calls, { ... })
        if type(return_value) == 'function' then
            return return_value(...)
        else
            return return_value
        end
    end

    return function()
        module[func_name] = original
        return calls
    end
end

--- Create a spy that tracks calls but doesn't change behavior
--- @param module table Module to spy on
--- @param func_name string Function name to spy
--- @return function Restore function
function M.spy_function(module, func_name)
    local original = module[func_name]
    local calls = {}

    module[func_name] = function(...)
        table.insert(calls, { ... })
        return original(...)
    end

    return function()
        module[func_name] = original
        return calls
    end
end

--- Assert that a table contains a key
--- @param tbl table Table to check
--- @param key any Key to find
function M.assert_contains_key(tbl, key)
    assert.is_not_nil(tbl[key], string.format('Expected table to contain key: %s', vim.inspect(key)))
end

--- Assert that a table does not contain a key
--- @param tbl table Table to check
--- @param key any Key to check
function M.assert_not_contains_key(tbl, key)
    assert.is_nil(tbl[key], string.format('Expected table to not contain key: %s', vim.inspect(key)))
end

--- Assert that a list contains a value
--- @param list table List to check
--- @param value any Value to find
function M.assert_contains(list, value)
    for _, item in ipairs(list) do
        if item == value then
            return
        end
    end
    assert.fail(string.format('Expected list to contain value: %s', vim.inspect(value)))
end

--- Assert that a string matches a pattern
--- @param str string String to check
--- @param pattern string Lua pattern
function M.assert_matches_pattern(str, pattern)
    assert.is_true(
        str:match(pattern) ~= nil,
        string.format('Expected "%s" to match pattern "%s"', str, pattern)
    )
end

--- Create a mock plenary job that returns predefined output
--- @param stdout string|table Output lines
--- @param stderr string|table Error lines
--- @param exit_code number Exit code
--- @return table Mock job object
function M.mock_job(stdout, stderr, exit_code)
    if type(stdout) == 'string' then
        stdout = { stdout }
    end
    if type(stderr) == 'string' then
        stderr = { stderr }
    end

    return {
        code = exit_code or 0,
        result = function()
            return stdout
        end,
        stderr_result = function()
            return stderr
        end,
        sync = function() end,
        start = function() end,
        shutdown = function() end,
        is_shutdown = false,
    }
end

return M
