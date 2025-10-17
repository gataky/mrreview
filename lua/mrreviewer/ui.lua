-- lua/mrreviewer/ui.lua
-- Selection interfaces and user prompts

local M = {}
local utils = require('mrreviewer.utils')

--- Format a timestamp for display
--- @param timestamp string ISO 8601 timestamp
--- @return string Formatted timestamp
local function format_timestamp(timestamp)
  if utils.is_empty(timestamp) then
    return 'N/A'
  end

  -- Extract date portion (YYYY-MM-DD)
  local date = timestamp:match('(%d%d%d%d%-%d%d%-%d%d)')
  if date then
    return date
  end

  return timestamp
end

--- Format an MR entry for display
--- @param mr table MR data
--- @param include_metadata boolean|nil Include additional metadata (default: false)
--- @return string Formatted MR entry
function M.format_mr_entry(mr, include_metadata)
  if not mr then
    return ''
  end

  local formatted = string.format('!%d - %s', mr.iid or 0, mr.title or 'Untitled')

  if include_metadata then
    formatted = formatted .. string.format(' (@%s)', mr.author and mr.author.username or 'unknown')

    if mr.created_at then
      formatted = formatted .. string.format(' [%s]', format_timestamp(mr.created_at))
    end

    if mr.state and mr.state ~= 'opened' then
      formatted = formatted .. string.format(' (%s)', mr.state)
    end
  else
    -- Default: just include author
    formatted = formatted .. string.format(' (@%s)', mr.author and mr.author.username or 'unknown')
  end

  return formatted
end

--- Display MR selection UI
--- @param mrs table List of MRs
--- @param callback function Callback function(selected_mr, index)
function M.select_mr(mrs, callback)
  if not mrs or #mrs == 0 then
    utils.notify('No merge requests available', 'info')
    return
  end

  -- Format MRs for display
  local items = {}
  for _, mr in ipairs(mrs) do
    table.insert(items, M.format_mr_entry(mr, false))
  end

  -- Display selection UI
  vim.ui.select(items, {
    prompt = 'Select MR to review:',
    format_item = function(item)
      return item
    end,
  }, function(choice, idx)
    if choice and idx then
      callback(mrs[idx], idx)
    end
  end)
end

--- Display a floating window with text content
--- @param title string Window title
--- @param lines table List of lines to display
--- @param opts table|nil Window options
function M.show_float(title, lines, opts)
  opts = opts or {}

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')

  -- Calculate window size
  local width = opts.width or 80
  local height = opts.height or #lines + 2

  -- Center window
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Window options
  local win_opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = opts.border or 'rounded',
    title = title,
    title_pos = 'center',
  }

  -- Open window
  local win = vim.api.nvim_open_win(buf, true, win_opts)

  -- Set window options
  vim.api.nvim_win_set_option(win, 'wrap', true)
  vim.api.nvim_win_set_option(win, 'cursorline', true)

  -- Close on q or <Esc>
  local close_keys = { 'q', '<Esc>' }
  for _, key in ipairs(close_keys) do
    vim.api.nvim_buf_set_keymap(buf, 'n', key, '', {
      callback = function()
        vim.api.nvim_win_close(win, true)
      end,
      noremap = true,
      silent = true,
    })
  end

  return buf, win
end

--- Show loading indicator
--- @param message string Loading message
--- @return number Timer ID
function M.show_loading(message)
  message = message or 'Loading...'

  local frames = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }
  local frame_idx = 1

  local timer = vim.loop.new_timer()
  timer:start(0, 100, vim.schedule_wrap(function()
    local frame = frames[frame_idx]
    vim.notify(frame .. ' ' .. message, vim.log.levels.INFO, {
      title = 'MRReviewer',
      hide_from_history = true,
      timeout = false,
    })

    frame_idx = frame_idx + 1
    if frame_idx > #frames then
      frame_idx = 1
    end
  end))

  return timer
end

--- Hide loading indicator
--- @param timer number Timer ID from show_loading
function M.hide_loading(timer)
  if timer then
    timer:stop()
    timer:close()
  end
end

return M
