-- lua/mrreviewer/comments/init.lua
-- Comment fetching, parsing, and display logic

local M = {}
local utils = require('mrreviewer.lib.utils')
local parsers = require('mrreviewer.lib.parsers')
local highlights = require('mrreviewer.ui.highlights')
local position = require('mrreviewer.lib.position')
local formatting = require('mrreviewer.ui.comments.formatting')
local state_module = require('mrreviewer.core.state')

-- Expose comments state dynamically for backward compatibility
setmetatable(M, {
  __index = function(t, key)
    if key == 'state' then
      return state_module.get_comments()
    end
    return rawget(t, key)
  end,
})

--- Filter comments by file path
--- @param comments table List of all comments
--- @param file_path string File path to filter by
--- @return table Filtered comments
function M.filter_by_file(comments, file_path)
  return parsers.filter_comments_by_file(comments, file_path)
end

--- Map comment position to buffer line number
--- @param comment table Comment with position data
--- @param buffer number Buffer number
--- @return number|nil Line number in buffer (1-indexed) or nil
function M.map_to_line(comment, buffer)
  return position.map_comment_to_line(comment, buffer)
end

--- Display comments in a split buffer
--- @param comments table List of comments to display
--- @param buffer number Target buffer where diff is shown
function M.display_split(comments, buffer)
  local config = require('mrreviewer.core.config')

  -- Close existing comment window if open
  if M.state.comment_window and vim.api.nvim_win_is_valid(M.state.comment_window) then
    vim.api.nvim_win_close(M.state.comment_window, true)
  end

  if #comments == 0 then
    return
  end

  -- Sort comments by line
  local sorted_comments = parsers.sort_comments_by_line(comments)

  -- Create comment buffer
  local comment_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[comment_buf].buftype = 'nofile'
  vim.bo[comment_buf].bufhidden = 'wipe'
  vim.bo[comment_buf].swapfile = false
  vim.api.nvim_buf_set_name(comment_buf, 'MRReviewer://comments')

  -- Format all comments
  local all_lines = {}
  for _, comment in ipairs(sorted_comments) do
    local line_num = M.map_to_line(comment, buffer)
    if line_num then
      table.insert(all_lines, string.format('Line %d:', line_num))
      table.insert(all_lines, '')
      local comment_lines = formatting.format_comment(comment)
      for _, line in ipairs(comment_lines) do
        table.insert(all_lines, line)
      end
    end
  end

  -- Set buffer content
  vim.api.nvim_buf_set_lines(comment_buf, 0, -1, false, all_lines)
  vim.bo[comment_buf].modifiable = false
  vim.bo[comment_buf].filetype = 'markdown'

  -- Create vertical split on the right
  local width = config.get_value('window.comment_width') or 40
  vim.cmd('rightbelow ' .. width .. ' vsplit')
  local comment_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(comment_win, comment_buf)

  -- Set window options
  vim.wo[comment_win].wrap = true
  vim.wo[comment_win].linebreak = true
  vim.wo[comment_win].number = false
  vim.wo[comment_win].relativenumber = false

  -- Store state
  local comments_state = state_module.get_comments()
  comments_state.comment_buffer = comment_buf
  comments_state.comment_window = comment_win
  comments_state.displayed_comments = sorted_comments

  -- Return focus to diff buffer
  vim.cmd('wincmd p')
end

--- Display comments as virtual text
--- @param comments table List of comments to display
--- @param buffer number Target buffer where diff is shown
function M.display_virtual_text(comments, buffer)
  -- Clear existing virtual text
  vim.api.nvim_buf_clear_namespace(buffer, M.state.namespace_id, 0, -1)

  if #comments == 0 then
    return
  end

  -- Sort comments by line
  local sorted_comments = parsers.sort_comments_by_line(comments)
  local comments_state = state_module.get_comments()
  comments_state.displayed_comments = sorted_comments

  for _, comment in ipairs(sorted_comments) do
    local line_num = M.map_to_line(comment, buffer)

    if line_num then
      -- Get highlight group based on resolved status
      local hl_group = comment.resolved
        and highlights.get_group('virtual_text_resolved')
        or highlights.get_group('virtual_text')

      -- Create virtual text
      local virt_text = string.format(
        '💬 %s: %s',
        comment.author.username or comment.author.name,
        comment.body:gsub('\n', ' '):sub(1, 60)
      )

      -- Add extmark with virtual text
      vim.api.nvim_buf_set_extmark(buffer, M.state.namespace_id, line_num - 1, 0, {
        virt_text = { { virt_text, hl_group } },
        virt_text_pos = 'eol',
        hl_mode = 'combine',
      })
    end
  end
