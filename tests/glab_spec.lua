-- tests/glab_spec.lua
-- Tests for glab CLI wrapper module

describe('glab', function()
  local glab = require('mrreviewer.integrations.glab')

  describe('build_mr_list_args', function()
    it('builds args for opened MRs (default)', function()
      local args = glab.build_mr_list_args()
      assert.are.same({
        'mr',
        'list',
        '--output',
        'json',
      }, args)
    end)

    it('builds args for opened MRs (explicit)', function()
      local args = glab.build_mr_list_args('opened')
      assert.are.same({
        'mr',
        'list',
        '--output',
        'json',
      }, args)
    end)

    it('builds args for closed MRs', function()
      local args = glab.build_mr_list_args('closed')
      assert.are.same({
        'mr',
        'list',
        '--output',
        'json',
        '--closed',
      }, args)
    end)

    it('builds args for merged MRs', function()
      local args = glab.build_mr_list_args('merged')
      assert.are.same({
        'mr',
        'list',
        '--output',
        'json',
        '--merged',
      }, args)
    end)

    it('builds args for all MRs', function()
      local args = glab.build_mr_list_args('all')
      assert.are.same({
        'mr',
        'list',
        '--output',
        'json',
        '--all',
      }, args)
    end)
  end)

  describe('build_mr_view_args', function()
    it('builds args without comments', function()
      local args = glab.build_mr_view_args(123, false)
      assert.are.same({
        'mr',
        'view',
        '123',
        '--output',
        'json',
      }, args)
    end)

    it('builds args with comments', function()
      local args = glab.build_mr_view_args(456, true)
      assert.are.same({
        'mr',
        'view',
        '456',
        '--output',
        'json',
        '--comments',
      }, args)
    end)

    it('handles string MR numbers', function()
      local args = glab.build_mr_view_args('789', false)
      assert.are.same({
        'mr',
        'view',
        '789',
        '--output',
        'json',
      }, args)
    end)
  end)

  describe('build_mr_diff_args', function()
    it('builds args for MR diff', function()
      local args = glab.build_mr_diff_args(123)
      assert.are.same({
        'mr',
        'diff',
        '123',
      }, args)
    end)

    it('handles string MR numbers', function()
      local args = glab.build_mr_diff_args('456')
      assert.are.same({
        'mr',
        'diff',
        '456',
      }, args)
    end)
  end)

  describe('check_installation', function()
    it('checks if glab command exists', function()
      -- This test will pass/fail based on whether glab is actually installed
      -- We just verify the function returns boolean and optional error message
      local ok, err = glab.check_installation()
      assert.is_boolean(ok)
      if not ok then
        assert.is_string(err)
        assert.is_true(#err > 0)
        assert.is_true(err:match('glab') ~= nil, 'Error should mention glab')
      else
        assert.is_nil(err)
      end
    end)
  end)

  describe('execute_sync', function()
    -- Note: We test with git commands instead of glab commands
    -- to avoid requiring glab to be installed for tests

    it('executes a simple command successfully', function()
      -- Use git command which we know exists
      local config = require('mrreviewer.core.config')
      -- Temporarily override glab path to use git for testing
      local original_get_value = config.get_value
      config.get_value = function(key)
        if key == 'glab.path' then
          return 'git'
        elseif key == 'glab.timeout' then
          return 5000
        end
        return original_get_value(key)
      end

      local exit_code, stdout, stderr = glab.execute_sync({ '--version' })

      -- Restore original function
      config.get_value = original_get_value

      assert.equals(0, exit_code)
      assert.is_string(stdout)
      assert.is_true(#stdout > 0)
      assert.is_true(stdout:match('git') ~= nil)
    end)

    it('handles failed commands', function()
      local config = require('mrreviewer.core.config')
      local original_get_value = config.get_value
      config.get_value = function(key)
        if key == 'glab.path' then
          return 'git'
        elseif key == 'glab.timeout' then
          return 5000
        end
        return original_get_value(key)
      end

      -- Use an invalid git command that will fail
      local exit_code, stdout, stderr = glab.execute_sync({ 'invalid-command-xyz' })

      config.get_value = original_get_value

      assert.is_not.equals(0, exit_code)
    end)
  end)

  describe('execute_async', function()
    it('executes command asynchronously', function()
      local config = require('mrreviewer.core.config')
      local original_get_value = config.get_value
      config.get_value = function(key)
        if key == 'glab.path' then
          return 'git'
        elseif key == 'glab.timeout' then
          return 5000
        end
        return original_get_value(key)
      end

      local completed = false
      local result_exit_code
      local result_stdout

      glab.execute_async({ '--version' }, function(exit_code, stdout, stderr)
        completed = true
        result_exit_code = exit_code
        result_stdout = stdout
      end)

      -- Wait for async operation to complete (max 2 seconds)
      local max_wait = 200 -- 2 seconds (200 * 10ms)
      local wait_count = 0
      while not completed and wait_count < max_wait do
        vim.wait(10)
        wait_count = wait_count + 1
      end

      config.get_value = original_get_value

      assert.is_true(completed, 'Async operation should complete')
      assert.equals(0, result_exit_code)
      assert.is_string(result_stdout)
      assert.is_true(#result_stdout > 0)
    end)
  end)
end)
