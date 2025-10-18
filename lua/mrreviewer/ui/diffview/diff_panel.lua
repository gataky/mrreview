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

--- Place comment range signs in diff buffers
--- @param file_path string Current file path
--- @param old_buf number Old diff buffer ID
--- @param new_buf number New diff buffer ID
local function place_comment_range_signs(file_path, old_buf, new_buf)
  local comments_state = state.get_comments()
  local comments = comments_state.list or {}

  logger.info('diff_panel', 'place_comment_range_signs called', {
    file_path = file_path,
    comment_count = #comments,
    old_buf = old_buf,
    new_buf = new_buf,
  })

  -- Unplace existing comment signs
  vim.fn.sign_unplace('MRReviewerCommentRange', { buffer = old_buf })
  vim.fn.sign_unplace('MRReviewerCommentRange', { buffer = new_buf })

  -- Group comments by their line range
  local comment_ranges = {}
  for _, comment in ipairs(comments) do
    if comment.position and comment.position.new_path == file_path then
      local start_line = comment.position.new_line
      local end_line = comment.position.new_line_end or start_line
      logger.info('diff_panel', 'Found comment for file', {
        comment_id = comment.id,
        start_line = start_line,
        end_line = end_line,
        new_line_end_raw = comment.position.new_line_end,
        is_multiline = start_line ~= end_line,
      })
      if start_line then
        table.insert(comment_ranges, {
          start_line = start_line,
          end_line = end_line,
          comment = comment,
        })
      end
    end
  end

  logger.info('diff_panel', 'Found comment ranges', {
    range_count = #comment_ranges,
  })

  -- Sort ranges by start line
  table.sort(comment_ranges, function(a, b)
    return a.start_line < b.start_line
  end)

  -- Place signs for each range
  for _, range in ipairs(comment_ranges) do
    local buf = new_buf -- Place in new buffer (right side)

    if range.start_line == range.end_line then
      -- Single line comment - use regular comment sign
      local sign_name = range.comment.resolved and 'MRReviewerCommentResolved' or 'MRReviewerComment'
      logger.debug('diff_panel', 'Placing single-line sign', {
        sign_name = sign_name,
        line = range.start_line,
        buf = buf,
      })
      vim.fn.sign_place(0, 'MRReviewerCommentRange', sign_name, buf, {
        lnum = range.start_line,
        priority = 15, -- Higher than diff signs but lower than selection
      })
    else
      -- Multi-line comment - use bracket signs
      logger.info('diff_panel', 'Placing multi-line bracket signs', {
        start_line = range.start_line,
        end_line = range.end_line,
        comment_id = range.comment.id,
        buf = buf,
      })

      -- Top bracket
      vim.fn.sign_place(0, 'MRReviewerCommentRange', 'MRReviewerCommentRangeTop', buf, {
        lnum = range.start_line,
        priority = 15,
      })

      -- Middle brackets
      for line = range.start_line + 1, range.end_line - 1 do
        vim.fn.sign_place(0, 'MRReviewerCommentRange', 'MRReviewerCommentRangeMiddle', buf, {
          lnum = line,
          priority = 15,
        })
      end

      -- Bottom bracket
      vim.fn.sign_place(0, 'MRReviewerCommentRange', 'MRReviewerCommentRangeBottom', buf, {
        lnum = range.end_line,
        priority = 15,
      })
    end
  end

  logger.info('diff_panel', 'Finished placing comment range signs')
end

--- Highlight a specific line in the diff buffers
--- @param line_number number Line number to highlight (1-indexed)
--- @param duration number|nil Duration in milliseconds (nil/0 for permanent)
function M.highlight_comment_line(line_number, duration)
  local diffview_state = state.get_diffview()
  local buffers = diffview_state.panel_buffers

  if not buffers or not buffers.diff_new then
    logger.warn('diff_panel','No diff buffers available for highlighting')
    return
  end

  local buf = buffers.diff_new
  if not vim.api.nvim_buf_is_valid(buf) then
    logger.error('diff_panel','Diff buffer is not valid')
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
    logger.warn('diff_panel','Line number out of range: ' .. line_number)
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

  logger.debug('diff_panel','Highlighted line ' .. line_number .. ' in diff buffer')

  -- Handle highlight duration
  if duration and duration > 0 then
    -- Clear highlight after duration using vim.defer_fn
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
        logger.debug('diff_panel','Cleared highlight for line ' .. line_number)
      end
      diffview_state.highlight_timer = nil
    end, duration)

    -- Note: We don't store the defer_fn timer as it can't be cancelled
    -- But we track that a highlight is active
    diffview_state.highlight_timer = -1 -- Sentinel value indicating active highlight
  else
    -- Permanent highlight (nil or 0 duration)
    logger.debug('diff_panel','Applied permanent highlight to line ' .. line_number)
  end
