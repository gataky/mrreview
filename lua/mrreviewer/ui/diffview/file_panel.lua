-- lua/mrreviewer/ui/diffview/file_panel.lua
-- File tree panel with comment count indicators for diffview

local M = {}
local state = require('mrreviewer.core.state')
local logger = require('mrreviewer.core.logger')
local highlights = require('mrreviewer.ui.highlights')
local file_tree = require('mrreviewer.ui.diffview.file_tree')
local config = require('mrreviewer.core.config')

-- Cache for last rendered data (for re-rendering after toggle)
local render_cache = {
  files = nil,
  comments = nil,
}

--- Check if a directory is collapsed
--- @param dir_path string The directory path to check
--- @return boolean True if directory is collapsed
function M.is_directory_collapsed(dir_path)
  local diffview = state.get_diffview()
  return diffview.collapsed_dirs[dir_path] == true
end

--- Toggle directory collapse/expand state
--- @param dir_path string The directory path to toggle
--- @return boolean New collapsed state (true if now collapsed)
function M.toggle_directory(dir_path)
  if not dir_path or dir_path == '' then
    logger.warn('file_panel', 'toggle_directory called with invalid path')
    return false
  end

  local diffview = state.get_diffview()
  local current_state = diffview.collapsed_dirs[dir_path]

  -- Toggle the state
  if current_state then
    diffview.collapsed_dirs[dir_path] = nil -- Remove from table (expanded)
    logger.info('file_panel', 'Expanded directory', { path = dir_path })
    return false
  else
    diffview.collapsed_dirs[dir_path] = true -- Add to table (collapsed)
    logger.info('file_panel', 'Collapsed directory', { path = dir_path })
    return true
  end
end

--- Collapse all directories in the tree
function M.collapse_all()
  -- This will be called with the tree structure to collapse all directories
  -- For now, we'll implement this when we have the tree rendering
  logger.info('file_panel', 'Collapse all directories')
  -- Implementation will be added when tree rendering is complete
end

--- Expand all directories in the tree
function M.expand_all()
  local diffview = state.get_diffview()
  diffview.collapsed_dirs = {}
  logger.info('file_panel', 'Expanded all directories')
end

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

--- Get the node at the current cursor position
--- @return table|nil Node info: {path: string, kind: string, depth: number} or nil if not found
function M.get_node_at_cursor()
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1] -- 1-indexed

  -- Get node metadata from buffer
  local buf = vim.api.nvim_get_current_buf()
  local ok, node_metadata = pcall(vim.api.nvim_buf_get_var, buf, 'mrreviewer_file_tree_nodes')

  if not ok or not node_metadata then
    logger.warn('file_panel', 'No node metadata found in buffer')
    return nil
  end

  -- Get node at cursor line
  local node_info = node_metadata[cursor_line]
  if not node_info then
    logger.warn('file_panel', 'No node at cursor line', { line = cursor_line })
    return nil
  end

  return node_info
end

--- Get the file path at the current cursor position
--- @return string|nil File path or nil if not found
function M.get_file_at_cursor()
  local node_info = M.get_node_at_cursor()

  -- Only return path if it's a file node
  if node_info and node_info.kind == 'file' then
    return node_info.path
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

  -- Enter to toggle directories or select files (task 5.3)
  vim.keymap.set('n', '<CR>', function()
    local node_info = M.get_node_at_cursor()
    if not node_info then
      return
    end

    if node_info.kind == 'dir' then
      -- Toggle directory collapse/expand
      M.toggle_directory(node_info.path)
      -- Re-render to show changes (task 5.7)
      M.render_current(buf, on_file_selected_callback)
    elseif node_info.kind == 'file' then
      -- Select file (task 5.6)
      M.on_file_selected(node_info.path, on_file_selected_callback)
    end
  end, opts)

  -- Tab to toggle directory collapse/expand (task 5.4)
  vim.keymap.set('n', '<Tab>', function()
    local node_info = M.get_node_at_cursor()
    if node_info and node_info.kind == 'dir' then
      M.toggle_directory(node_info.path)
      M.render_current(buf, on_file_selected_callback)
    end
  end, opts)

  -- za (vim-style fold toggle) for directories (task 5.5)
  vim.keymap.set('n', 'za', function()
    local node_info = M.get_node_at_cursor()
    if node_info and node_info.kind == 'dir' then
      M.toggle_directory(node_info.path)
      M.render_current(buf, on_file_selected_callback)
    end
  end, opts)

  logger.debug('file_panel','File panel keymaps set up for buffer ' .. buf)
