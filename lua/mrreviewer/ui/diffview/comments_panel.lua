-- lua/mrreviewer/ui/diffview/comments_panel.lua
-- Comments panel with filtering and minimal formatting for diffview

local M = {}
local state = require('mrreviewer.core.state')
local config = require('mrreviewer.core.config')
local logger = require('mrreviewer.core.logger')
local highlights = require('mrreviewer.ui.highlights')
local formatting = require('mrreviewer.ui.comments.formatting')

--- Group comments by file, maintaining file tree order
--- @param comments table List of all comments
--- @param files table List of file paths in display order
--- @return table Grouped comments: {file_path = {comment1, comment2, ...}}
function M.group_by_file(comments, files)
  if not comments or #comments == 0 then
    return {}
  end

  -- Create a set of files for quick lookup
  local file_set = {}
  for _, file in ipairs(files) do
    file_set[file] = true
  end

  -- Group comments by file
  local grouped = {}
  for _, comment in ipairs(comments) do
    if comment.position then
      -- Use new_path first, fallback to old_path
      local file_path = comment.position.new_path or comment.position.old_path

      -- Only include comments for files that are in the file list
      if file_path and file_set[file_path] then
        if not grouped[file_path] then
          grouped[file_path] = {}
        end
        table.insert(grouped[file_path], comment)
      end
    end
  end

  logger.debug('comments_panel','Grouped comments by file', {
    total_comments = #comments,
    files_with_comments = vim.tbl_count(grouped),
  })

  return grouped
end

