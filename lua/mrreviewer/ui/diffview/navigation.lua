-- lua/mrreviewer/ui/diffview/navigation.lua
-- Bidirectional navigation and highlighting for diffview

local M = {}
local state = require('mrreviewer.core.state')
local config = require('mrreviewer.core.config')
local logger = require('mrreviewer.core.logger')
local diff_panel = require('mrreviewer.ui.diffview.diff_panel')
local highlights = require('mrreviewer.ui.highlights')

-- Store autocmd IDs for cleanup
local autocmd_ids = {}

--- Find comment at a specific line in a file
--- @param file_path string The file path to search in
--- @param line_number number The line number to find comments at
--- @param comments table List of all comments
--- @return table|nil Comment object or nil if not found
function M.find_comment_at_line(file_path, line_number, comments)
  if not file_path or not line_number or not comments then
    return nil
  end

  for _, comment in ipairs(comments) do
    if comment.position then
      local matches_file = comment.position.new_path == file_path
        or comment.position.old_path == file_path

      if matches_file then
        local comment_line = comment.position.new_line or comment.position.old_line
        if comment_line == line_number then
          return comment
        end
      end
    end
  end

  return nil
end

--- Highlight a specific comment in the comments panel
--- @param comment_id string|number Comment ID to highlight
function M.highlight_comment_in_panel(comment_id)
  local diffview = state.get_diffview()
  local panel_buffers = diffview.panel_buffers

  if not panel_buffers or not panel_buffers.comments then
    logger.warn('navigation', 'Comments panel buffer not available for highlighting')
    return
  end

  local buf = panel_buffers.comments
  if not vim.api.nvim_buf_is_valid(buf) then
    logger.error('navigation','Comments panel buffer is not valid')
    return
  end

  -- Get comment map from buffer variable
  local ok, comment_map = pcall(vim.api.nvim_buf_get_var, buf, 'mrreviewer_comment_map')
  if not ok or not comment_map then
    logger.debug('navigation','No comment map available in comments panel')
    return
  end

  -- Clear existing highlights
  local ns_id = vim.api.nvim_create_namespace('mrreviewer_comments_panel')
  vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)

  -- Find and highlight the comment line
  for line_num, comment in pairs(comment_map) do
    if comment.id == comment_id then
      vim.api.nvim_buf_add_highlight(
        buf,
        ns_id,
        highlights.get_group('selected_comment'),
        line_num - 1,
        0,
        -1
      )
      logger.debug('navigation','Highlighted comment ' .. comment_id .. ' in panel at line ' .. line_num)
      break
    end
  end
end

--- Jump to a specific comment in the diff view
--- @param comment table Comment object with position information
--- @param highlight_duration number|nil Duration in milliseconds for highlight (nil/0 for permanent)
--- @param mr_data table|nil MR data (required if switching files)
--- @return boolean Success status
function M.jump_to_comment(comment, highlight_duration, mr_data)
  logger.debug('navigation', 'jump_to_comment called', {
    has_comment = comment ~= nil,
    has_position = comment and comment.position ~= nil,
    has_mr_data = mr_data ~= nil,
  })

  if not comment or not comment.position then
    logger.error('navigation','Invalid comment or missing position for jump', {
      comment = comment,
    })
    return false
  end

  local file_path = comment.position.new_path or comment.position.old_path
  local line_number = comment.position.new_line or comment.position.old_line

  if not file_path or not line_number then
    logger.error('navigation','Missing file path or line number in comment position', {
      position = comment.position,
    })
    return false
  end

  logger.info('navigation','Jumping to comment', {
    file = file_path,
    line = line_number,
    comment_id = comment.id,
  })

  local diffview = state.get_diffview()

  -- Check if we need to switch files
  if diffview.selected_file ~= file_path then
    if not mr_data then
      logger.error('navigation','MR data required to switch files')
      return false
    end

    -- Update the file in diff panel
    diff_panel.update_file(mr_data, file_path)
    diffview.selected_file = file_path
  end

  -- Get the diff window (new version)
  local panel_windows = diffview.panel_windows
  if not panel_windows or not panel_windows.diff_new then
    logger.error('navigation','Diff windows not available')
    return false
  end

  local diff_win = panel_windows.diff_new

  if not vim.api.nvim_win_is_valid(diff_win) then
    logger.error('navigation','Diff window is not valid')
    return false
  end

  -- Switch to diff window and move cursor
  vim.api.nvim_set_current_win(diff_win)
  vim.api.nvim_win_set_cursor(diff_win, { line_number, 0 })

  -- Center the line in the window
  vim.cmd('normal! zz')

  -- Apply highlight
  local duration = highlight_duration or config.get_value('diffview.highlight_duration')
  diff_panel.highlight_comment_line(line_number, duration)

  -- Update selected comment in state
  diffview.selected_comment = comment

  -- Highlight the comment in the comments panel
  M.highlight_comment_in_panel(comment.id)

  logger.info('navigation','Successfully jumped to comment', {
    file = file_path,
    line = line_number,
  })

  return true