end

--- Apply syntax highlighting to tree elements (icons, names, indentation)
--- @param buf number Buffer ID
--- @param visible_nodes table List of visible nodes
--- @param indent_size number Number of spaces per indentation level
local function apply_tree_highlights(buf, visible_nodes, indent_size)
  local ns_id = vim.api.nvim_create_namespace('mrreviewer_file_tree_highlights')
  vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)

  for line_idx, node in ipairs(visible_nodes) do
    local line_num = line_idx - 1 -- 0-indexed for nvim API
    local line = vim.api.nvim_buf_get_lines(buf, line_num, line_num + 1, false)[1]
    if not line then
      goto continue
    end

    -- Use byte offsets instead of display width for accurate highlighting
    local byte_offset = 0

    -- Highlight indentation (subtle guide lines)
    if node.depth > 0 then
      local indent_bytes = node.depth * indent_size
      vim.api.nvim_buf_add_highlight(
        buf,
        ns_id,
        highlights.get_group('tree_indent'),
        line_num,
        byte_offset,
        byte_offset + indent_bytes
      )
      byte_offset = byte_offset + indent_bytes
    end

    -- Get the actual icon from config
    local icon
    if node:is_dir() then
      if state.get_diffview().collapsed_dirs[node.path] then
        icon = config.get_value('diffview.file_tree.dir_collapsed_icon') or '▸'
      else
        icon = config.get_value('diffview.file_tree.dir_expanded_icon') or '▾'
      end
    else
      icon = config.get_value('diffview.file_tree.file_icon') or '•'
    end

    -- Highlight icon (use byte length, not display width)
    local icon_bytes = #icon
    vim.api.nvim_buf_add_highlight(
      buf,
      ns_id,
      node:is_dir() and highlights.get_group('folder_sign') or highlights.get_group('file_sign'),
      line_num,
      byte_offset,
      byte_offset + icon_bytes
    )
    byte_offset = byte_offset + icon_bytes + 1 -- +1 for space after icon

    -- Highlight name (use byte length of name)
    local name_bytes = #node.name
    vim.api.nvim_buf_add_highlight(
      buf,
      ns_id,
      node:is_dir() and highlights.get_group('folder_name') or highlights.get_group('file_name'),
      line_num,
      byte_offset,
      byte_offset + name_bytes
    )
    byte_offset = byte_offset + name_bytes

    -- Highlight comment count if present
    if node:is_file() and node.comment_count and node.comment_count.total > 0 then
      -- Skip the "  " before the comment icon
      byte_offset = byte_offset + 2
      -- Highlight the entire comment count display
      vim.api.nvim_buf_add_highlight(
        buf,
        ns_id,
        highlights.get_group('comment_count'),
        line_num,
        byte_offset,
        -1 -- to end of line
      )
    end

    ::continue::
  end
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

  -- Get node metadata from buffer (task 4.7)
  local ok, node_metadata = pcall(vim.api.nvim_buf_get_var, buf, 'mrreviewer_file_tree_nodes')
  if not ok or not node_metadata then
    logger.warn('file_panel', 'No node metadata found in buffer for highlighting')
    return
  end

  -- Find the line containing the selected file by matching node path (task 4.7)
  for i, node_info in ipairs(node_metadata) do
    if node_info.kind == 'file' and node_info.path == selected_file then
      -- Highlight this line (0-indexed)
      vim.api.nvim_buf_add_highlight(
        buf,
        ns_id,
        highlights.get_group('file_panel_selected'),
        i - 1,
        0,
        -1
      )
      break
    end
  end
end