--- Get the comment data at the current cursor position
--- @return table|nil Comment data or nil if not found
function M.get_comment_at_cursor()
  local line = vim.api.nvim_get_current_line()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

  logger.debug('comments_panel', 'get_comment_at_cursor called', {
    line = line,
    cursor_line = cursor_line,
  })

  -- Check if this is a comment line (starts with "Line ")
  if not line:match('^Line %d+') then
    logger.debug('comments_panel', 'Not a comment line', { line = line })
    return nil
  end

  -- Extract comment ID from the line (we'll store it as metadata)
  local diffview = state.get_diffview()
  local panel_buffers = diffview.panel_buffers

  if not panel_buffers or not panel_buffers.comments then
    logger.debug('comments_panel', 'No comments panel buffer in state')
    return nil
  end

  local buf = panel_buffers.comments
  if not vim.api.nvim_buf_is_valid(buf) then
    logger.debug('comments_panel', 'Comments panel buffer is invalid')
    return nil
  end

  -- Get comment from stored metadata
  -- We'll store comment references in buffer variables
  local ok, comment_map = pcall(vim.api.nvim_buf_get_var, buf, 'mrreviewer_comment_map')
  if not ok or not comment_map then
    logger.debug('comments_panel', 'No comment map found in buffer', { ok = ok })
    return nil
  end

  local comment = comment_map[cursor_line]
  logger.debug('comments_panel', 'Found comment', {
    has_comment = comment ~= nil,
    comment_id = comment and comment.id,
  })

  return comment
end

--- Setup keymaps for the comments panel buffer
--- @param buf number Buffer ID
--- @param on_comment_selected_callback function|nil Optional callback when comment is selected
--- @param on_open_thread_callback function|nil Optional callback to open full thread
function M.setup_keymaps(buf, on_comment_selected_callback, on_open_thread_callback)
  local opts = { noremap = true, silent = true, buffer = buf }

  logger.debug('comments_panel', 'Setting up keymaps for buffer ' .. buf)

  -- j/k navigation (standard vim motions work by default)

  -- Enter to jump to comment in diff view
  vim.keymap.set('n', '<CR>', function()
    logger.debug('comments_panel', '<CR> pressed in comments panel')
    local comment = M.get_comment_at_cursor()
    logger.debug('comments_panel', 'Got comment from cursor', {
      has_comment = comment ~= nil,
      has_callback = on_comment_selected_callback ~= nil,
    })
    if comment and on_comment_selected_callback then
      logger.info('comments_panel', 'Calling on_comment_selected callback')
      on_comment_selected_callback(comment)
    else
      logger.warn('comments_panel', 'No comment or callback', {
        has_comment = comment ~= nil,
        has_callback = on_comment_selected_callback ~= nil,
      })
    end
  end, opts)

  -- KK to open full comment thread in floating window
  vim.keymap.set('n', 'KK', function()
    local comment = M.get_comment_at_cursor()
    if comment and on_open_thread_callback then
      on_open_thread_callback(comment)
    end
  end, opts)

  -- Toggle resolved filter with 'r'
  vim.keymap.set('n', 'r', function()
    M.toggle_resolved_filter()
  end, vim.tbl_extend('force', opts, { desc = 'Toggle resolved comments filter' }))

  logger.debug('comments_panel','Comments panel keymaps set up for buffer ' .. buf)
end

--- Toggle the resolved comments filter
--- Updates state and triggers re-render
function M.toggle_resolved_filter()
  local diffview = state.get_diffview()
  local current = diffview.filter_resolved or false

  -- Toggle the filter
  diffview.filter_resolved = not current

  local filter_state = diffview.filter_resolved and 'hiding' or 'showing'
  logger.info('comments_panel','Toggled resolved filter: now ' .. filter_state .. ' resolved comments')

  -- Trigger re-render
  -- This will be called from the render function which has access to all data
  -- For now, we just update the state
  vim.notify('Filter: ' .. filter_state .. ' resolved comments', vim.log.levels.INFO)
end

--- Filter comments by resolved status
--- @param comments table List of comments
--- @param show_resolved boolean Whether to show resolved comments
--- @return table Filtered comments
function M.filter_by_status(comments, show_resolved)
  if show_resolved then
    return comments
  end

  local filtered = {}
  for _, comment in ipairs(comments) do
    if not comment.resolved then
      table.insert(filtered, comment)
    end
  end

  logger.debug('comments_panel','Filtered comments', {
    total = #comments,
    filtered = #filtered,
    show_resolved = show_resolved,
  })

  return filtered
end

--- Apply highlighting to the currently selected comment
--- @param buf number Buffer ID
--- @param selected_comment table|nil Currently selected comment
--- @param comment_map table Map of line numbers to comments
local function highlight_selected_comment(buf, selected_comment, comment_map)
  if not selected_comment then
    return
  end

  -- Clear existing highlights
  local ns_id = vim.api.nvim_create_namespace('mrreviewer_comments_panel')
  vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)

  -- Find the line containing the selected comment
  for line_num, comment in pairs(comment_map) do
    if comment.id == selected_comment.id then
      -- Highlight this line (0-indexed)
      vim.api.nvim_buf_add_highlight(
        buf,
        ns_id,
        highlights.get_group('selected_comment'),
        line_num - 1,
        0,
        -1
      )
      break
    end
  end
end

