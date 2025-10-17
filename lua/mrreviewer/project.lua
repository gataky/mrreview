-- lua/mrreviewer/project.lua
-- Git/GitLab project detection and metadata

local M = {}
local utils = require('mrreviewer.utils')

--- Get git remote URL
--- @param remote_name string|nil Remote name (default: 'origin')
--- @return string|nil Remote URL or nil if not found
function M.get_remote_url(remote_name)
  remote_name = remote_name or 'origin'

  local handle = io.popen('git remote get-url ' .. remote_name .. ' 2>/dev/null')
  if not handle then
    return nil
  end

  local url = handle:read('*a')
  handle:close()

  if utils.is_empty(url) then
    return nil
  end

  return utils.trim(url)
end

--- Parse GitLab project information from remote URL
--- @param url string Git remote URL
--- @return table|nil Project info with host, namespace, and name fields
function M.parse_gitlab_url(url)
  if utils.is_empty(url) then
    return nil
  end

  local host, namespace, name

  -- Try HTTPS format: https://gitlab.example.com/namespace/project.git
  host, namespace, name = url:match('https?://([^/]+)/([^/]+)/([^/%.]+)')
  if host and namespace and name then
    return {
      host = host,
      namespace = namespace,
      name = name,
      full_path = namespace .. '/' .. name,
    }
  end

  -- Try SSH format: git@gitlab.example.com:namespace/project.git
  host, namespace, name = url:match('git@([^:]+):([^/]+)/([^/%.]+)')
  if host and namespace and name then
    return {
      host = host,
      namespace = namespace,
      name = name,
      full_path = namespace .. '/' .. name,
    }
  end

  -- Try SSH format with .git suffix
  host, namespace, name = url:match('git@([^:]+):([^/]+)/(.+)%.git$')
  if host and namespace and name then
    return {
      host = host,
      namespace = namespace,
      name = name,
      full_path = namespace .. '/' .. name,
    }
  end

  -- Try HTTPS format with .git suffix
  host, namespace, name = url:match('https?://([^/]+)/([^/]+)/(.+)%.git$')
  if host and namespace and name then
    return {
      host = host,
      namespace = namespace,
      name = name,
      full_path = namespace .. '/' .. name,
    }
  end

  return nil
end

--- Get GitLab project information from current git repository
--- @param remote_name string|nil Remote name (default: 'origin')
--- @return table|nil, string|nil Project info or nil and error message
function M.get_project_info(remote_name)
  -- Check if we're in a git repository
  if not utils.is_git_repo() then
    return nil, 'Not in a git repository'
  end

  -- Get remote URL
  local url = M.get_remote_url(remote_name)
  if not url then
    return nil, 'Failed to get git remote URL for remote: ' .. (remote_name or 'origin')
  end

  -- Parse GitLab project info
  local project_info = M.parse_gitlab_url(url)
  if not project_info then
    return nil, 'Failed to parse GitLab project information from URL: ' .. url
  end

  -- Validate it looks like a GitLab URL
  if not project_info.host:match('gitlab') then
    return nil, 'Remote URL does not appear to be a GitLab repository: ' .. url
  end

  return project_info, nil
end

--- Get current git repository root directory
--- @return string|nil Root directory path or nil
function M.get_repo_root()
  local handle = io.popen('git rev-parse --show-toplevel 2>/dev/null')
  if not handle then
    return nil
  end

  local root = handle:read('*a')
  handle:close()

  if utils.is_empty(root) then
    return nil
  end

  return utils.trim(root)
end

--- Get current git branch name
--- @return string|nil Branch name or nil
function M.get_current_branch()
  return utils.get_current_branch()
end

--- Get the base/target branch for the current branch
--- This attempts to detect the target branch from git tracking info
--- @return string|nil Target branch name or nil (defaults to 'main')
function M.get_target_branch()
  -- Try to get upstream tracking branch
  local handle = io.popen('git rev-parse --abbrev-ref @{upstream} 2>/dev/null')
  if not handle then
    return 'main'
  end

  local upstream = handle:read('*a')
  handle:close()

  if not utils.is_empty(upstream) then
    -- Extract branch name from remote/branch format
    local branch = upstream:match('[^/]+/(.+)')
    if branch then
      return utils.trim(branch)
    end
  end

  -- Default to main if no upstream
  return 'main'
end

return M