--- Re-render the file panel with cached data and preserve cursor position (tasks 5.7, 5.8)
--- @param buf number Buffer ID
--- @param on_file_selected_callback function|nil Optional callback when file is selected
function M.render_current(buf, on_file_selected_callback)
  if not render_cache.files then
    logger.warn('file_panel', 'Cannot re-render: no cached files')
    return
  end

  -- Save cursor position (task 5.8)
  local cursor_pos = vim.api.nvim_win_get_cursor(0)

  -- Re-render with cached data
  M.render(render_cache.files, render_cache.comments, buf, on_file_selected_callback)

  -- Restore cursor position (task 5.8)
  -- Make sure cursor is within bounds
  local line_count = vim.api.nvim_buf_line_count(buf)
  if cursor_pos[1] > line_count then
    cursor_pos[1] = line_count
  end
  pcall(vim.api.nvim_win_set_cursor, 0, cursor_pos)
end

--- Render the file panel with hierarchical tree structure
--- @param files table List of file paths
--- @param comments table List of comments
--- @param buf number|nil Buffer ID (if nil, uses current diffview buffer)
--- @param on_file_selected_callback function|nil Optional callback when file is selected
function M.render(files, comments, buf, on_file_selected_callback)
  if not files or #files == 0 then
    logger.warn('file_panel','No files provided to file_panel.render')
    return
  end

  -- Cache files and comments for re-rendering (task 5.7)
  render_cache.files = files
  render_cache.comments = comments

  -- Get buffer from state if not provided
  if not buf then
    local diffview = state.get_diffview()
    buf = diffview.panel_buffers.files
  end

  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    logger.error('file_panel','Invalid buffer for file panel')
    return
  end

  -- Build tree from file paths (tasks 4.3)
  local tree = file_tree.build_tree(files, comments)

  -- Get collapsed state from diffview
  local diffview = state.get_diffview()
  local collapsed_state = diffview.collapsed_dirs or {}

  -- Flatten visible nodes respecting collapsed state (task 4.3)
  local visible_nodes = file_tree.flatten_visible_nodes(tree, collapsed_state)

  -- Get configuration values (task 4.4)
  local indent_size = config.get_value('diffview.file_tree.indent') or 2
  local dir_collapsed_icon = config.get_value('diffview.file_tree.dir_collapsed_icon') or '▸'
  local dir_expanded_icon = config.get_value('diffview.file_tree.dir_expanded_icon') or '▾'
  local file_icon = config.get_value('diffview.file_tree.file_icon') or '•'

  -- Build content lines with tree formatting (tasks 4.4, 4.5, 4.6)
  local lines = {}
  local node_metadata = {} -- Store node info for each line (task 4.8)

  for _, node in ipairs(visible_nodes) do
    -- Calculate indentation based on depth (task 4.4)
    local indent = string.rep(' ', node.depth * indent_size)

    -- Determine icon based on node type and state (task 4.5)
    local icon
    if node:is_dir() then
      if collapsed_state[node.path] then
        icon = dir_collapsed_icon
      else
        icon = dir_expanded_icon
      end
    else
      icon = file_icon
    end

    -- Build line with indentation, icon, and name
    local line = indent .. icon .. ' ' .. node.name

    -- Add comment count for files (task 4.6)
    if node:is_file() and node.comment_count and node.comment_count.total > 0 then
      line = line .. string.format('  💬 %d/%d', node.comment_count.resolved, node.comment_count.total)
    end

    table.insert(lines, line)

    -- Store node metadata for cursor operations (task 4.8)
    table.insert(node_metadata, {
      path = node.path,
      kind = node.kind,
      depth = node.depth,
    })
  end

  -- Set buffer content
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  -- Store node metadata in buffer variable (task 4.8)
  vim.api.nvim_buf_set_var(buf, 'mrreviewer_file_tree_nodes', node_metadata)

  -- Apply syntax highlighting to tree elements
  apply_tree_highlights(buf, visible_nodes, indent_size)

  -- Apply highlighting for selected file
  highlight_selected_file(buf, diffview.selected_file)

  -- Setup keymaps
  M.setup_keymaps(buf, on_file_selected_callback)

  logger.info('file_panel','File panel rendered with ' .. #visible_nodes .. ' visible nodes')
end

return M