--- Render the comments panel with filtering and formatting
--- @param comments table List of all comments
--- @param files table List of file paths (for grouping order)
--- @param buf number|nil Buffer ID (if nil, uses current diffview buffer)
--- @param on_comment_selected_callback function|nil Optional callback when comment is selected
--- @param on_open_thread_callback function|nil Optional callback to open full thread
function M.render(comments, files, buf, on_comment_selected_callback, on_open_thread_callback)
  -- Get buffer from state if not provided
  if not buf then
    local diffview = state.get_diffview()
    buf = diffview.panel_buffers and diffview.panel_buffers.comments
  end

  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    logger.error('comments_panel','Invalid buffer for comments panel')
    return
  end

  -- Get filter state from config and state
  local diffview = state.get_diffview()
  local show_resolved = diffview.filter_resolved == false
    and config.get_value('diffview.show_resolved')
    or not diffview.filter_resolved

  -- Filter comments by status
  local filtered_comments = M.filter_by_status(comments, show_resolved)

  -- Handle empty state
  if not filtered_comments or #filtered_comments == 0 then
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      '',
      '  No comments to display',
      '',
      '  Press "r" to toggle resolved filter',
      ''
    })
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)

    -- Clear comment map
    pcall(vim.api.nvim_buf_set_var, buf, 'mrreviewer_comment_map', {})

    logger.info('comments_panel','Comments panel rendered (empty state)')
    return
  end

  -- Group comments by file
  local grouped = M.group_by_file(filtered_comments, files)

  -- Build content lines
  local lines = {}
  local comment_map = {} -- Map line numbers to comment objects
  local current_line = 1

  -- Iterate through files in display order
  for _, file_path in ipairs(files) do
    local file_comments = grouped[file_path]

    if file_comments and #file_comments > 0 then
      -- Add file header
      table.insert(lines, '')
      current_line = current_line + 1

      table.insert(lines, '📁 ' .. file_path)
      current_line = current_line + 1

      table.insert(lines, '---')
      current_line = current_line + 1

      -- Sort comments by line number
      table.sort(file_comments, function(a, b)
        local a_line = a.position and (a.position.new_line or a.position.old_line) or 0
        local b_line = b.position and (b.position.new_line or b.position.old_line) or 0
        return a_line < b_line
      end)

      -- Add each comment
      for _, comment in ipairs(file_comments) do
        local formatted = formatting.format_minimal(comment)
        table.insert(lines, formatted)

        -- Store comment reference for this line
        comment_map[current_line] = comment
        current_line = current_line + 1
      end
    end
  end

  -- Add empty line at the end
  table.insert(lines, '')

  -- Set buffer content
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  -- Store comment map in buffer variable
  pcall(vim.api.nvim_buf_set_var, buf, 'mrreviewer_comment_map', comment_map)

  -- Apply syntax highlighting
  M.apply_highlighting(buf, grouped, files)

  -- Apply highlighting for selected comment
  highlight_selected_comment(buf, diffview.selected_comment, comment_map)

  -- Setup keymaps
  M.setup_keymaps(buf, on_comment_selected_callback, on_open_thread_callback)

  logger.info('comments_panel','Comments panel rendered', {
    total_comments = #filtered_comments,
    files_with_comments = vim.tbl_count(grouped),
    show_resolved = show_resolved,
  })
end

--- Apply syntax highlighting to the comments panel
--- @param buf number Buffer ID
--- @param grouped table Grouped comments by file
--- @param files table List of file paths in display order
function M.apply_highlighting(buf, grouped, files)
  local ns_id = vim.api.nvim_create_namespace('mrreviewer_comments_syntax')
  vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  for i, line in ipairs(lines) do
    -- Highlight file headers (lines starting with 📁)
    if line:match('^📁') then
      vim.api.nvim_buf_add_highlight(
        buf,
        ns_id,
        highlights.get_group('comment_file_header'),
        i - 1,
        0,
        -1
      )
    -- Highlight separators
    elseif line:match('^%-%-%-') then
      vim.api.nvim_buf_add_highlight(
        buf,
        ns_id,
        'Comment',
        i - 1,
        0,
        -1
      )
    -- Highlight comment lines
    elseif line:match('^Line %d+') then
      -- Get comment from map to check resolved status
      local ok, comment_map = pcall(vim.api.nvim_buf_get_var, buf, 'mrreviewer_comment_map')
      if ok and comment_map and comment_map[i] then
        local comment = comment_map[i]
        local hl_group = comment.resolved
          and 'MRReviewerResolvedComment'
          or 'MRReviewerUnresolvedComment'

        vim.api.nvim_buf_add_highlight(
          buf,
          ns_id,
          hl_group,
          i - 1,
          0,
          -1
        )
      end
    end
  end
end

return M
