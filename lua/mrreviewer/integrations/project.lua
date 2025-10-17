-- lua/mrreviewer/project.lua
-- Git/GitLab project detection and metadata

local M = {}
local utils = require('mrreviewer.lib.utils')
local errors = require('mrreviewer.core.errors')

--- Get git remote URL
--- @param remote_name string|nil Remote name (default: 'origin')
--- @return string|nil, table|nil Remote URL or nil, and error object or nil
function M.get_remote_url(remote_name)
  local git = require('mrreviewer.integrations.git')
  return git.get_remote_url(remote_name)
end

--- Parse GitLab project information from remote URL
--- @param url string Git remote URL
--- @return table|nil, table|nil Project info or nil, and error object or nil
function M.parse_gitlab_url(url)
  if utils.is_empty(url) then
    return nil, errors.parse_error('Empty or nil URL provided')
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
    }, nil
  end

  -- Try SSH format: git@gitlab.example.com:namespace/project.git
  host, namespace, name = url:match('git@([^:]+):([^/]+)/([^/%.]+)')
  if host and namespace and name then
    return {
      host = host,
      namespace = namespace,
      name = name,
      full_path = namespace .. '/' .. name,
    }, nil
  end

  -- Try SSH format with .git suffix
  host, namespace, name = url:match('git@([^:]+):([^/]+)/(.+)%.git$')
  if host and namespace and name then
    return {
      host = host,
      namespace = namespace,
      name = name,
      full_path = namespace .. '/' .. name,
    }, nil
  end

  -- Try HTTPS format with .git suffix
  host, namespace, name = url:match('https?://([^/]+)/([^/]+)/(.+)%.git$')
  if host and namespace and name then
    return {
      host = host,
      namespace = namespace,
      name = name,
      full_path = namespace .. '/' .. name,
    }, nil
  end

  return nil, errors.parse_error('Failed to parse GitLab URL', {
    url = url,
    suggestion = 'URL must be in format: https://gitlab.com/namespace/project or git@gitlab.com:namespace/project',
  })
end

--- Get GitLab project information from current git repository
--- @param remote_name string|nil Remote name (default: 'origin')
--- @return table|nil, table|nil Project info or nil, and error object or nil
function M.get_project_info(remote_name)
  -- Check if we're in a git repository
  if not utils.is_git_repo() then
    return nil, errors.validation_error('Not in a git repository', {
      suggestion = 'Navigate to a git repository or initialize one with git init',
    })
  end

  -- Get remote URL
  local url, err = M.get_remote_url(remote_name)
  if not url then
    return nil, errors.wrap('Failed to get git remote URL for ' .. (remote_name or 'origin'), err)
  end

  -- Parse GitLab project info
  local project_info, parse_err = M.parse_gitlab_url(url)
  if not project_info then
    return nil, errors.wrap('Failed to parse GitLab project information', parse_err)
  end

  -- Validate it looks like a GitLab URL
  if not project_info.host:match('gitlab') then
    return nil, errors.validation_error('Remote URL does not appear to be a GitLab repository', {
      url = url,
      host = project_info.host,
      suggestion = 'Ensure your git remote points to a GitLab instance',
    })
  end

  return project_info, nil
end

--- Get current git repository root directory
--- Tries to detect from current buffer's file path first, then falls back to cwd
--- @return string|nil, table|nil Root directory path or nil, and error object or nil
function M.get_repo_root()
  local git = require('mrreviewer.integrations.git')

  -- First try to get repo root from current buffer's file path
  local current_file = vim.api.nvim_buf_get_name(0)

  -- Skip MRReviewer virtual buffers
  if current_file and current_file ~= '' and not current_file:match('^MRReviewer://') then
    -- Get directory of current file
    local file_dir = vim.fn.fnamemodify(current_file, ':h')

    -- Check if this directory is in a git repo
    local root, err = git.get_repo_root(file_dir)
    if root then
      return root, nil
    end
  end

  -- Fall back to current working directory
  return git.get_repo_root()
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
  local git = require('mrreviewer.integrations.git')

  -- Try to get upstream tracking branch
  local upstream = git.get_upstream_branch()

  if upstream then
    -- Extract branch name from remote/branch format
    local branch = upstream:match('[^/]+/(.+)')
    if branch then
      return branch
    end
  end

  -- Default to main if no upstream
  return 'main'
end

return M