end

--- Display comments in floating windows (like diagnostics)
--- @param comments table List of comments to display
--- @param buffer number Target buffer where diff is shown
function M.display_float(comments, buffer)
  if #comments == 0 then
    return
  end

  -- Sort comments by line
  local sorted_comments = parsers.sort_comments_by_line(comments)
  local comments_state = state_module.get_comments()
  comments_state.displayed_comments = sorted_comments

  -- No need to show anything initially - float will appear on demand
end

--- Show floating window for a specific comment
--- @param comment table Comment object to display
--- @param focus boolean|nil Whether to focus the floating window (default: false)
--- @return boolean Success status
function M.show_float(comment, focus)
  if not comment then
    return false
  end

  -- Close any existing float
  local comments_state = state_module.get_comments()
  if comments_state.comment_float_win and vim.api.nvim_win_is_valid(comments_state.comment_float_win) then
    vim.api.nvim_win_close(comments_state.comment_float_win, true)
    comments_state.comment_float_win = nil
    comments_state.comment_float_buf = nil
  end

  -- Find all comments in the same thread (by discussion_id)
  local thread_comments = { comment }
  if comment.discussion_id then
    local all_comments = comments_state.list or {}
    for _, c in ipairs(all_comments) do
      if c.discussion_id == comment.discussion_id and c.id ~= comment.id then
        table.insert(thread_comments, c)
      end
    end
    -- Sort by created_at timestamp
    table.sort(thread_comments, function(a, b)
      return a.created_at < b.created_at
    end)
  end

  -- Format comment thread for display
  local lines = {}

  for i, thread_comment in ipairs(thread_comments) do
    if i > 1 then
      -- Separator between comments in thread
      table.insert(lines, '')
      table.insert(lines, string.rep('─', 60))
      table.insert(lines, '')
    end

    local resolved_marker = thread_comment.resolved and '✓ ' or '• '
    local resolved_text = thread_comment.resolved and '(resolved)' or '(unresolved)'

    table.insert(lines, resolved_marker .. thread_comment.author.name .. ' ' .. resolved_text)

    if thread_comment.created_at then
      local date = thread_comment.created_at:match('(%d%d%d%d%-%d%d%-%d%d)')
      if date then
        table.insert(lines, date)
      end
    end

    table.insert(lines, '')

    -- Add comment body (split by newlines)
    for line in thread_comment.body:gmatch('[^\r\n]+') do
      table.insert(lines, line)
    end
  end

  -- Create floating window
  local width = 80
  local height = math.min(#lines, 20)

  local opts = {
    relative = 'cursor',
    row = 1,
    col = 0,
    width = width,
    height = height,
    style = 'minimal',
    border = 'rounded',
    focusable = true,
    zindex = 50,
  }

  -- Get the source buffer (before creating the float)
  local source_buffer = vim.api.nvim_get_current_buf()

  -- Create buffer for float
  local float_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(float_buf, 0, -1, false, lines)
  vim.bo[float_buf].modifiable = false
  vim.bo[float_buf].filetype = 'markdown'

  -- Open floating window (focus based on parameter, default false)
  local float_win = vim.api.nvim_open_win(float_buf, focus == true, opts)

  -- Ensure the window isn't in diff mode (diff is window-local, not buffer-local)
  vim.wo[float_win].diff = false

  -- Store float window
  comments_state.comment_float_win = float_win
  comments_state.comment_float_buf = float_buf

  -- Set window options
  vim.wo[float_win].wrap = true
  vim.wo[float_win].linebreak = true
  vim.wo[float_win].cursorbind = false
  vim.wo[float_win].scrollbind = false

  -- Close float function
  local close_float = function()
    local comments_state = state_module.get_comments()
    if comments_state.comment_float_win and vim.api.nvim_win_is_valid(comments_state.comment_float_win) then
      vim.api.nvim_win_close(comments_state.comment_float_win, true)
      comments_state.comment_float_win = nil
      comments_state.comment_float_buf = nil
    end
  end

  -- Set up autocommands to close the float
  local float_augroup = vim.api.nvim_create_augroup('MRReviewerFloat', { clear = true })

  -- Only set up auto-close on cursor movement if we're not focusing the window
  -- (if focused, user can manually close with q or Esc)
  if not focus then
    -- Close when cursor moves in the main buffer
    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
      group = float_augroup,
      buffer = source_buffer,
      callback = close_float,
    })
  else
    -- If focused, close when leaving the float window
    vim.api.nvim_create_autocmd('BufLeave', {
      group = float_augroup,
      buffer = float_buf,
      callback = close_float,
    })
  end

  -- Close when pressing q or Escape in the float
  vim.keymap.set('n', 'q', close_float, { buffer = float_buf, noremap = true, silent = true })
  vim.keymap.set('n', '<Esc>', close_float, { buffer = float_buf, noremap = true, silent = true })

  return true
