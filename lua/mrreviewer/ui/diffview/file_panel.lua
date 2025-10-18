-- lua/mrreviewer/ui/diffview/file_panel.lua
-- File tree panel with comment count indicators for diffview

local M = {}
local state = require('mrreviewer.core.state')
local logger = require('mrreviewer.core.logger')
local highlights = require('mrreviewer.ui.highlights')

--- Calculate comment counts for a specific file
--- @param file_path string The file path to count comments for
--- @param comments table List of all comments
--- @return table Comment counts: {resolved: number, total: number}
function M.calculate_comment_counts(file_path, comments)
  if not comments or #comments == 0 then
    return { resolved = 0, total = 0 }
  end

  local resolved = 0
  local total = 0

  for _, comment in ipairs(comments) do
    -- Match comments by new_path or old_path
    if comment.position then
      local matches = false
      if comment.position.new_path == file_path or comment.position.old_path == file_path then
        matches = true
      end

      if matches then
        total = total + 1
        if comment.resolved then
          resolved = resolved + 1
        end
      end
    end
  end

  return { resolved = resolved, total = total }
end

--- Sort files using natural file system ordering
--- Directories before files, alphabetical within each group
--- @param files table List of file paths
--- @return table Sorted list of file paths
local function sort_files_naturally(files)
  local sorted = vim.deepcopy(files)

  table.sort(sorted, function(a, b)
    -- Check if paths are directories (end with /)
    local a_is_dir = a:match('/$') ~= nil
    local b_is_dir = b:match('/$') ~= nil

    -- Directories come before files
    if a_is_dir and not b_is_dir then
      return true
    elseif not a_is_dir and b_is_dir then
      return false
    end

    -- Within the same type, sort alphabetically
    return a < b
  end)

  return sorted
end

--- Get the file path at the current cursor position
--- @return string|nil File path or nil if not found
function M.get_file_at_cursor()
  local line = vim.api.nvim_get_current_line()

  -- Remove leading whitespace and comment indicator
  -- Format is: "  <filename>  💬 <resolved>/<total>" or "  <filename>"
  local file_path = line:match('^%s*(.-)%s*💬') or line:match('^%s*(.-)%s*$')

  if file_path and file_path ~= '' then
    return file_path
  end

  return nil
end

--- Callback when a file is selected
--- Updates state and triggers diff panel update
--- @param file_path string The selected file path
--- @param on_file_selected_callback function|nil Optional callback to trigger diff update
function M.on_file_selected(file_path, on_file_selected_callback)
  if not file_path or file_path == '' then
    logger.warn('file_panel','No file path provided to on_file_selected')
    return
  end

  logger.debug('file_panel','File selected: ' .. file_path)

  -- Update state
  local diffview = state.get_diffview()
  diffview.selected_file = file_path

  -- Trigger callback if provided (to update diff panel)
  if on_file_selected_callback and type(on_file_selected_callback) == 'function' then
    on_file_selected_callback(file_path)
  end

  -- Re-render to update highlighting
  -- This will be called from the render function after setup
end

--- Setup keymaps for the file panel buffer
--- @param buf number Buffer ID
--- @param on_file_selected_callback function|nil Optional callback when file is selected
function M.setup_keymaps(buf, on_file_selected_callback)
  local opts = { noremap = true, silent = true, buffer = buf }

  -- j/k navigation (already works by default, but we can add custom behavior if needed)
  -- These are standard vim motions, so no need to remap

  -- Enter to select file
  vim.keymap.set('n', '<CR>', function()
    local file_path = M.get_file_at_cursor()
    if file_path then
      M.on_file_selected(file_path, on_file_selected_callback)
    end
  end, opts)

  logger.debug('file_panel','File panel keymaps set up for buffer ' .. buf)
end

--- Apply highlighting to the currently selected file
--- @param buf number Buffer ID
--- @param selected_file string|nil Currently selected file path
local function highlight_selected_file(buf, selected_file)
  if not selected_file then
    return
  end

  -- Clear existing highlights
  local ns_id = vim.api.nvim_create_namespace('mrreviewer_file_panel')
  vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)

  -- Find the line containing the selected file
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for i, line in ipairs(lines) do
    local file_path = line:match('^%s*(.-)%s*💬') or line:match('^%s*(.-)%s*$')
    if file_path == selected_file then
      -- Highlight this line (0-indexed)
      vim.api.nvim_buf_add_highlight(
        buf,
        ns_id,
        highlights.get_group('selected_comment'),
        i - 1,
        0,
        -1
      )
      break
    end
  end
end

--- Render the file panel with comment indicators
--- @param files table List of file paths
--- @param comments table List of comments
--- @param buf number|nil Buffer ID (if nil, uses current diffview buffer)
--- @param on_file_selected_callback function|nil Optional callback when file is selected
function M.render(files, comments, buf, on_file_selected_callback)
  if not files or #files == 0 then
    logger.warn('file_panel','No files provided to file_panel.render')
    return
  end

  -- Get buffer from state if not provided
  if not buf then
    local diffview = state.get_diffview()
    buf = diffview.panel_buffers.files
  end

  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    logger.error('file_panel','Invalid buffer for file panel')
    return
  end

  -- Sort files naturally
  local sorted_files = sort_files_naturally(files)

  -- Build content lines
  local lines = {}
  for _, file_path in ipairs(sorted_files) do
    local counts = M.calculate_comment_counts(file_path, comments)

    local line
    if counts.total > 0 then
      -- Format: "  <filename>  💬 <resolved>/<total>"
      line = string.format('  %s  💬 %d/%d', file_path, counts.resolved, counts.total)
    else
      -- Format: "  <filename>"
      line = string.format('  %s', file_path)
    end

    table.insert(lines, line)
  end

  -- Set buffer content
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  -- Apply highlighting for selected file
  local diffview = state.get_diffview()
  highlight_selected_file(buf, diffview.selected_file)

  -- Setup keymaps
  M.setup_keymaps(buf, on_file_selected_callback)

  logger.info('file_panel','File panel rendered with ' .. #sorted_files .. ' files')
end

return M