end

--- Update the diff view to show a different file
--- @param mr_data table MR data with diff_refs
--- @param file_path string Path of the file to display
--- @return boolean Success status
function M.update_file(mr_data, file_path)
  if not mr_data or not file_path then
    logger.error('diff_panel','Missing MR data or file path')
    return false
  end

  local base_sha = mr_data.diff_refs and mr_data.diff_refs.base_sha
  local head_sha = mr_data.diff_refs and mr_data.diff_refs.head_sha

  if not base_sha or not head_sha then
    logger.error('diff_panel','Missing diff refs in MR data')
    utils.notify('Missing diff refs (base_sha/head_sha) in MR data', 'error')
    return false
  end

  logger.info('diff_panel','Updating diff view for file: ' .. file_path)
  utils.notify('Loading diff for ' .. file_path .. '...', 'info')

  -- Fetch file versions using existing function
  local old_lines = view.fetch_file_versions(file_path, base_sha)
  local new_lines = view.fetch_file_versions(file_path, head_sha)

  if not old_lines then
    logger.error('diff_panel','Failed to fetch old version of file: ' .. file_path)
    utils.notify('Failed to fetch old version of ' .. file_path, 'error')
    return false
  end

  if not new_lines then
    logger.error('diff_panel','Failed to fetch new version of file: ' .. file_path)
    utils.notify('Failed to fetch new version of ' .. file_path, 'error')
    return false
  end

  -- Get diff buffers from state
  local diffview_state = state.get_diffview()
  local buffers = diffview_state.panel_buffers

  if not buffers or not buffers.diff_old or not buffers.diff_new then
    logger.error('diff_panel','Diff buffers not found in state')
    return false
  end

  local old_buf = buffers.diff_old
  local new_buf = buffers.diff_new

  -- Validate buffers
  if not vim.api.nvim_buf_is_valid(old_buf) or not vim.api.nvim_buf_is_valid(new_buf) then
    logger.error('diff_panel','One or more diff buffers are invalid')
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

  logger.info('diff_panel','Successfully updated diff view for: ' .. file_path)
  utils.notify('Loaded diff for ' .. file_path, 'info')

  -- Place comment range signs
  place_comment_range_signs(file_path, old_buf, new_buf)

  -- Setup keymaps for diff buffers (re-setup after update)
  M.setup_keymaps(old_buf, new_buf)

  return true
end

--- Render side-by-side diff for a file
--- @param mr_data table MR data with diff_refs
--- @param file_path string Path of the file to display
--- @return boolean Success status
function M.render(mr_data, file_path)
  if not mr_data or not file_path then
    logger.error('diff_panel','Missing MR data or file path for diff rendering')
    return false
  end

  local base_sha = mr_data.diff_refs and mr_data.diff_refs.base_sha
  local head_sha = mr_data.diff_refs and mr_data.diff_refs.head_sha

  if not base_sha or not head_sha then
    logger.error('diff_panel','Missing diff refs in MR data')
    utils.notify('Missing diff refs (base_sha/head_sha) in MR data', 'error')
    return false
  end

  logger.info('diff_panel','Rendering diff for file: ' .. file_path)

  -- Fetch file versions
  local old_lines = view.fetch_file_versions(file_path, base_sha)
  local new_lines = view.fetch_file_versions(file_path, head_sha)

  if not old_lines then
    logger.error('diff_panel','Failed to fetch old version of file: ' .. file_path)
    utils.notify('Failed to fetch old version of ' .. file_path, 'error')
    return false
  end

  if not new_lines then
    logger.error('diff_panel','Failed to fetch new version of file: ' .. file_path)
    utils.notify('Failed to fetch new version of ' .. file_path, 'error')
    return false
  end

  -- Get diff buffers from state (they should already exist from layout.create_layout)
  local diffview_state = state.get_diffview()
  local buffers = diffview_state.panel_buffers
  local windows = diffview_state.panel_windows

  if not buffers or not buffers.diff_old or not buffers.diff_new then
    logger.error('diff_panel','Diff buffers not found in state')
    return false
  end

  if not windows or not windows.diff_old or not windows.diff_new then
    logger.error('diff_panel','Diff windows not found in state')
    return false
  end

  local old_buf = buffers.diff_old
  local new_buf = buffers.diff_new
  local old_win = windows.diff_old
  local new_win = windows.diff_new

  -- Validate buffers and windows
  if not vim.api.nvim_buf_is_valid(old_buf) or not vim.api.nvim_buf_is_valid(new_buf) then
    logger.error('diff_panel','One or more diff buffers are invalid')
    return false
  end

  if not vim.api.nvim_win_is_valid(old_win) or not vim.api.nvim_win_is_valid(new_win) then
    logger.error('diff_panel','One or more diff windows are invalid')
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

  logger.info('diff_panel','Successfully rendered side-by-side diff for: ' .. file_path)

  -- Place comment range signs
  place_comment_range_signs(file_path, old_buf, new_buf)

  -- Setup keymaps for diff buffers
  M.setup_keymaps(old_buf, new_buf)

  return true
