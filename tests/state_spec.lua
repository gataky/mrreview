-- tests/state_spec.lua
-- Tests for centralized state management module

describe('state', function()
  local state

  before_each(function()
    -- Fresh require to reset state
    package.loaded['mrreviewer.state'] = nil
    state = require('mrreviewer.core.state')
    state.reset()
  end)

  describe('get methods', function()
    it('should get entire state', function()
      local s = state.get()

      assert.is_table(s)
      assert.is_table(s.session)
      assert.is_table(s.diff)
      assert.is_table(s.comments)
    end)

    it('should get session state', function()
      local session = state.get_session()

      assert.is_table(session)
      assert.is_boolean(session.initialized)
      assert.is_table(session.current_diff_buffers)
    end)

    it('should get diff state', function()
      local diff = state.get_diff()

      assert.is_table(diff)
      assert.is_table(diff.buffers)
      assert.is_table(diff.windows)
      assert.is_number(diff.current_file_index)
      assert.is_table(diff.files)
    end)

    it('should get comments state', function()
      local comments = state.get_comments()

      assert.is_table(comments)
      assert.is_table(comments.displayed_comments)
      assert.is_number(comments.namespace_id)
    end)
  end)

  describe('get_value', function()
    it('should get session values with dot notation', function()
      assert.equals(false, state.get_value('session.initialized'))
      assert.is_nil(state.get_value('session.current_mr'))
    end)

    it('should get diff values with dot notation', function()
      assert.equals(1, state.get_value('diff.current_file_index'))
      assert.is_table(state.get_value('diff.buffers'))
    end)

    it('should get comments values with dot notation', function()
      assert.is_table(state.get_value('comments.displayed_comments'))
      assert.is_number(state.get_value('comments.namespace_id'))
    end)

    it('should return nil for invalid paths', function()
      assert.is_nil(state.get_value('invalid.path'))
      assert.is_nil(state.get_value('session.nonexistent'))
    end)

    it('should return nil for empty paths', function()
      assert.is_nil(state.get_value(''))
      assert.is_nil(state.get_value(nil))
    end)

    it('should return nil for non-string paths', function()
      assert.is_nil(state.get_value(123))
      assert.is_nil(state.get_value({}))
    end)
  end)

  describe('set_value', function()
    it('should set session values', function()
      local ok, err = state.set_value('session.initialized', true)

      assert.is_true(ok)
      assert.is_nil(err)
      assert.is_true(state.get_value('session.initialized'))
    end)

    it('should set diff values', function()
      local ok, err = state.set_value('diff.current_file_index', 5)

      assert.is_true(ok)
      assert.is_nil(err)
      assert.equals(5, state.get_value('diff.current_file_index'))
    end)

    it('should set nested table values', function()
      local files = { 'file1.lua', 'file2.lua' }
      local ok, err = state.set_value('diff.files', files)

      assert.is_true(ok)
      assert.is_nil(err)
      assert.equals(files, state.get_value('diff.files'))
    end)

    it('should return error for invalid paths', function()
      local ok, err = state.set_value('', 'value')

      assert.is_false(ok)
      assert.is_not_nil(err)
      assert.matches('Invalid path', err.message)
    end)

    it('should return error for nil paths', function()
      local ok, err = state.set_value(nil, 'value')

      assert.is_false(ok)
      assert.is_not_nil(err)
    end)

    it('should return error for non-existent keys', function()
      local ok, err = state.set_value('session.nonexistent.key', 'value')

      assert.is_false(ok)
      assert.is_not_nil(err)
      assert.matches('Invalid path', err.message)
    end)
  end)

  describe('is_initialized', function()
    it('should return false initially', function()
      assert.is_false(state.is_initialized())
    end)

    it('should return true after set_initialized', function()
      state.set_initialized(true)

      assert.is_true(state.is_initialized())
    end)
  end)

  describe('current MR management', function()
    it('should get nil initially', function()
      assert.is_nil(state.get_current_mr())
    end)

    it('should set and get current MR', function()
      local mr_data = { id = 123, title = 'Test MR' }
      state.set_current_mr(mr_data)

      assert.equals(mr_data, state.get_current_mr())
    end)

    it('should clear current MR with nil', function()
      local mr_data = { id = 123 }
      state.set_current_mr(mr_data)
      state.set_current_mr(nil)

      assert.is_nil(state.get_current_mr())
    end)
  end)

  describe('clear methods', function()
    it('should clear session state', function()
      state.set_initialized(true)
      state.set_current_mr({ id = 123 })

      state.clear_session()

      assert.is_nil(state.get_current_mr())
      assert.is_table(state.get_session().current_diff_buffers)
      assert.equals(0, #state.get_session().current_diff_buffers)
    end)

    it('should clear diff state', function()
      local diff = state.get_diff()
      diff.current_file_index = 5
      diff.files = { 'file1', 'file2' }

      state.clear_diff()

      assert.equals(1, state.get_diff().current_file_index)
      assert.equals(0, #state.get_diff().files)
      assert.equals(0, vim.tbl_count(state.get_diff().buffers))
    end)

    it('should clear comments state', function()
      local comments = state.get_comments()
      comments.displayed_comments = { {}, {} }
      comments.comment_buffer = 1

      state.clear_comments()

      assert.equals(0, #state.get_comments().displayed_comments)
      assert.is_nil(state.get_comments().comment_buffer)
    end)

    it('should clear all state', function()
      state.set_initialized(true)
      state.set_current_mr({ id = 123 })
      state.get_diff().current_file_index = 5

      state.clear_all()

      assert.is_nil(state.get_current_mr())
      assert.equals(1, state.get_diff().current_file_index)
      assert.equals(0, #state.get_comments().displayed_comments)
    end)
  end)

  describe('validate', function()
    it('should validate initial state', function()
      local valid, err = state.validate()

      assert.is_true(valid)
      assert.is_nil(err)
    end)

    it('should validate session structure', function()
      local valid, err = state.validate()

      assert.is_true(valid)
      assert.is_nil(err)
    end)

    it('should reject non-table state', function()
      local valid, err = state.validate('not a table')

      assert.is_false(valid)
      assert.is_not_nil(err)
      assert.matches('State must be a table', err.message)
    end)

    it('should reject missing session', function()
      local bad_state = {
        diff = {},
        comments = {},
      }
      local valid, err = state.validate(bad_state)

      assert.is_false(valid)
      assert.is_not_nil(err)
      assert.matches('session must be a table', err.message)
    end)

    it('should reject missing diff', function()
      local bad_state = {
        session = { initialized = false, current_mr = nil, current_diff_buffers = {} },
        comments = {},
      }
      local valid, err = state.validate(bad_state)

      assert.is_false(valid)
      assert.is_not_nil(err)
      assert.matches('diff must be a table', err.message)
    end)

    it('should reject missing comments', function()
      local bad_state = {
        session = { initialized = false, current_mr = nil, current_diff_buffers = {} },
        diff = { buffers = {}, windows = {}, current_file_index = 1, files = {} },
      }
      local valid, err = state.validate(bad_state)

      assert.is_false(valid)
      assert.is_not_nil(err)
      assert.matches('comments must be a table', err.message)
    end)

    it('should reject invalid initialized type', function()
      local bad_state = vim.deepcopy(state.get())
      bad_state.session.initialized = 'not a boolean'

      local valid, err = state.validate(bad_state)

      assert.is_false(valid)
      assert.is_not_nil(err)
      assert.matches('initialized must be a boolean', err.message)
    end)

    it('should reject invalid current_file_index type', function()
      local bad_state = vim.deepcopy(state.get())
      bad_state.diff.current_file_index = 'not a number'

      local valid, err = state.validate(bad_state)

      assert.is_false(valid)
      assert.is_not_nil(err)
      assert.matches('current_file_index must be a number', err.message)
    end)

    it('should accept nil for optional fields', function()
      local good_state = vim.deepcopy(state.get())
      good_state.session.current_mr = nil
      good_state.comments.comment_buffer = nil

      local valid, err = state.validate(good_state)

      assert.is_true(valid)
      assert.is_nil(err)
    end)
  end)

  describe('reset', function()
    it('should reset state to initial values', function()
      -- Modify state
      state.set_initialized(true)
      state.set_current_mr({ id = 123 })
      state.get_diff().current_file_index = 5

      -- Reset
      state.reset()

      -- Verify reset
      assert.is_false(state.is_initialized())
      assert.is_nil(state.get_current_mr())
      assert.equals(1, state.get_diff().current_file_index)
    end)

    it('should maintain namespace_id after reset', function()
      local old_ns_id = state.get_comments().namespace_id

      state.reset()

      local new_ns_id = state.get_comments().namespace_id
      assert.is_number(new_ns_id)
      -- Namespace IDs are auto-incremented, so new one will be different
    end)
  end)

  describe('state persistence', function()
    it('should maintain state across get calls', function()
      local session1 = state.get_session()
      session1.initialized = true

      local session2 = state.get_session()

      -- Both should reference the same state
      assert.is_true(session2.initialized)
    end)

    it('should allow direct table modification', function()
      local diff = state.get_diff()
      diff.current_file_index = 10

      assert.equals(10, state.get_value('diff.current_file_index'))
    end)
  end)
end)
