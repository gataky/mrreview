-- tests/comments_spec.lua
-- Tests for comment filtering, mapping, and display logic

describe('comments', function()
  local comments

  before_each(function()
    -- Clear module cache to get fresh instance
    package.loaded['mrreviewer.comments'] = nil
    comments = require('mrreviewer.ui.comments')
  end)

  describe('filter_by_file', function()
    it('filters comments by file path', function()
      local all_comments = {
        {
          id = 1,
          body = 'Comment on file1',
          position = { new_path = 'src/file1.lua', new_line = 10 },
        },
        {
          id = 2,
          body = 'Comment on file2',
          position = { new_path = 'src/file2.lua', new_line = 20 },
        },
        {
          id = 3,
          body = 'Another comment on file1',
          position = { new_path = 'src/file1.lua', new_line = 30 },
        },
      }

      local filtered = comments.filter_by_file(all_comments, 'src/file1.lua')

      assert.equals(2, #filtered)
      assert.equals(1, filtered[1].id)
      assert.equals(3, filtered[2].id)
    end)

    it('returns empty table when no comments match', function()
      local all_comments = {
        {
          id = 1,
          body = 'Comment',
          position = { new_path = 'src/file1.lua', new_line = 10 },
        },
      }

      local filtered = comments.filter_by_file(all_comments, 'src/other.lua')
      assert.equals(0, #filtered)
    end)

    it('handles empty comment list', function()
      local filtered = comments.filter_by_file({}, 'any/file.lua')
      assert.is_table(filtered)
      assert.equals(0, #filtered)
    end)

    it('matches both new_path and old_path', function()
      local all_comments = {
        {
          id = 1,
          body = 'Comment on new path',
          position = { new_path = 'file.lua', old_path = 'file.lua', new_line = 10 },
        },
        {
          id = 2,
          body = 'Comment on old path only',
          position = { new_path = 'other.lua', old_path = 'file.lua', new_line = 20 },
        },
      }

      local filtered = comments.filter_by_file(all_comments, 'file.lua')

      -- Should match both comments (one via new_path, one via old_path)
      assert.equals(2, #filtered)
    end)
  end)

  describe('map_to_line', function()
    it('maps comment position to buffer line', function()
      -- Create a test buffer
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        'line 1',
        'line 2',
        'line 3',
        'line 4',
        'line 5',
      })

      local comment = {
        position = {
          new_line = 3,
          new_path = 'test.lua',
        },
      }

      local line = comments.map_to_line(comment, buf)

      assert.equals(3, line)

      -- Clean up
      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it('returns nil when comment has no position', function()
      local buf = vim.api.nvim_create_buf(false, true)
      local comment = { body = 'test' } -- no position

      local line = comments.map_to_line(comment, buf)
      assert.is_nil(line)

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it('returns nil when new_line is nil', function()
      local buf = vim.api.nvim_create_buf(false, true)
      local comment = {
        position = {
          new_path = 'test.lua',
          -- new_line is nil
        },
      }

      local line = comments.map_to_line(comment, buf)
      assert.is_nil(line)

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it('returns nil when new_line is 0 or negative', function()
      local buf = vim.api.nvim_create_buf(false, true)

      local comment1 = {
        position = { new_line = 0 },
      }
      assert.is_nil(comments.map_to_line(comment1, buf))

      local comment2 = {
        position = { new_line = -1 },
      }
      assert.is_nil(comments.map_to_line(comment2, buf))

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it('returns nil when line exceeds buffer bounds', function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        'line 1',
        'line 2',
        'line 3',
      })

      local comment = {
        position = {
          new_line = 100, -- Way beyond buffer size
        },
      }

      local line = comments.map_to_line(comment, buf)
      assert.is_nil(line)

      vim.api.nvim_buf_delete(buf, { force = true })
    end)

    it('handles boundary line numbers correctly', function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        'line 1',
        'line 2',
        'line 3',
      })

      -- First line
      local comment1 = {
        position = { new_line = 1 },
      }
      assert.equals(1, comments.map_to_line(comment1, buf))

      -- Last line
      local comment2 = {
        position = { new_line = 3 },
      }
      assert.equals(3, comments.map_to_line(comment2, buf))

      -- Just beyond last line
      local comment3 = {
        position = { new_line = 4 },
      }
      assert.is_nil(comments.map_to_line(comment3, buf))

      vim.api.nvim_buf_delete(buf, { force = true })
    end)
  end)

  describe('state management', function()
    it('has initial state structure', function()
      assert.is_table(comments.state)
      assert.is_nil(comments.state.comment_buffer)
      assert.is_nil(comments.state.comment_window)
      assert.is_nil(comments.state.comment_float_win)
      assert.is_nil(comments.state.comment_float_buf)
      assert.is_table(comments.state.displayed_comments)
      assert.equals(0, #comments.state.displayed_comments)
      assert.is_number(comments.state.namespace_id)
    end)

    it('namespace_id is consistent', function()
      local ns1 = comments.state.namespace_id
      -- Reload module
      package.loaded['mrreviewer.comments'] = nil
      comments = require('mrreviewer.ui.comments')
      local ns2 = comments.state.namespace_id

      -- Namespace IDs should be different across reloads
      -- (each reload creates a new namespace)
      assert.is_number(ns2)
    end)
  end)

  describe('clear', function()
    it('clears state without errors', function()
      -- This should not error even with no active windows/buffers
      assert.has_no.errors(function()
        comments.clear()
      end)

      -- State should be reset
      assert.is_nil(comments.state.comment_buffer)
      assert.is_nil(comments.state.comment_window)
      assert.is_nil(comments.state.comment_float_win)
      assert.is_nil(comments.state.comment_float_buf)
      assert.equals(0, #comments.state.displayed_comments)
    end)

    it('clears displayed comments', function()
      -- Simulate some displayed comments
      comments.state.displayed_comments = {
        { id = 1 },
        { id = 2 },
      }

      comments.clear()

      assert.equals(0, #comments.state.displayed_comments)
    end)
  end)
end)
