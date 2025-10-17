-- lua/mrreviewer/git.lua
-- Git operations using plenary.job for safe async execution
-- Replaces unsafe io.popen() calls throughout the codebase

local M = {}
local Job = require('plenary.job')

--- Execute a git command synchronously
--- @param args table Git command arguments (e.g., {'rev-parse', '--abbrev-ref', 'HEAD'})
--- @param opts table|nil Options: cwd (string), timeout (number in ms, default 5000)
--- @return boolean, string|nil Success status and result/error message
local function git_exec(args, opts)
  opts = opts or {}
  local timeout = opts.timeout or 5000
  local cwd = opts.cwd

  local job_opts = {
    command = 'git',
    args = args,
    cwd = cwd,
  }

  local job = Job:new(job_opts)

  local ok, result = pcall(function()
    job:sync(timeout)
    return job:result()
  end)

  if not ok then
    return false, 'Git command failed: ' .. tostring(result)
  end

  if job.code ~= 0 then
    local stderr = table.concat(job:stderr_result() or {}, '\n')
    return false, stderr ~= '' and stderr or 'Git command exited with code ' .. job.code
  end

  local stdout = table.concat(result or {}, '\n')
  return true, stdout
end

--- Get current git branch name
--- @param cwd string|nil Working directory (defaults to current)
--- @return string|nil Branch name or nil if not in a git repo
function M.get_current_branch(cwd)
  local ok, result = git_exec({ 'rev-parse', '--abbrev-ref', 'HEAD' }, { cwd = cwd })

  if not ok then
    return nil
  end

  -- Trim whitespace
  result = result:match('^%s*(.-)%s*$')

  if result == '' then
    return nil
  end

  return result
end

--- Check if currently in a git repository
--- @param cwd string|nil Working directory (defaults to current)
--- @return boolean True if inside a git repository
function M.is_git_repo(cwd)
  local ok, result = git_exec({ 'rev-parse', '--is-inside-work-tree' }, { cwd = cwd })

  if not ok then
    return false
  end

  -- Trim whitespace
  result = result:match('^%s*(.-)%s*$')

  return result == 'true'
end

--- Get git repository root directory
--- @param cwd string|nil Working directory to check (defaults to current)
--- @return string|nil Root directory path or nil if not in a repo
function M.get_repo_root(cwd)
  local ok, result = git_exec({ 'rev-parse', '--show-toplevel' }, { cwd = cwd })

  if not ok then
    return nil
  end

  -- Trim whitespace
  result = result:match('^%s*(.-)%s*$')

  if result == '' then
    return nil
  end

  return result
end

--- Get git remote URL
--- @param remote_name string|nil Remote name (default: 'origin')
--- @param cwd string|nil Working directory (defaults to current)
--- @return string|nil Remote URL or nil if not found
function M.get_remote_url(remote_name, cwd)
  remote_name = remote_name or 'origin'

  local ok, result = git_exec({ 'remote', 'get-url', remote_name }, { cwd = cwd })

  if not ok then
    return nil
  end

  -- Trim whitespace
  result = result:match('^%s*(.-)%s*$')

  if result == '' then
    return nil
  end

  return result
end

--- Get the upstream tracking branch for current branch
--- @param cwd string|nil Working directory (defaults to current)
--- @return string|nil Upstream branch name or nil
function M.get_upstream_branch(cwd)
  local ok, result = git_exec({ 'rev-parse', '--abbrev-ref', '@{upstream}' }, { cwd = cwd })

  if not ok then
    return nil
  end

  -- Trim whitespace
  result = result:match('^%s*(.-)%s*$')

  if result == '' then
    return nil
  end

  return result
end

--- Check if a command exists in PATH
--- Used for checking if glab CLI is installed
--- @param command string Command name to check
--- @return boolean True if command exists
function M.command_exists(command)
  local job = Job:new({
    command = 'command',
    args = { '-v', command },
  })

  local ok = pcall(function()
    job:sync(2000) -- 2 second timeout
  end)

  return ok and job.code == 0
end

return M
