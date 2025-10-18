-- lua/mrreviewer/ui/diffview/comments_panel.lua
-- Comments panel with filtering and minimal formatting for diffview

local M = {}
local state = require('mrreviewer.core.state')
local config = require('mrreviewer.core.config')
local logger = require('mrreviewer.core.logger')
local highlights = require('mrreviewer.ui.highlights')
local formatting = require('mrreviewer.ui.comments.formatting')
local card_renderer = require('mrreviewer.ui.comments.card_renderer')
local card_navigator = require('mrreviewer.ui.comments.card_navigator')

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
--- Returns the primary (first) comment from the card at cursor
--- @return table|nil Comment data or nil if not found
function M.get_comment_at_cursor()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

  logger.debug('comments_panel', 'get_comment_at_cursor called', {
    cursor_line = cursor_line,
  })

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

  -- Get card from stored card_map
  local ok, card_map = pcall(vim.api.nvim_buf_get_var, buf, 'mrreviewer_card_map')
  if not ok or not card_map then
    logger.debug('comments_panel', 'No card map found in buffer', { ok = ok })
    return nil
  end

  local card = card_map[cursor_line]
  if not card then
    logger.debug('comments_panel', 'No card found at cursor line')
    return nil
  end

  -- Return the first comment from the card (primary comment)
  local comment = card.comments and card.comments[1]
  logger.debug('comments_panel', 'Found comment from card', {
    has_comment = comment ~= nil,
    comment_id = comment and comment.id,
    card_id = card.id,
    is_thread = card.is_thread,
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

  -- Tab to navigate to next card
  vim.keymap.set('n', '<Tab>', function()
    local win = vim.api.nvim_get_current_win()
    card_navigator.move_to_next_card(buf, win)
  end, vim.tbl_extend('force', opts, { desc = 'Move to next comment card' }))

  -- Shift+Tab to navigate to previous card
  vim.keymap.set('n', '<S-Tab>', function()
    local win = vim.api.nvim_get_current_win()
    card_navigator.move_to_prev_card(buf, win)
  end, vim.tbl_extend('force', opts, { desc = 'Move to previous comment card' }))

  -- ]f to navigate to next file section's first card
  vim.keymap.set('n', ']f', function()
    local win = vim.api.nvim_get_current_win()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local current_line = cursor[1]

    -- Find next file section
    local next_file_line = card_navigator.find_next_file_section(buf, current_line)
    if next_file_line then
      -- Move to the next file header
      vim.api.nvim_win_set_cursor(win, { next_file_line, 0 })

      -- Find the first card after this file header
      local ok, card_map = pcall(vim.api.nvim_buf_get_var, buf, 'mrreviewer_card_map')
      if ok and card_map then
        for line = next_file_line + 1, vim.api.nvim_buf_line_count(buf) do
          if card_map[line] then
            vim.api.nvim_win_set_cursor(win, { line, 0 })
            break
          end
        end
      end
    end
  end, vim.tbl_extend('force', opts, { desc = 'Move to next file section' }))

  -- [f to navigate to previous file section's first card
  vim.keymap.set('n', '[f', function()
    local win = vim.api.nvim_get_current_win()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local current_line = cursor[1]

    -- Find previous file section
    local prev_file_line = card_navigator.find_prev_file_section(buf, current_line)
    if prev_file_line then
      -- Move to the previous file header
      vim.api.nvim_win_set_cursor(win, { prev_file_line, 0 })

      -- Find the first card after this file header
      local ok, card_map = pcall(vim.api.nvim_buf_get_var, buf, 'mrreviewer_card_map')
      if ok and card_map then
        for line = prev_file_line + 1, vim.api.nvim_buf_line_count(buf) do
          if card_map[line] then
            vim.api.nvim_win_set_cursor(win, { line, 0 })
            break
          end
        end
      end
    end
  end, vim.tbl_extend('force', opts, { desc = 'Move to previous file section' }))

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

    -- Clear card map
    pcall(vim.api.nvim_buf_set_var, buf, 'mrreviewer_card_map', {})

    logger.info('comments_panel','Comments panel rendered (empty state)')
    return
  end

  -- Group comments by file
  local grouped = M.group_by_file(filtered_comments, files)

  -- Build content lines using card-based rendering
  local lines = {}
  local card_map = {} -- Map line ranges to card objects
  local current_line = 1

  -- Iterate through files in display order
  for _, file_path in ipairs(files) do
    local file_comments = grouped[file_path]

    if file_comments and #file_comments > 0 then
      -- Sort comments by line number
      table.sort(file_comments, function(a, b)
        local a_line = a.position and (a.position.new_line or a.position.old_line) or 0
        local b_line = b.position and (b.position.new_line or b.position.old_line) or 0
        return a_line < b_line
      end)

      -- Convert file comments into cards
      local file_cards = card_renderer.group_comments_into_cards(file_comments)

      -- Sort cards by line number (extracted from first comment)
      table.sort(file_cards, function(a, b)
        if not a.comments[1] or not b.comments[1] then
          return false
        end
        local a_line = a.comments[1].position and (a.comments[1].position.new_line or a.comments[1].position.old_line) or 0
        local b_line = b.comments[1].position and (b.comments[1].position.new_line or b.comments[1].position.old_line) or 0
        return a_line < b_line
      end)

      -- Add file header
      table.insert(lines, '')
      current_line = current_line + 1

      table.insert(lines, '📁 ' .. file_path .. ' (' .. #file_cards .. ' comments)')
      current_line = current_line + 1

      table.insert(lines, '---')
      current_line = current_line + 1

      -- Render each card
      for _, card in ipairs(file_cards) do
        -- Get card start line
        local card_start_line = current_line

        -- Render card with borders
        local card_lines = card_renderer.render_card_with_borders(card)

        -- Add card lines to buffer
        for _, card_line in ipairs(card_lines) do
          table.insert(lines, '  ' .. card_line) -- Indent cards slightly
          current_line = current_line + 1
        end

        -- Add spacing between cards
        table.insert(lines, '')
        current_line = current_line + 1

        -- Store card reference for this line range
        local card_end_line = current_line - 1
        for line_num = card_start_line, card_end_line do
          card_map[line_num] = card
        end
      end
    end
  end

  -- Add empty line at the end
  table.insert(lines, '')

  -- Set buffer content
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  -- Disable signcolumn and line numbers to conserve space
  vim.api.nvim_buf_set_option(buf, 'signcolumn', 'no')
  vim.api.nvim_buf_set_option(buf, 'number', false)
  vim.api.nvim_buf_set_option(buf, 'relativenumber', false)

  -- Store card map in buffer variable
  pcall(vim.api.nvim_buf_set_var, buf, 'mrreviewer_card_map', card_map)

  -- Apply syntax highlighting
  M.apply_highlighting(buf, grouped, files)

  -- Apply highlighting for selected comment (TODO: update to use card-based highlighting)
  -- highlight_selected_comment(buf, diffview.selected_comment, card_map)

  -- Setup keymaps
  M.setup_keymaps(buf, on_comment_selected_callback, on_open_thread_callback)

  logger.info('comments_panel','Comments panel rendered', {
    total_comments = #filtered_comments,
    files_with_comments = vim.tbl_count(grouped),
    show_resolved = show_resolved,
  })
end

--- Apply syntax highlighting to the comments panel (card-based)
--- @param buf number Buffer ID
--- @param grouped table Grouped comments by file
--- @param files table List of file paths in display order
function M.apply_highlighting(buf, grouped, files)
  local ns_id = vim.api.nvim_create_namespace('mrreviewer_comments_syntax')
  vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  -- Get card map to check for resolved status
  local ok, card_map = pcall(vim.api.nvim_buf_get_var, buf, 'mrreviewer_card_map')
  if not ok or not card_map then
    card_map = {}
  end

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
    -- Highlight card lines (lines that are part of a card)
    else
      local card = card_map[i]
      if card then
        -- Determine highlight group based on resolved status
        local hl_group
        if card.resolved then
          hl_group = 'MRReviewerCardResolved'
        else
          -- Check if this is a border line or content line
          if line:match('^%s*[┌└]') or line:match('^%s*[─]+') then
            hl_group = 'MRReviewerCardBorder'
          else
            hl_group = 'MRReviewerUnresolvedComment'
          end
        end

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

--- Scroll to the comment section for a specific file in the comments panel
--- @param file_path string The file path to scroll to
--- @return boolean Success status
function M.scroll_to_file(file_path)
  if not file_path then
    logger.warn('comments_panel', 'No file path provided to scroll_to_file')
    return false
  end

  local diffview = state.get_diffview()
  local panel_buffers = diffview.panel_buffers
  local panel_windows = diffview.panel_windows

  if not panel_buffers or not panel_buffers.comments then
    logger.warn('comments_panel', 'Comments panel buffer not available')
    return false
  end

  if not panel_windows or not panel_windows.comments then
    logger.warn('comments_panel', 'Comments panel window not available')
    return false
  end

  local buf = panel_buffers.comments
  local win = panel_windows.comments

  if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then
    logger.warn('comments_panel', 'Comments panel buffer or window is invalid')
    return false
  end

  -- Get all lines in the buffer
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  -- Find the line with the file header (starts with "📁 " followed by file path)
  local target_line = nil
  for i, line in ipairs(lines) do
    if line:match('^📁%s+' .. vim.pesc(file_path) .. '$') then
      target_line = i
      break
    end
  end

  if not target_line then
    logger.debug('comments_panel', 'File section not found in comments panel', { file = file_path })
    return false
  end

  -- Scroll to the file header line and move cursor there
  vim.api.nvim_win_set_cursor(win, { target_line, 0 })

  -- Center the line in the window
  vim.api.nvim_set_current_win(win)
  vim.cmd('normal! zz')

  logger.info('comments_panel', 'Scrolled to file section', {
    file = file_path,
    line = target_line,
  })

  return true
end

return M