end

--- Setup keymaps for diff buffers
--- @param old_buf number Old diff buffer ID
--- @param new_buf number New diff buffer ID
function M.setup_keymaps(old_buf, new_buf)
  local navigation = require('mrreviewer.ui.diffview.navigation')

  -- Get comments from state
  local comments_state = state.get_comments()
  local comments = comments_state.list or {}

  -- Get MR data for file switching
  local session = state.get_session()
  local mr_data = session.mr_data

  logger.info('diff_panel', 'Setting up keymaps', {
    old_buf = old_buf,
    new_buf = new_buf,
    comment_count = #comments,
    has_mr_data = mr_data ~= nil,
    comments_sample = comments[1] and vim.inspect(comments[1]) or 'none',
  })

  -- Setup keymaps for both buffers
  for _, buf in ipairs({old_buf, new_buf}) do
    local opts = { noremap = true, silent = true, buffer = buf }

    -- K to preview comment at cursor
    vim.keymap.set('n', 'K', function()
      local cursor = vim.api.nvim_win_get_cursor(0)
      local line_number = cursor[1]

      local diffview = state.get_diffview()
      local selected_file = diffview.selected_file

      logger.info('diff_panel', 'K pressed', {
        line = line_number,
        file = selected_file,
        comment_count = #comments,
        first_comment_file = comments[1] and comments[1].position and comments[1].position.new_path or 'none',
        first_comment_line = comments[1] and comments[1].position and comments[1].position.new_line or 'none',
      })

      if not selected_file then
        logger.warn('diff_panel', 'No file selected for comment preview')
        utils.notify('No file selected', 'warn')
        return
      end

      -- Find comment at current line
      local comment = navigation.find_comment_at_line(selected_file, line_number, comments)

      if comment then
        logger.info('diff_panel', 'Found comment at line', {
          comment_id = comment.id,
          line = line_number,
          file = selected_file,
        })
        navigation.open_full_comment_thread(comment)
      else
        -- Debug: show all comment lines for this file
        local comment_lines = {}
        for _, c in ipairs(comments) do
          if c.position and (c.position.new_path == selected_file or c.position.old_path == selected_file) then
            table.insert(comment_lines, c.position.new_line or c.position.old_line)
          end
        end
        logger.info('diff_panel', 'No comment found', {
          searched_line = line_number,
          file = selected_file,
          available_comment_lines = table.concat(comment_lines, ', '),
        })
        utils.notify(string.format('No comment at line %d. Comments at: %s', line_number, table.concat(comment_lines, ', ')), 'info')
      end
    end, opts)

    -- KK to open comment and focus into floating window
    vim.keymap.set('n', 'KK', function()
      local cursor = vim.api.nvim_win_get_cursor(0)
      local line_number = cursor[1]

      local diffview = state.get_diffview()
      local selected_file = diffview.selected_file

      if not selected_file then
        logger.warn('diff_panel', 'No file selected for comment thread')
        return
      end

      -- Find comment at current line
      local comment = navigation.find_comment_at_line(selected_file, line_number, comments)

      if comment then
        logger.info('diff_panel', 'Opening comment thread', { comment_id = comment.id })
        -- Open and focus the floating window
        vim.schedule(function()
          navigation.open_full_comment_thread(comment, true)
        end)
      else
        logger.debug('diff_panel', 'No comment at line ' .. line_number)
      end
    end, opts)
  end

  logger.debug('diff_panel', 'Setup keymaps for diff buffers')
end

return M
