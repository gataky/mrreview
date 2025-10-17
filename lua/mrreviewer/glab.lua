-- lua/mrreviewer/glab.lua
-- Wrapper for glab CLI tool with async execution using plenary.job

local M = {}
local utils = require('mrreviewer.utils')
local Job = require('plenary.job')

--- Execute a glab command asynchronously
--- @param args table Command arguments (e.g., {'mr', 'list', '--output', 'json'})
--- @param callback function Callback function(exit_code, stdout, stderr)
--- @param timeout number|nil Timeout in milliseconds (default: 30000)
--- @param cwd string|nil Working directory (defaults to git repo root)
function M.execute_async(args, callback, timeout, cwd)
  local config = require('mrreviewer.config')
  local glab_path = config.get_value('glab.path') or 'glab'
  timeout = timeout or config.get_value('glab.timeout') or 30000

  -- If no cwd specified, try to get git repo root
  if not cwd then
    local project = require('mrreviewer.project')
    cwd = project.get_repo_root()
  end

  local job_opts = {
    command = glab_path,
    args = args,
    on_exit = vim.schedule_wrap(function(j, exit_code)
      local stdout = table.concat(j:result(), '\n')
      local stderr = table.concat(j:stderr_result(), '\n')
      callback(exit_code, stdout, stderr)
    end),
  }

  -- Set working directory if available
  if cwd then
    job_opts.cwd = cwd
  end

  local job = Job:new(job_opts)

  job:start()

  -- Set up timeout
  if timeout and timeout > 0 then
    vim.defer_fn(function()
      if job and not job.is_shutdown then
        job:shutdown()
        callback(1, '', 'Command timed out after ' .. timeout .. 'ms')
      end
    end, timeout)
  end
end

--- Execute a glab command synchronously (blocking)
--- @param args table Command arguments
--- @param timeout number|nil Timeout in milliseconds
--- @param cwd string|nil Working directory (defaults to git repo root)
--- @return number, string, string exit_code, stdout, stderr
function M.execute_sync(args, timeout, cwd)
  local config = require('mrreviewer.config')
  local glab_path = config.get_value('glab.path') or 'glab'
  timeout = timeout or config.get_value('glab.timeout') or 30000

  -- If no cwd specified, try to get git repo root
  if not cwd then
    local project = require('mrreviewer.project')
    cwd = project.get_repo_root()
  end

  local job_opts = {
    command = glab_path,
    args = args,
  }

  -- Set working directory if available
  if cwd then
    job_opts.cwd = cwd
  end

  local job = Job:new(job_opts)

  -- Start job and wait for completion
  job:sync(timeout)

  local stdout = table.concat(job:result(), '\n')
  local stderr = table.concat(job:stderr_result(), '\n')
  local exit_code = job.code or 0

  return exit_code, stdout, stderr
end

--- Check if glab is installed
--- Note: This only checks if the glab binary exists, not authentication status.
--- Authentication will be validated naturally when actual glab commands are run,
--- and glab will automatically use the correct GitLab instance based on git remote.
--- @return boolean, string Returns true if ready, or false and error message
function M.check_installation()
  local config = require('mrreviewer.config')
  local git = require('mrreviewer.git')
  local glab_path = config.get_value('glab.path') or 'glab'

  -- Check if glab command exists
  if not git.command_exists(glab_path) then
    return false, 'glab CLI is not installed. Please install it from https://gitlab.com/gitlab-org/cli'
  end

  -- Don't check authentication here - it will be validated when actual commands run.
  -- This avoids false errors when multiple GitLab instances are configured and
  -- one has auth issues but the one for the current repo is fine.
  return true, nil
end

--- Build glab command arguments for listing MRs
--- @param state string|nil MR state filter: 'opened', 'closed', 'merged', 'all' (default: 'opened')
--- @return table Command arguments
function M.build_mr_list_args(state)
  state = state or 'opened'

  local args = {
    'mr',
    'list',
    '--output',
    'json',
  }

  -- Add state flag if not 'opened' (opened is the default)
  if state == 'closed' then
    table.insert(args, '--closed')
  elseif state == 'merged' then
    table.insert(args, '--merged')
  elseif state == 'all' then
    table.insert(args, '--all')
  end
  -- 'opened' is default, no flag needed

  return args
end

--- Build glab command arguments for viewing an MR
--- @param mr_number string|number MR number
--- @param with_comments boolean Whether to include comments
--- @return table Command arguments
function M.build_mr_view_args(mr_number, with_comments)
  local args = {
    'mr',
    'view',
    tostring(mr_number),
    '--output',
    'json',
  }

  if with_comments then
    table.insert(args, '--comments')
  end

  return args
end

--- Build glab command arguments for getting MR diff
--- @param mr_number string|number MR number
--- @return table Command arguments
function M.build_mr_diff_args(mr_number)
  return {
    'mr',
    'diff',
    tostring(mr_number),
  }
end

return M
