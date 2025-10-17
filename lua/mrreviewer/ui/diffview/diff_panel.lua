-- lua/mrreviewer/ui/diffview/diff_panel.lua
-- Side-by-side diff rendering for diffview

local M = {}
local state = require('mrreviewer.core.state')
local config = require('mrreviewer.core.config')
local logger = require('mrreviewer.core.logger')
local utils = require('mrreviewer.lib.utils')
local highlights = require('mrreviewer.ui.highlights')

-- Import fetch_file_versions from existing diff view module
local view = require('mrreviewer.ui.diff.view')

--- Highlight a specific line in the diff buffers
--- @param line_number number Line number to highlight (1-indexed)
--- @param duration number|nil Duration in milliseconds (nil/0 for permanent)
function M.highlight_comment_line(line_number, duration)
  local diffview_state = state.get_diffview()
  local buffers = diffview_state.panel_buffers

  if not buffers or not buffers.diff_new then
    logger.log_warn('No diff buffers available for highlighting')
    return
  end

  local buf = buffers.diff_new
  if not vim.api.nvim_buf_is_valid(buf) then
    logger.log_error('Diff buffer is not valid')
    return
  end

  -- Cancel previous highlight timer if exists
  if diffview_state.highlight_timer then
    vim.fn.timer_stop(diffview_state.highlight_timer)
    diffview_state.highlight_timer = nil
  end

  -- Create namespace for comment highlights
  local ns_id = vim.api.nvim_create_namespace('mrreviewer_comment_highlight')

  -- Clear previous highlights
  vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)

  -- Validate line number
  local line_count = vim.api.nvim_buf_line_count(buf)
  if line_number < 1 or line_number > line_count then
    logger.log_warn('Line number out of range: ' .. line_number)
    return
  end

  -- Apply highlight (0-indexed for extmark API)
  vim.api.nvim_buf_add_highlight(
    buf,
    ns_id,
    highlights.get_group('comment_highlight'),
    line_number - 1,
    0,
    -1
  )

  logger.log_debug('Highlighted line ' .. line_number .. ' in diff buffer')

  -- Handle highlight duration
  if duration and duration > 0 then
    -- Clear highlight after duration using vim.defer_fn
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
        logger.log_debug('Cleared highlight for line ' .. line_number)
      end
      diffview_state.highlight_timer = nil
    end, duration)

    -- Note: We don't store the defer_fn timer as it can't be cancelled
    -- But we track that a highlight is active
    diffview_state.highlight_timer = -1 -- Sentinel value indicating active highlight
  else
    -- Permanent highlight (nil or 0 duration)
    logger.log_debug('Applied permanent highlight to line ' .. line_number)
  end
end

