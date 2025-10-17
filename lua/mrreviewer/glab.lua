-- lua/mrreviewer/glab.lua
-- Wrapper for glab CLI tool with async execution

local M = {}
local utils = require('mrreviewer.utils')

--- Execute a glab command asynchronously
--- @param args table Command arguments (e.g., {'mr', 'list', '--output', 'json'})
--- @param callback function Callback function(exit_code, stdout, stderr)
--- @param timeout number|nil Timeout in milliseconds (default: 30000)
function M.execute_async(args, callback, timeout)
  local config = require('mrreviewer.config')
  local glab_path = config.get_value('glab.path') or 'glab'
  timeout = timeout or config.get_value('glab.timeout') or 30000

  local stdout_chunks = {}
  local stderr_chunks = {}

  -- Create stdout pipe
  local stdout = vim.loop.new_pipe(false)
  local stderr = vim.loop.new_pipe(false)

  -- Timer for timeout
  local timer = vim.loop.new_timer()
  local timed_out = false

  local handle
  handle = vim.loop.spawn(
    glab_path,
    {
      args = args,
      stdio = { nil, stdout, stderr },
    },
    vim.schedule_wrap(function(exit_code, signal)
      -- Stop timer
      if timer then
        timer:stop()
        timer:close()
      end

      -- Close pipes
      if stdout then
        stdout:close()
      end
      if stderr then
        stderr:close()
      end

      -- Handle timeout
      if timed_out then
        callback(1, '', 'Command timed out after ' .. timeout .. 'ms')
        return
      end

      -- Combine output chunks
      local stdout_str = table.concat(stdout_chunks, '')
      local stderr_str = table.concat(stderr_chunks, '')

      callback(exit_code, stdout_str, stderr_str)
    end)
  )

  if not handle then
    callback(1, '', 'Failed to spawn glab process')
    return
  end

  -- Set up timeout
  timer:start(timeout, 0, function()
    timed_out = true
    if handle then
      handle:kill(15) -- SIGTERM
    end
  end)

  -- Read stdout
  if stdout then
    stdout:read_start(function(err, data)
      if err then
        utils.notify('Error reading glab stdout: ' .. err, 'error')
        return
      end
      if data then
        table.insert(stdout_chunks, data)
      end
    end)
  end

  -- Read stderr
  if stderr then
    stderr:read_start(function(err, data)
      if err then
        utils.notify('Error reading glab stderr: ' .. err, 'error')
        return
      end
      if data then
        table.insert(stderr_chunks, data)
      end
    end)
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

  -- Build command
  local cmd = glab_path .. ' ' .. table.concat(args, ' ')

  -- Execute with timeout
  local handle = io.popen(cmd .. ' 2>&1')
  if not handle then
    return 1, '', 'Failed to execute command'
  end

  local output = handle:read('*a')
  local success, exit_type, exit_code = handle:close()

  if not success then
    return exit_code or 1, output, 'Command failed'
  end

  return 0, output, ''
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
