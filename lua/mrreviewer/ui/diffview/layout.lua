-- lua/mrreviewer/ui/diffview/layout.lua
-- Three-pane window layout management for diffview

local M = {}
local state = require('mrreviewer.core.state')
local config = require('mrreviewer.core.config')
local logger = require('mrreviewer.core.logger')

--- Create the three-pane layout windows
--- @return table|nil Window and buffer IDs, or nil on failure
--- @return string|nil Error message if failed
function M.create_three_pane_windows()
  -- Save current window to restore later if needed
  local original_win = vim.api.nvim_get_current_win()

  -- Get total width for calculating proportions
  local total_width = vim.o.columns

  -- Calculate widths: 15% | 70% | 15%
  local files_width = math.floor(total_width * 0.15)
  local diff_width = math.floor(total_width * 0.70)
  local comments_width = total_width - files_width - diff_width -- Ensure we use all available space

  logger.debug('layout','Creating three-pane layout', {
    total_width = total_width,
    files_width = files_width,
    diff_width = diff_width,
    comments_width = comments_width,
  })

  -- Create buffers for each pane
  local files_buf = vim.api.nvim_create_buf(false, true)
  local diff_old_buf = vim.api.nvim_create_buf(false, true)
  local diff_new_buf = vim.api.nvim_create_buf(false, true)
  local comments_buf = vim.api.nvim_create_buf(false, true)

  if files_buf == 0 or diff_old_buf == 0 or diff_new_buf == 0 or comments_buf == 0 then
    logger.error('layout','Failed to create buffers for diffview layout')
    return nil, 'Failed to create buffers'
  end

  -- Set buffer options for all panes
  local buffers = {
    files = files_buf,
    diff_old = diff_old_buf,
    diff_new = diff_new_buf,
    comments = comments_buf,
  }

  local buffer_names = {
    files = 'MRReviewer Files',
    diff_old = 'MRReviewer Diff (Old)',
    diff_new = 'MRReviewer Diff (New)',
    comments = 'MRReviewer Comments',
  }

  for pane_name, buf in pairs(buffers) do
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf, 'swapfile', false)
    vim.api.nvim_buf_set_name(buf, buffer_names[pane_name])
  end

  -- Close all windows except one
  vim.cmd('only')

  -- Create the layout:
  -- Start with full window, then split to create three panes

  -- Create files pane on the left (15%)
  vim.cmd('topleft ' .. files_width .. 'vsplit')
  local files_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(files_win, files_buf)

  -- Move to the right pane and create diff panes (70% total, split in half)
  vim.cmd('wincmd l')

  -- Create diff panes side-by-side in the middle section
  vim.cmd('vsplit')
  local diff_new_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(diff_new_win, diff_new_buf)

  vim.cmd('wincmd h')
  local diff_old_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(diff_old_win, diff_old_buf)

  -- Move to the rightmost section and create comments pane (15%)
  vim.cmd('wincmd l')
  vim.cmd('wincmd l')
  vim.cmd('botright ' .. comments_width .. 'vsplit')
  local comments_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(comments_win, comments_buf)

  -- Now explicitly set all window widths to maintain exact proportions
  local half_diff_width = math.floor(diff_width / 2)
  vim.api.nvim_win_set_width(files_win, files_width)
  vim.api.nvim_win_set_width(diff_old_win, half_diff_width)
  vim.api.nvim_win_set_width(diff_new_win, half_diff_width)
  vim.api.nvim_win_set_width(comments_win, comments_width)

  -- Set window options for all panes
  local windows = {
    files = files_win,
    diff_old = diff_old_win,
    diff_new = diff_new_win,
    comments = comments_win,
  }

  for _, win in pairs(windows) do
    vim.api.nvim_win_set_option(win, 'wrap', false)
    vim.api.nvim_win_set_option(win, 'cursorline', true)
  end

  -- Enable diff mode for the diff panes
  vim.api.nvim_win_set_option(diff_old_win, 'diff', true)
  vim.api.nvim_win_set_option(diff_new_win, 'diff', true)

  logger.info('layout','Three-pane layout created successfully')

  return {
    windows = windows,
    buffers = buffers,
  }
end

--- Focus a specific pane by name
--- @param pane_name string Pane to focus: 'files', 'diff', or 'comments'
--- @return boolean Success status
function M.focus_pane(pane_name)
  local diffview = state.get_diffview()
  local windows = diffview.panel_windows

  if not windows or vim.tbl_isempty(windows) then
    logger.error('layout','No diffview windows available to focus')
    return false
  end

  local target_win = nil

  if pane_name == 'files' then
    target_win = windows.files
  elseif pane_name == 'diff' then
    -- Focus the new diff pane (right side of diff)
    target_win = windows.diff_new
  elseif pane_name == 'comments' then
    target_win = windows.comments
  else
    logger.error('layout','Invalid pane name: ' .. tostring(pane_name))
    return false
  end

  if not target_win or not vim.api.nvim_win_is_valid(target_win) then
    logger.error('layout','Target window is not valid', { pane_name = pane_name, win = target_win })
    return false
  end

  vim.api.nvim_set_current_win(target_win)
  logger.debug('layout','Focused pane: ' .. pane_name)
  return true
end

--- Create the three-pane diffview layout
--- @param mr_data table MR data (not used yet, reserved for future)
--- @return boolean Success status
function M.create_layout(mr_data)
  logger.info('layout','Creating diffview layout')

  -- Create the window layout
  local layout, err = M.create_three_pane_windows()
  if not layout then
    logger.error('layout','Failed to create three-pane layout: ' .. tostring(err))
    return false
  end

  -- Store window and buffer IDs in state
  local diffview = state.get_diffview()
  diffview.panel_windows = layout.windows
  diffview.panel_buffers = layout.buffers

  logger.debug('layout','Stored layout in state', {
    windows = vim.tbl_keys(layout.windows),
    buffers = vim.tbl_keys(layout.buffers),
  })

  -- Focus the default pane from config
  local default_focus = config.get_value('diffview.default_focus') or 'files'
  M.focus_pane(default_focus)

  return true
end

--- Close the diffview layout and clean up state
--- @return boolean Success status
function M.close()
  logger.info('layout','Closing diffview layout')

  local diffview = state.get_diffview()
  local windows = diffview.panel_windows

  if not windows or vim.tbl_isempty(windows) then
    logger.warn('layout','No diffview windows to close')
    state.clear_diffview()
    return true
  end

  -- Close all diffview windows
  local closed_count = 0
  for pane_name, win in pairs(windows) do
    if vim.api.nvim_win_is_valid(win) then
      local ok, err = pcall(vim.api.nvim_win_close, win, true)
      if ok then
        closed_count = closed_count + 1
        logger.debug('layout','Closed window: ' .. pane_name)
      else
        logger.warn('layout','Failed to close window: ' .. pane_name, { error = err })
      end
    end
  end

  logger.info('layout','Closed ' .. closed_count .. ' diffview windows')

  -- Clear diffview state
  state.clear_diffview()

  return true
end

return M
