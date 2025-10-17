-- lua/mrreviewer/glab.lua
-- Wrapper for glab CLI tool with async execution using plenary.job

local M = {}
local utils = require('mrreviewer.utils')
local Job = require('plenary.job')

--- Execute a glab command asynchronously
--- @param args table Command arguments (e.g., {'mr', 'list', '--output', 'json'})
--- @param callback function Callback function(exit_code, stdout, stderr)
--- @param timeout number|nil Timeout in milliseconds (default: 30000)
function M.execute_async(args, callback, timeout)
  local config = require('mrreviewer.config')
  local glab_path = config.get_value('glab.path') or 'glab'
  timeout = timeout or config.get_value('glab.timeout') or 30000

  local job = Job:new({
    command = glab_path,
    args = args,
    on_exit = vim.schedule_wrap(function(j, exit_code)
      local stdout = table.concat(j:result(), '\n')
      local stderr = table.concat(j:stderr_result(), '\n')
      callback(exit_code, stdout, stderr)
    end),
  })

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
--- @return number, string, string exit_code, stdout, stderr
function M.execute_sync(args, timeout)
  local config = require('mrreviewer.config')
  local glab_path = config.get_value('glab.path') or 'glab'
  timeout = timeout or config.get_value('glab.timeout') or 30000

  local job = Job:new({
    command = glab_path,
    args = args,
  })

  -- Start job and wait for completion
  job:sync(timeout)

  local stdout = table.concat(job:result(), '\n')
  local stderr = table.concat(job:stderr_result(), '\n')
  local exit_code = job.code or 0

  return exit_code, stdout, stderr
end

--- Check if glab is installed and authenticated
--- @return boolean, string Returns true if ready, or false and error message
function M.check_installation()
  local config = require('mrreviewer.config')
  local glab_path = config.get_value('glab.path') or 'glab'

  -- Check if glab command exists
  local handle = io.popen('command -v ' .. glab_path .. ' 2>/dev/null')
  if not handle then
    return false, 'Failed to check for glab installation'
  end

  local result = handle:read('*a')
  handle:close()

  if utils.is_empty(result) then
    return false, 'glab CLI is not installed. Please install it from https://gitlab.com/gitlab-org/cli'
  end

  -- Check authentication status
  local exit_code, output, stderr = M.execute_sync({ 'auth', 'status' }, 5000)

  if exit_code ~= 0 then
    if output:match('not authenticated') or stderr:match('not authenticated') then
      return false, 'glab is not authenticated. Please run: glab auth login'
    end
    return false, 'Failed to check glab authentication status: ' .. (stderr or output)
  end

  return true, nil
end

--- Build glab command arguments for listing MRs
--- @param state string|nil MR state filter: 'opened', 'closed', 'merged', 'all' (default: 'opened')
--- @return table Command arguments
function M.build_mr_list_args(state)
  state = state or 'opened'
  return {
    'mr',
    'list',
    '--state',
    state,
    '--output',
    'json',
  }
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