--- Update the diff view to show a different file
--- @param mr_data table MR data with diff_refs
--- @param file_path string Path of the file to display
--- @return boolean Success status
function M.update_file(mr_data, file_path)
  if not mr_data or not file_path then
    logger.log_error('Missing MR data or file path')
    return false
  end

  local base_sha = mr_data.diff_refs and mr_data.diff_refs.base_sha
  local head_sha = mr_data.diff_refs and mr_data.diff_refs.head_sha

  if not base_sha or not head_sha then
    logger.log_error('Missing diff refs in MR data')
    utils.notify('Missing diff refs (base_sha/head_sha) in MR data', 'error')
    return false
  end

  logger.log_info('Updating diff view for file: ' .. file_path)
  utils.notify('Loading diff for ' .. file_path .. '...', 'info')

  -- Fetch file versions using existing function
  local old_lines = view.fetch_file_versions(file_path, base_sha)
  local new_lines = view.fetch_file_versions(file_path, head_sha)

  if not old_lines then
    logger.log_error('Failed to fetch old version of file: ' .. file_path)
    utils.notify('Failed to fetch old version of ' .. file_path, 'error')
    return false
  end

  if not new_lines then
    logger.log_error('Failed to fetch new version of file: ' .. file_path)
    utils.notify('Failed to fetch new version of ' .. file_path, 'error')
    return false
  end

  -- Get diff buffers from state
  local diffview_state = state.get_diffview()
  local buffers = diffview_state.panel_buffers

  if not buffers or not buffers.diff_old or not buffers.diff_new then
    logger.log_error('Diff buffers not found in state')
    return false
  end

  local old_buf = buffers.diff_old
  local new_buf = buffers.diff_new

  -- Validate buffers
  if not vim.api.nvim_buf_is_valid(old_buf) or not vim.api.nvim_buf_is_valid(new_buf) then
    logger.log_error('One or more diff buffers are invalid')
    return false
  end

  -- Update old buffer
  vim.api.nvim_buf_set_option(old_buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(old_buf, 0, -1, false, old_lines)
  vim.api.nvim_buf_set_option(old_buf, 'modifiable', false)

  -- Update new buffer
  vim.api.nvim_buf_set_option(new_buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, new_lines)
  vim.api.nvim_buf_set_option(new_buf, 'modifiable', false)

  -- Update buffer names
  pcall(vim.api.nvim_buf_set_name, old_buf, 'MRReviewer Old: ' .. file_path)
  pcall(vim.api.nvim_buf_set_name, new_buf, 'MRReviewer New: ' .. file_path)

  -- Set filetype for syntax highlighting
  local ft = vim.filetype.match({ filename = file_path })
  if ft then
    vim.api.nvim_buf_set_option(old_buf, 'filetype', ft)
    vim.api.nvim_buf_set_option(new_buf, 'filetype', ft)
  end

  logger.log_info('Successfully updated diff view for: ' .. file_path)
  utils.notify('Loaded diff for ' .. file_path, 'info')

  return true
end

--- Render side-by-side diff for a file
--- @param mr_data table MR data with diff_refs
--- @param file_path string Path of the file to display
--- @return boolean Success status
function M.render(mr_data, file_path)
  if not mr_data or not file_path then
    logger.log_error('Missing MR data or file path for diff rendering')
    return false
  end

  local base_sha = mr_data.diff_refs and mr_data.diff_refs.base_sha
  local head_sha = mr_data.diff_refs and mr_data.diff_refs.head_sha

  if not base_sha or not head_sha then
    logger.log_error('Missing diff refs in MR data')
    utils.notify('Missing diff refs (base_sha/head_sha) in MR data', 'error')
    return false
  end

  logger.log_info('Rendering diff for file: ' .. file_path)

  -- Fetch file versions
  local old_lines = view.fetch_file_versions(file_path, base_sha)
  local new_lines = view.fetch_file_versions(file_path, head_sha)

  if not old_lines then
    logger.log_error('Failed to fetch old version of file: ' .. file_path)
    utils.notify('Failed to fetch old version of ' .. file_path, 'error')
    return false
  end

  if not new_lines then
    logger.log_error('Failed to fetch new version of file: ' .. file_path)
    utils.notify('Failed to fetch new version of ' .. file_path, 'error')
    return false
  end

  -- Get diff buffers from state (they should already exist from layout.create_layout)
  local diffview_state = state.get_diffview()
  local buffers = diffview_state.panel_buffers
  local windows = diffview_state.panel_windows

  if not buffers or not buffers.diff_old or not buffers.diff_new then
    logger.log_error('Diff buffers not found in state')
    return false
  end

  if not windows or not windows.diff_old or not windows.diff_new then
    logger.log_error('Diff windows not found in state')
    return false
  end

  local old_buf = buffers.diff_old
  local new_buf = buffers.diff_new
  local old_win = windows.diff_old
  local new_win = windows.diff_new

  -- Validate buffers and windows
  if not vim.api.nvim_buf_is_valid(old_buf) or not vim.api.nvim_buf_is_valid(new_buf) then
    logger.log_error('One or more diff buffers are invalid')
    return false
  end

  if not vim.api.nvim_win_is_valid(old_win) or not vim.api.nvim_win_is_valid(new_win) then
    logger.log_error('One or more diff windows are invalid')
    return false
  end

  -- Set buffer content
  vim.api.nvim_buf_set_option(old_buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(old_buf, 0, -1, false, old_lines)
  vim.api.nvim_buf_set_option(old_buf, 'modifiable', false)

  vim.api.nvim_buf_set_option(new_buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, new_lines)
  vim.api.nvim_buf_set_option(new_buf, 'modifiable', false)

  -- Set buffer names
  pcall(vim.api.nvim_buf_set_name, old_buf, 'MRReviewer Old: ' .. file_path)
  pcall(vim.api.nvim_buf_set_name, new_buf, 'MRReviewer New: ' .. file_path)

  -- Set filetype for syntax highlighting
  local ft = vim.filetype.match({ filename = file_path })
  if ft then
    vim.api.nvim_buf_set_option(old_buf, 'filetype', ft)
    vim.api.nvim_buf_set_option(new_buf, 'filetype', ft)
  end

  -- Configure diff mode for windows (already set in layout.lua, but ensure it's enabled)
  vim.api.nvim_win_set_option(old_win, 'diff', true)
  vim.api.nvim_win_set_option(new_win, 'diff', true)

  -- Set scrollbind to keep windows synchronized
  vim.api.nvim_win_set_option(old_win, 'scrollbind', true)
  vim.api.nvim_win_set_option(new_win, 'scrollbind', true)

  -- Set cursorbind to keep cursor synchronized
  vim.api.nvim_win_set_option(old_win, 'cursorbind', true)
  vim.api.nvim_win_set_option(new_win, 'cursorbind', true)

  logger.log_info('Successfully rendered side-by-side diff for: ' .. file_path)

  return true
end

return M
