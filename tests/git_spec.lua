-- tests/git_spec.lua
-- Tests for git operations module

describe('git', function()
  local git = require('mrreviewer.git')

  -- We're running tests in a git repository, so we can test actual operations
  local test_repo_root = vim.fn.getcwd()

  describe('get_current_branch', function()
    it('returns the current branch name', function()
      local branch = git.get_current_branch()
      assert.is_not_nil(branch)
      assert.is_string(branch)
      -- Branch name should not be empty and should not have whitespace
      assert.is_true(#branch > 0)
      assert.is_nil(branch:match('%s'))
    end)

    it('returns nil for non-git directories', function()
      local branch = git.get_current_branch('/tmp')
      assert.is_nil(branch)
    end)
  end)

  describe('is_git_repo', function()
    it('returns true for the test repository', function()
      local is_repo = git.is_git_repo()
      assert.is_true(is_repo)
    end)

    it('returns true when cwd is explicitly provided', function()
      local is_repo = git.is_git_repo(test_repo_root)
      assert.is_true(is_repo)
    end)

    it('returns false for non-git directories', function()
      local is_repo = git.is_git_repo('/tmp')
      assert.is_false(is_repo)
    end)

    it('returns false for non-existent directories', function()
      local is_repo = git.is_git_repo('/nonexistent/path/that/does/not/exist')
      assert.is_false(is_repo)
    end)
  end)

  describe('get_repo_root', function()
    it('returns the repository root directory', function()
      local root = git.get_repo_root()
      assert.is_not_nil(root)
      assert.is_string(root)
      assert.is_true(#root > 0)
      -- Root should be an absolute path
      assert.is_true(root:sub(1, 1) == '/')
    end)

    it('returns consistent root from subdirectories', function()
      local root1 = git.get_repo_root(test_repo_root)
      local root2 = git.get_repo_root(test_repo_root .. '/lua')
      assert.equals(root1, root2)
    end)

    it('returns nil for non-git directories', function()
      local root = git.get_repo_root('/tmp')
      assert.is_nil(root)
    end)
  end)

  describe('get_remote_url', function()
    it('returns remote URL for default remote (origin)', function()
      local url = git.get_remote_url()
      -- May return nil if origin doesn't exist, but if it does it should be a string
      if url then
        assert.is_string(url)
        assert.is_true(#url > 0)
        -- Should contain git or http(s) protocol indicators
        assert.is_true(
          url:match('git@') ~= nil or url:match('https?://') ~= nil,
          'URL should contain git@ or http(s)://'
        )
      end
    end)

    it('accepts custom remote name', function()
      -- This will return nil if the remote doesn't exist, which is fine
      local url = git.get_remote_url('upstream')
      if url then
        assert.is_string(url)
        assert.is_true(#url > 0)
      end
    end)

    it('returns nil for non-existent remote', function()
      local url = git.get_remote_url('nonexistent_remote_xyz')
      assert.is_nil(url)
    end)

    it('returns nil for non-git directories', function()
      local url = git.get_remote_url('origin', '/tmp')
      assert.is_nil(url)
    end)
  end)

  describe('get_upstream_branch', function()
    it('returns upstream branch or nil', function()
      local upstream = git.get_upstream_branch()
      -- May be nil if no upstream is set, which is valid
      if upstream then
        assert.is_string(upstream)
        assert.is_true(#upstream > 0)
        -- Upstream typically has format: remote/branch
        assert.is_true(upstream:match('/') ~= nil, 'Upstream should contain /')
      end
    end)

    it('returns nil for non-git directories', function()
      local upstream = git.get_upstream_branch('/tmp')
      assert.is_nil(upstream)
    end)
  end)

  describe('command_exists', function()
    it('returns true for git command', function()
      local exists = git.command_exists('git')
      assert.is_true(exists)
    end)

    it('returns true for common unix commands', function()
      local exists = git.command_exists('ls')
      assert.is_true(exists)
    end)

    it('returns false for non-existent commands', function()
      local exists = git.command_exists('nonexistent_command_xyz_12345')
      assert.is_false(exists)
    end)

    it('handles empty string', function()
      local exists = git.command_exists('')
      assert.is_false(exists)
    end)
  end)

  describe('error handling', function()
    it('handles git operations gracefully with invalid cwd', function()
      -- These should not throw errors, just return nil/false
      local branch = git.get_current_branch('/nonexistent/path')
      local is_repo = git.is_git_repo('/nonexistent/path')
      local root = git.get_repo_root('/nonexistent/path')
      local url = git.get_remote_url('origin', '/nonexistent/path')

      assert.is_nil(branch)
      assert.is_false(is_repo)
      assert.is_nil(root)
      assert.is_nil(url)
    end)
  end)

  describe('return value trimming', function()
    it('returns trimmed strings without trailing newlines', function()
      local branch = git.get_current_branch()
      if branch then
        -- Should not have any leading/trailing whitespace
        assert.equals(branch, branch:match('^%s*(.-)%s*$'))
      end

      local root = git.get_repo_root()
      if root then
        assert.equals(root, root:match('^%s*(.-)%s*$'))
      end

      local url = git.get_remote_url()
      if url then
        assert.equals(url, url:match('^%s*(.-)%s*$'))
      end
    end)
  end)
end)