end

--- Show floating window for comment on current line
function M.show_float_for_current_line()
  local buffer = vim.api.nvim_get_current_buf()
  local current_line = vim.api.nvim_win_get_cursor(0)[1]

  -- If float is already open and valid, enter it
  if M.state.comment_float_win and vim.api.nvim_win_is_valid(M.state.comment_float_win) then
    vim.api.nvim_set_current_win(M.state.comment_float_win)
    return
  end

  if #M.state.displayed_comments == 0 then
    return
  end

  -- Find comment(s) for current line
  local line_comments = {}
  for _, comment in ipairs(M.state.displayed_comments) do
    local line_num = M.map_to_line(comment, buffer)
    if line_num == current_line then
      table.insert(line_comments, comment)
    end
  end

  if #line_comments == 0 then
    return
  end

  -- Format comment(s) for display
  local lines = {}
  for i, comment in ipairs(line_comments) do
    if i > 1 then
      table.insert(lines, '')
      table.insert(lines, string.rep('─', 60))
      table.insert(lines, '')
    end

    local resolved_marker = comment.resolved and '✓ ' or '• '
    local resolved_text = comment.resolved and '(resolved)' or '(unresolved)'

    table.insert(lines, resolved_marker .. comment.author.name .. ' ' .. resolved_text)

    if comment.created_at then
      local date = comment.created_at:match('(%d%d%d%d%-%d%d%-%d%d)')
      if date then
        table.insert(lines, date)
      end
    end

    table.insert(lines, '')

    -- Add comment body (split by newlines)
    for line in comment.body:gmatch('[^\r\n]+') do
      table.insert(lines, line)
    end
  end

  -- Create floating window
  local width = 80
  local height = math.min(#lines, 20)

  local opts = {
    relative = 'cursor',
    row = 1,
    col = 0,
    width = width,
    height = height,
    style = 'minimal',
    border = 'rounded',
    focusable = true,
    zindex = 50,
  }

  -- Create buffer for float
  local float_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(float_buf, 0, -1, false, lines)
  vim.bo[float_buf].modifiable = false
  vim.bo[float_buf].filetype = 'markdown'

  -- Open floating window (don't focus it initially)
  local float_win = vim.api.nvim_open_win(float_buf, false, opts)

  -- Store float window
  local comments_state = state_module.get_comments()
  comments_state.comment_float_win = float_win
  comments_state.comment_float_buf = float_buf

  -- Set window options
  vim.wo[float_win].wrap = true
  vim.wo[float_win].linebreak = true

  -- Close float function
  local close_float = function()
    local comments_state = state_module.get_comments()
    if comments_state.comment_float_win and vim.api.nvim_win_is_valid(comments_state.comment_float_win) then
      vim.api.nvim_win_close(comments_state.comment_float_win, true)
      comments_state.comment_float_win = nil
      comments_state.comment_float_buf = nil
    end
  end

  -- Set up autocommands to close the float
  local float_augroup = vim.api.nvim_create_augroup('MRReviewerFloat', { clear = true })

  -- Close when cursor moves in the main buffer
  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
    group = float_augroup,
    buffer = buffer,
    callback = function()
      -- Only close if we're still in the main buffer (not in the float)
      if vim.api.nvim_get_current_win() ~= float_win then
        close_float()
      end
    end,
  })

  -- Close when leaving the float window
  vim.api.nvim_create_autocmd('WinLeave', {
    group = float_augroup,
    buffer = float_buf,
    callback = function()
      vim.schedule(close_float)
    end,
  })

  -- Close if the main buffer is closed
  vim.api.nvim_create_autocmd('BufWipeout', {
    group = float_augroup,
    buffer = buffer,
    callback = close_float,
  })

  -- Add keymaps to close float
  vim.api.nvim_buf_set_keymap(float_buf, 'n', 'q', '', {
    callback = close_float,
    noremap = true,
    silent = true,
  })
  vim.api.nvim_buf_set_keymap(float_buf, 'n', '<Esc>', '', {
    callback = close_float,
    noremap = true,
    silent = true,
  })
end

