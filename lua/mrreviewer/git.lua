-- lua/mrreviewer/git.lua
-- Git operations using plenary.job for safe async execution
-- Replaces unsafe io.popen() calls throughout the codebase

local M = {}
local Job = require('plenary.job')
local errors = require('mrreviewer.errors')
local logger = require('mrreviewer.logger')

--- Execute a git command synchronously
--- @param args table Git command arguments (e.g., {'rev-parse', '--abbrev-ref', 'HEAD'})
--- @param opts table|nil Options: cwd (string), timeout (number in ms, default 5000)
--- @return string|nil, table|nil Result string or nil, and error object or nil
local function git_exec(args, opts)
  opts = opts or {}
  local timeout = opts.timeout or 5000
  local cwd = opts.cwd

  local cmd_str = 'git ' .. table.concat(args, ' ')
  logger.debug('git', 'Executing command: ' .. cmd_str, { cwd = cwd, timeout = timeout })

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
    local err = errors.git_error('Git command execution failed', {
      command = cmd_str,
      error = tostring(result),
      cwd = cwd,
    })
    logger.log_error('git', err)
    return nil, err
  end

  if job.code ~= 0 then
    local stderr = table.concat(job:stderr_result() or {}, '\n')
    local err = errors.git_error('Git command failed', {
      command = cmd_str,
      exit_code = job.code,
      stderr = stderr ~= '' and stderr or nil,
      cwd = cwd,
    })
    logger.log_error('git', err)
    return nil, err
  end

  local stdout = table.concat(result or {}, '\n')
  logger.debug('git', 'Command succeeded: ' .. cmd_str, { output_length = #stdout })
  return stdout, nil
end

--- Get current git branch name
--- @param cwd string|nil Working directory (defaults to current)
--- @return string|nil, table|nil Branch name or nil, and error object or nil
function M.get_current_branch(cwd)
  local result, err = git_exec({ 'rev-parse', '--abbrev-ref', 'HEAD' }, { cwd = cwd })

  if not result then
    return nil, errors.wrap('Failed to get current branch', err)
  end

  -- Trim whitespace
  result = result:match('^%s*(.-)%s*$')

  if result == '' then
    local err_obj = errors.git_error('Empty branch name returned')
    logger.log_error('git', err_obj)
    return nil, err_obj
  end

  logger.info('git', 'Current branch: ' .. result, { cwd = cwd })
  return result, nil
end

--- Check if currently in a git repository
--- @param cwd string|nil Working directory (defaults to current)
--- @return boolean True if inside a git repository
function M.is_git_repo(cwd)
  local result, err = git_exec({ 'rev-parse', '--is-inside-work-tree' }, { cwd = cwd })

  if not result then
    return false
  end

  -- Trim whitespace
  result = result:match('^%s*(.-)%s*$')

  return result == 'true'
end

--- Get git repository root directory
--- @param cwd string|nil Working directory to check (defaults to current)
--- @return string|nil, table|nil Root directory path or nil, and error object or nil
function M.get_repo_root(cwd)
  local result, err = git_exec({ 'rev-parse', '--show-toplevel' }, { cwd = cwd })

  if not result then
    return nil, errors.wrap('Failed to get repository root', err)
  end

  -- Trim whitespace
  result = result:match('^%s*(.-)%s*$')

  if result == '' then
    local err_obj = errors.git_error('Empty repository root returned')
    logger.log_error('git', err_obj)
    return nil, err_obj
  end

  logger.info('git', 'Repository root: ' .. result)
  return result, nil
end

--- Get git remote URL
--- @param remote_name string|nil Remote name (default: 'origin')
--- @param cwd string|nil Working directory (defaults to current)
--- @return string|nil, table|nil Remote URL or nil, and error object or nil
function M.get_remote_url(remote_name, cwd)
  remote_name = remote_name or 'origin'

  local result, err = git_exec({ 'remote', 'get-url', remote_name }, { cwd = cwd })

  if not result then
    return nil, errors.wrap('Failed to get remote URL for ' .. remote_name, err)
  end

  -- Trim whitespace
  result = result:match('^%s*(.-)%s*$')

  if result == '' then
    local err_obj = errors.git_error('Empty remote URL returned for ' .. remote_name)
    logger.log_error('git', err_obj)
    return nil, err_obj
  end

  logger.info('git', 'Remote URL for ' .. remote_name .. ': ' .. result)
  return result, nil
end

--- Get the upstream tracking branch for current branch
--- @param cwd string|nil Working directory (defaults to current)
--- @return string|nil, table|nil Upstream branch name or nil, and error object or nil
function M.get_upstream_branch(cwd)
  local result, err = git_exec({ 'rev-parse', '--abbrev-ref', '@{upstream}' }, { cwd = cwd })

  if not result then
    -- Upstream not configured is common, so just return nil without detailed error
    return nil, nil
  end

  -- Trim whitespace
  result = result:match('^%s*(.-)%s*$')

  if result == '' then
    return nil, nil
  end

  return result, nil
end

--- Check if a command exists in PATH
--- Used for checking if glab CLI is installed
--- @param command string Command name to check
--- @return boolean True if command exists
function M.command_exists(command)
  logger.debug('git', 'Checking if command exists: ' .. command)

  local job = Job:new({
    command = 'command',
    args = { '-v', command },
  })

  local ok = pcall(function()
    job:sync(2000) -- 2 second timeout
  end)

  local exists = ok and job.code == 0
  logger.info('git', 'Command ' .. command .. ' exists: ' .. tostring(exists))
  return exists
end

return M
