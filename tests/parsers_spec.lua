-- tests/parsers_spec.lua
-- Tests for JSON parsing functions

describe('parsers', function()
  local parsers = require('mrreviewer.parsers')

  describe('parse_mr_list', function()
    it('parses valid MR list JSON', function()
      local json_str = [[
        [
          {
            "iid": 123,
            "title": "Test MR",
            "state": "opened",
            "author": {"username": "testuser", "name": "Test User"},
            "source_branch": "feature-branch",
            "target_branch": "main",
            "created_at": "2024-01-01T00:00:00Z"
          }
        ]
      ]]

      local mrs, err = parsers.parse_mr_list(json_str)

      assert.is_nil(err)
      assert.is_not_nil(mrs)
      assert.equals(1, #mrs)
      assert.equals(123, mrs[1].iid)
      assert.equals('Test MR', mrs[1].title)
      assert.equals('testuser', mrs[1].author.username)
    end)

    it('handles empty MR list', function()
      local json_str = '[]'
      local mrs, err = parsers.parse_mr_list(json_str)

      assert.is_nil(err)
      assert.is_not_nil(mrs)
      assert.equals(0, #mrs)
    end)

    it('handles invalid JSON', function()
      local mrs, err = parsers.parse_mr_list('not json')
      assert.is_nil(mrs)
      assert.is_not_nil(err)
    end)
  end)

  describe('filter_comments_by_file', function()
    it('filters comments by file path', function()
      local comments = {
        {
          id = 1,
          body = 'Comment 1',
          position = { new_path = 'file1.lua' },
        },
        {
          id = 2,
          body = 'Comment 2',
          position = { new_path = 'file2.lua' },
        },
        {
          id = 3,
          body = 'Comment 3',
          position = { new_path = 'file1.lua' },
        },
      }

      local filtered = parsers.filter_comments_by_file(comments, 'file1.lua')

      assert.equals(2, #filtered)
      assert.equals(1, filtered[1].id)
      assert.equals(3, filtered[2].id)
    end)

    it('returns empty table when no matches', function()
      local comments = {
        {
          id = 1,
          body = 'Comment 1',
          position = { new_path = 'file1.lua' },
        },
      }

      local filtered = parsers.filter_comments_by_file(comments, 'file2.lua')
      assert.equals(0, #filtered)
    end)
  end)

  describe('sort_comments_by_line', function()
    it('sorts comments by line number', function()
      local comments = {
        {
          id = 1,
          position = { new_line = 30 },
        },
        {
          id = 2,
          position = { new_line = 10 },
        },
        {
          id = 3,
          position = { new_line = 20 },
        },
      }

      local sorted = parsers.sort_comments_by_line(comments)

      assert.equals(2, sorted[1].id)
      assert.equals(3, sorted[2].id)
      assert.equals(1, sorted[3].id)
    end)
  end)
end)
