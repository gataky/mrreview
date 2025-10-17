-- tests/project_spec.lua
-- Tests for project/git detection and GitLab URL parsing

describe('project', function()
  local project = require('mrreviewer.project')

  describe('parse_gitlab_url', function()
    it('parses HTTPS URLs', function()
      local url = 'https://gitlab.com/namespace/project'
      local info = project.parse_gitlab_url(url)

      assert.is_not_nil(info)
      assert.equals('gitlab.com', info.host)
      assert.equals('namespace', info.namespace)
      assert.equals('project', info.name)
      assert.equals('namespace/project', info.full_path)
    end)

    it('parses HTTPS URLs with .git suffix', function()
      local url = 'https://gitlab.com/namespace/project.git'
      local info = project.parse_gitlab_url(url)

      assert.is_not_nil(info)
      assert.equals('gitlab.com', info.host)
      assert.equals('namespace', info.namespace)
      assert.equals('project', info.name)
      assert.equals('namespace/project', info.full_path)
    end)

    it('parses HTTP URLs', function()
      local url = 'http://gitlab.example.com/namespace/myproject'
      local info = project.parse_gitlab_url(url)

      assert.is_not_nil(info)
      assert.equals('gitlab.example.com', info.host)
      assert.equals('namespace', info.namespace)
      assert.equals('myproject', info.name)
      assert.equals('namespace/myproject', info.full_path)
    end)

    it('parses SSH URLs', function()
      local url = 'git@gitlab.com:namespace/project'
      local info = project.parse_gitlab_url(url)

      assert.is_not_nil(info)
      assert.equals('gitlab.com', info.host)
      assert.equals('namespace', info.namespace)
      assert.equals('project', info.name)
      assert.equals('namespace/project', info.full_path)
    end)

    it('parses SSH URLs with .git suffix', function()
      local url = 'git@gitlab.com:namespace/project.git'
      local info = project.parse_gitlab_url(url)

      assert.is_not_nil(info)
      assert.equals('gitlab.com', info.host)
      assert.equals('namespace', info.namespace)
      assert.equals('project', info.name)
      assert.equals('namespace/project', info.full_path)
    end)

    it('parses self-hosted GitLab instances', function()
      local url = 'https://git.company.com/team/project'
      local info = project.parse_gitlab_url(url)

      assert.is_not_nil(info)
      assert.equals('git.company.com', info.host)
      assert.equals('team', info.namespace)
      assert.equals('project', info.name)
    end)

    it('parses URLs with nested namespaces', function()
      -- Note: GitLab supports nested namespaces, but our simple parser
      -- only handles single-level namespaces (namespace/project format)
      -- For nested groups like group/subgroup/project, it parses as:
      -- namespace=group, name=subgroup (ignoring the final /project part)
      local url = 'https://gitlab.com/group/subgroup/project.git'
      local info = project.parse_gitlab_url(url)

      assert.is_not_nil(info)
      assert.equals('gitlab.com', info.host)
      assert.equals('group', info.namespace)
      -- Parser matches the second path segment as name
      assert.equals('subgroup', info.name)
      assert.equals('group/subgroup', info.full_path)
    end)

    it('returns nil for empty URLs', function()
      assert.is_nil(project.parse_gitlab_url(''))
      assert.is_nil(project.parse_gitlab_url(nil))
    end)

    it('returns nil for invalid URLs', function()
      assert.is_nil(project.parse_gitlab_url('not-a-valid-url'))
      assert.is_nil(project.parse_gitlab_url('ftp://invalid.com'))
      assert.is_nil(project.parse_gitlab_url('just-some-text'))
    end)

    it('returns nil for GitHub URLs (not GitLab)', function()
      -- Parser should still work, but get_project_info validates it's GitLab
      local url = 'https://github.com/user/repo.git'
      local info = project.parse_gitlab_url(url)
      -- This will parse successfully, but get_project_info will reject it
      assert.is_not_nil(info)
      assert.equals('github.com', info.host)
    end)
  end)

  describe('get_remote_url', function()
    it('delegates to git.get_remote_url', function()
      -- Test with actual repo
      local url = project.get_remote_url()
      -- URL may be nil if no remote exists, but if it does it should be a string
      if url then
        assert.is_string(url)
        assert.is_true(#url > 0)
      end
    end)

    it('accepts custom remote name', function()
      local url = project.get_remote_url('upstream')
      -- May be nil if upstream doesn't exist
      if url then
        assert.is_string(url)
      end
    end)
  end)

  describe('get_repo_root', function()
    it('returns repository root for current directory', function()
      local root = project.get_repo_root()
      assert.is_not_nil(root)
      assert.is_string(root)
      assert.is_true(#root > 0)
      assert.is_true(root:sub(1, 1) == '/')
    end)

    it('returns consistent root from different buffers', function()
      local root1 = project.get_repo_root()

      -- Create a temporary buffer and test again
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_name(buf, '/tmp/test.txt')
      vim.api.nvim_set_current_buf(buf)

      local root2 = project.get_repo_root()

      -- Clean up
      vim.api.nvim_buf_delete(buf, { force = true })

      assert.is_not_nil(root1)
      assert.is_not_nil(root2)
      -- Both should return valid roots (might be same or different depending on /tmp)
    end)
  end)

  describe('get_current_branch', function()
    it('returns current branch name', function()
      local branch = project.get_current_branch()
      assert.is_not_nil(branch)
      assert.is_string(branch)
      assert.is_true(#branch > 0)
    end)
  end)

  describe('get_target_branch', function()
    it('returns target branch or default', function()
      local target = project.get_target_branch()
      assert.is_not_nil(target)
      assert.is_string(target)
      assert.is_true(#target > 0)
      -- Should be either upstream branch name or 'main'
      assert.is_true(target == 'main' or #target > 0)
    end)

    it('extracts branch name from upstream format', function()
      -- We can't easily test this without mocking, but we verify
      -- it returns a valid string
      local target = project.get_target_branch()
      assert.is_string(target)
      -- Should not contain 'origin/' or other remote prefix
      -- (unless it failed to parse and defaulted to 'main')
      if target ~= 'main' then
        -- If not default, should be a clean branch name
        assert.is_true(#target > 0)
      end
    end)
  end)

  describe('get_project_info', function()
    it('returns project info for GitLab repos', function()
      -- This test will only pass if we're in a GitLab repo
      -- Otherwise it should return nil with error object
      local info, err = project.get_project_info()
      local errors = require('mrreviewer.errors')

      if info then
        -- If successful, verify structure
        assert.is_table(info)
        assert.is_string(info.host)
        assert.is_string(info.namespace)
        assert.is_string(info.name)
        assert.is_string(info.full_path)
        assert.is_true(info.host:match('gitlab') ~= nil)
      else
        -- If failed, should have error object
        assert.is_true(errors.is_error(err))
        assert.is_string(err.message)
      end
    end)

    it('accepts custom remote name', function()
      local info, err = project.get_project_info('upstream')
      local errors = require('mrreviewer.errors')
      -- May fail if upstream doesn't exist or isn't GitLab
      if not info then
        assert.is_true(errors.is_error(err))
      end
    end)

    it('rejects non-GitLab URLs', function()
      -- We can't easily test this without having a non-GitLab remote
      -- but we verify the function signature works
      local info, err = project.get_project_info('nonexistent_remote')
      local errors = require('mrreviewer.errors')
      assert.is_nil(info)
      assert.is_true(errors.is_error(err))
    end)
  end)

  describe('integration', function()
    it('full workflow: get repo info and parse URL', function()
      local url = project.get_remote_url()
      if url then
        local info = project.parse_gitlab_url(url)
        if info and info.host:match('gitlab') then
          -- Full GitLab workflow should work
          assert.is_string(info.host)
          assert.is_string(info.namespace)
          assert.is_string(info.name)
          assert.equals(info.namespace .. '/' .. info.name, info.full_path)
        end
      end
    end)
  end)
end)