end

--- Open full comment thread in floating window
--- @param comment table Comment object
--- @param focus boolean|nil Whether to focus the floating window (default: false)
--- @return boolean Success status
function M.open_full_comment_thread(comment, focus)
  if not comment then
    logger.error('navigation','No comment provided to open_full_comment_thread')
    return false
  end

  logger.info('navigation','Opening full comment thread', { comment_id = comment.id })

  -- Get the comments module that handles floating windows
  local ok, comments_module = pcall(require, 'mrreviewer.ui.comments')
  if not ok then
    logger.error('navigation','Failed to load comments module: ' .. tostring(comments_module))
    return false
  end

  -- Check if the module has show_float function
  if not comments_module.show_float then
    logger.error('navigation','Comments module does not have show_float function')
    return false
  end

  -- Show the comment thread in a floating window
  local success = comments_module.show_float(comment, focus)

  if success then
    logger.info('navigation','Successfully opened comment thread')
  else
    logger.warn('navigation','Failed to open comment thread')
  end

  return success
end

--- Setup CursorMoved autocmd for bidirectional highlighting
--- @param comments table List of all comments
--- @param mr_data table|nil MR data (optional, for context)
function M.setup_diff_cursor_moved(comments, mr_data)
  if not comments or #comments == 0 then
    logger.debug('navigation','No comments to track for cursor moved')
    return
  end

  local diffview = state.get_diffview()
  local panel_windows = diffview.panel_windows

  if not panel_windows or not panel_windows.diff_new then
    logger.warn('navigation','Diff windows not available for cursor tracking')
    return
  end

  -- Clear any existing autocmds
  M.cleanup_autocmds()

  local diff_win = panel_windows.diff_new

  -- Create autocmd for cursor movement in diff window
  local autocmd_id = vim.api.nvim_create_autocmd('CursorMoved', {
    buffer = vim.api.nvim_win_get_buf(diff_win),
    callback = function()
      -- Only process if we're in the diff window
      if vim.api.nvim_get_current_win() ~= diff_win then
        return
      end

      local cursor = vim.api.nvim_win_get_cursor(diff_win)
      local line_number = cursor[1]

      local selected_file = diffview.selected_file
      if not selected_file then
        return
      end

      -- Find comment at current cursor position
      local comment = M.find_comment_at_line(selected_file, line_number, comments)

      if comment then
        -- Update selected comment in state
        diffview.selected_comment = comment

        -- Highlight the comment in comments panel
        M.highlight_comment_in_panel(comment.id)

        logger.debug('navigation','Cursor moved to comment', {
          line = line_number,
          comment_id = comment.id,
        })
      else
        -- Clear selection if no comment at current line
        diffview.selected_comment = nil

        -- Clear highlights in comments panel
        local comments_buf = diffview.panel_buffers and diffview.panel_buffers.comments
        if comments_buf and vim.api.nvim_buf_is_valid(comments_buf) then
          local ns_id = vim.api.nvim_create_namespace('mrreviewer_comments_panel')
          vim.api.nvim_buf_clear_namespace(comments_buf, ns_id, 0, -1)
        end
      end
    end,
  })

  table.insert(autocmd_ids, autocmd_id)

  logger.info('navigation','Set up CursorMoved autocmd for diff window')
end

--- Cleanup autocmds created by navigation module
function M.cleanup_autocmds()
  for _, autocmd_id in ipairs(autocmd_ids) do
    pcall(vim.api.nvim_del_autocmd, autocmd_id)
  end
  autocmd_ids = {}
  logger.debug('navigation','Cleaned up navigation autocmds')
end

--- Jump to comment and return focus to comments panel
--- @param comment table Comment object
--- @param highlight_duration number|nil Duration for highlight
--- @param mr_data table|nil MR data
--- @return boolean Success status
function M.jump_to_comment_and_return(comment, highlight_duration, mr_data)
  local diffview = state.get_diffview()
  local comments_win = diffview.panel_windows and diffview.panel_windows.comments

  -- Store current window if it's the comments panel
  local return_to_comments = comments_win
    and vim.api.nvim_win_is_valid(comments_win)
    and vim.api.nvim_get_current_win() == comments_win

  -- Jump to comment
  local success = M.jump_to_comment(comment, highlight_duration, mr_data)

  -- Return focus to comments panel if requested
  if success and return_to_comments and vim.api.nvim_win_is_valid(comments_win) then
    -- Use defer to let the jump complete first
    vim.defer_fn(function()
      if vim.api.nvim_win_is_valid(comments_win) then
        vim.api.nvim_set_current_win(comments_win)
        logger.debug('navigation','Returned focus to comments panel')
      end
    end, 50)
  end

  return success
end

--- Cleanup function to be called when closing diffview
function M.cleanup()
  M.cleanup_autocmds()
  logger.info('navigation','Navigation module cleaned up')
end

return M