--- Place signs in the sign column for lines with comments
--- @param comments table List of comments
--- @param buffer number Target buffer
function M.place_signs(comments, buffer)
  -- Define signs if not already done
  highlights.define_signs()

  -- Clear existing signs
  vim.fn.sign_unplace('MRReviewerComments', { buffer = buffer })

  for _, comment in ipairs(comments) do
    local line_num = M.map_to_line(comment, buffer)

    if line_num then
      local sign_name = comment.resolved and 'MRReviewerCommentResolved' or 'MRReviewerComment'

      -- Use high priority so comment signs show over diff signs
      vim.fn.sign_place(0, 'MRReviewerComments', sign_name, buffer, {
        lnum = line_num,
        priority = 100,
      })
    end
  end
end

--- Display comments for a file based on configured mode
--- @param file_path string File path
--- @param buffer number Buffer number
function M.display_for_file(file_path, buffer)
  local mrreviewer = require('mrreviewer')
  local config = require('mrreviewer.core.config')

  -- Get comments from state
  local all_comments = mrreviewer.state.current_mr and mrreviewer.state.current_mr.comments
  if not all_comments then
    return
  end

  -- Filter comments for this file
  local file_comments = M.filter_by_file(all_comments, file_path)

  if #file_comments == 0 then
    return
  end

  -- Place signs in sign column
  M.place_signs(file_comments, buffer)

  -- Display based on mode
  local mode = config.get_value('comment_display_mode')
  if mode == 'virtual_text' then
    M.display_virtual_text(file_comments, buffer)
  elseif mode == 'float' then
    M.display_float(file_comments, buffer)
  else
    M.display_split(file_comments, buffer)
  end
end

--- Navigate to next comment
function M.next_comment()
  if #M.state.displayed_comments == 0 then
    utils.notify('No comments to navigate', 'warn')
    return
  end

  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local buffer = vim.api.nvim_get_current_buf()

  -- Find next comment after current line
  for _, comment in ipairs(M.state.displayed_comments) do
    local line = M.map_to_line(comment, buffer)
    if line and line > current_line then
      vim.api.nvim_win_set_cursor(0, { line, 0 })
      return
    end
  end

  -- Wrap to first comment
  local first_line = M.map_to_line(M.state.displayed_comments[1], buffer)
  if first_line then
    vim.api.nvim_win_set_cursor(0, { first_line, 0 })
  end
end

--- Navigate to previous comment
function M.prev_comment()
  if #M.state.displayed_comments == 0 then
    utils.notify('No comments to navigate', 'warn')
    return
  end

  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local buffer = vim.api.nvim_get_current_buf()

  -- Find previous comment before current line (iterate backwards)
  for i = #M.state.displayed_comments, 1, -1 do
    local comment = M.state.displayed_comments[i]
    local line = M.map_to_line(comment, buffer)
    if line and line < current_line then
      vim.api.nvim_win_set_cursor(0, { line, 0 })
      return
    end
  end

  -- Wrap to last comment
  local last_line = M.map_to_line(M.state.displayed_comments[#M.state.displayed_comments], buffer)
  if last_line then
    vim.api.nvim_win_set_cursor(0, { last_line, 0 })
  end
end

--- Toggle comment display mode
function M.toggle_mode()
  local config = require('mrreviewer.core.config')
  local current_mode = config.get_value('comment_display_mode')

  -- Cycle through modes: split -> virtual_text -> float -> split
  local new_mode
  if current_mode == 'split' then
    new_mode = 'virtual_text'
  elseif current_mode == 'virtual_text' then
    new_mode = 'float'
  else
    new_mode = 'split'
  end

  config.options.comment_display_mode = new_mode

  -- Refresh display if we have displayed comments
  if #M.state.displayed_comments > 0 then
    local buffer = vim.api.nvim_get_current_buf()
    -- Get file path from buffer name
    local buf_name = vim.api.nvim_buf_get_name(buffer)
    local file_path = buf_name:match('MRReviewer://(.+)')

    if file_path then
      M.display_for_file(file_path, buffer)
    end
  end
end

--- Clear all comment displays
function M.clear()
  local comments_state = state_module.get_comments()

  -- Close comment window
  if comments_state.comment_window and vim.api.nvim_win_is_valid(comments_state.comment_window) then
    vim.api.nvim_win_close(comments_state.comment_window, true)
  end

  -- Close float window
  if comments_state.comment_float_win and vim.api.nvim_win_is_valid(comments_state.comment_float_win) then
    vim.api.nvim_win_close(comments_state.comment_float_win, true)
  end

  -- Clear virtual text from all buffers
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_clear_namespace(buf, comments_state.namespace_id, 0, -1)
      vim.fn.sign_unplace('MRReviewerComments', { buffer = buf })
    end
  end

  -- Clear state using centralized method
  state_module.clear_comments()
end

return M
