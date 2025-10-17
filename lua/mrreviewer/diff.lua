-- lua/mrreviewer/diff.lua
-- Diff view creation, layout, and buffer management

local M = {}
local utils = require('mrreviewer.utils')
local Job = require('plenary.job')

-- Store current diff view state
M.state = {
  buffers = {},
  windows = {},
  current_file_index = 1,
  files = {},
}

--- Get changed files from MR data
--- @param mr_data table MR details
--- @return table List of changed files
function M.get_changed_files(mr_data)
  local files = {}

  -- Check if changes exist
  if not mr_data or not mr_data.changes then
    return files
  end

  for _, change in ipairs(mr_data.changes) do
    table.insert(files, {
      path = change.new_path or change.path,
      old_path = change.old_path or change.path,
      new_path = change.new_path or change.path,
      new_file = change.new_file or false,
      deleted_file = change.deleted_file or false,
      renamed_file = change.renamed_file or false,
    })
  end

  return files
end

--- Fetch file content from a specific git ref
--- @param file_path string File path
--- @param ref string Git ref (commit sha, branch name, etc.)
--- @return table|nil Lines of file content or nil
function M.fetch_file_versions(file_path, ref)
  if not file_path or not ref then
    return nil
  end

  local job = Job:new({
    command = 'git',
    args = { 'show', ref .. ':' .. file_path },
  })

  local ok, result = pcall(function()
    job:sync(5000)
    return job:result()
  end)

  if not ok or job.code ~= 0 then
    -- File might not exist in this ref (new file or deleted)
    return {}
  end

  return result
end

--- Create side-by-side diff layout
--- @param old_lines table Lines from target branch
--- @param new_lines table Lines from source branch
--- @param file_info table File information
--- @return number, number Buffer numbers for old and new
function M.create_side_by_side_layout(old_lines, new_lines, file_info)
  local config = require('mrreviewer.config')

  -- Save current window
  local current_win = vim.api.nvim_get_current_win()

  -- Create vertical split
  vim.cmd('vsplit')

  -- Create buffers
  local old_buf = vim.api.nvim_create_buf(false, true)
  local new_buf = vim.api.nvim_create_buf(false, true)

  -- Get windows
  local left_win = vim.api.nvim_get_current_win()
  vim.cmd('wincmd h')
  local right_win = vim.api.nvim_get_current_win()

  -- Set buffers in windows
  vim.api.nvim_win_set_buf(right_win, old_buf)
  vim.api.nvim_win_set_buf(left_win, new_buf)

  -- Set buffer content
  vim.api.nvim_buf_set_lines(old_buf, 0, -1, false, old_lines)
  vim.api.nvim_buf_set_lines(new_buf, 0, -1, false, new_lines)

  -- Set buffer options for old (target) file
  vim.api.nvim_buf_set_option(old_buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(old_buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(old_buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(old_buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(old_buf, 'readonly', true)

  -- Set filetype for syntax highlighting
  local file_path = file_info.old_path or file_info.path
  if file_path then
    local ft = vim.filetype.match({ filename = file_path })
    if ft then
      vim.api.nvim_buf_set_option(old_buf, 'filetype', ft)
    end
  end

  -- Set buffer options for new (source) file
  vim.api.nvim_buf_set_option(new_buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(new_buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(new_buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(new_buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(new_buf, 'readonly', true)

  -- Set filetype for syntax highlighting
  file_path = file_info.new_path or file_info.path
  if file_path then
    local ft = vim.filetype.match({ filename = file_path })
    if ft then
      vim.api.nvim_buf_set_option(new_buf, 'filetype', ft)
    end
  end

  -- Set buffer names
  vim.api.nvim_buf_set_name(old_buf, 'MRReviewer://old/' .. (file_info.old_path or file_info.path))
  vim.api.nvim_buf_set_name(new_buf, 'MRReviewer://new/' .. (file_info.new_path or file_info.path))

  -- Enable diff mode
  vim.api.nvim_win_set_option(right_win, 'diff', true)
  vim.api.nvim_win_set_option(left_win, 'diff', true)

  -- Enable synchronized scrolling if configured
  if config.get_value('window.sync_scroll') then
    vim.api.nvim_win_set_option(right_win, 'scrollbind', true)
    vim.api.nvim_win_set_option(left_win, 'scrollbind', true)
    vim.api.nvim_win_set_option(right_win, 'cursorbind', true)
    vim.api.nvim_win_set_option(left_win, 'cursorbind', true)
  end

  -- Store state
  M.state.buffers = { old = old_buf, new = new_buf }
  M.state.windows = { old = right_win, new = left_win }

  return old_buf, new_buf
end

--- Open diff view for a specific file in the MR
--- @param mr_data table MR details with diff_refs
--- @param file_info table File information
function M.open_file_diff(mr_data, file_info)
  if not mr_data or not file_info then
    utils.notify('Missing MR data or file info', 'error')
    return
  end

  local base_sha = mr_data.diff_refs and mr_data.diff_refs.base_sha
  local head_sha = mr_data.diff_refs and mr_data.diff_refs.head_sha

  if not base_sha or not head_sha then
    utils.notify('Missing diff refs in MR data', 'error')
    return
  end

  utils.notify('Loading diff for ' .. file_info.path .. '...', 'info')

  -- Fetch file versions
  local old_lines = M.fetch_file_versions(file_info.old_path, base_sha)
  local new_lines = M.fetch_file_versions(file_info.new_path, head_sha)

  if not old_lines or not new_lines then
    utils.notify('Failed to fetch file versions', 'error')
    return
  end

  -- Create diff view
  M.create_side_by_side_layout(old_lines, new_lines, file_info)

  utils.notify('Loaded diff for ' .. file_info.path, 'info')
end

--- Close the current diff view
function M.close()
  -- Close windows
  for _, win in pairs(M.state.windows) do
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  -- Clear state
  M.state.buffers = {}
  M.state.windows = {}
  M.state.current_file_index = 1
  M.state.files = {}
end

--- Navigate to next file in MR
function M.next_file()
  if #M.state.files == 0 then
    utils.notify('No files to navigate', 'warn')
    return
  end

  M.state.current_file_index = M.state.current_file_index + 1
  if M.state.current_file_index > #M.state.files then
    M.state.current_file_index = 1
  end

  local mrreviewer = require('mrreviewer')
  local mr_data = mrreviewer.state.current_mr and mrreviewer.state.current_mr.data

  if mr_data then
    M.close()
    M.open_file_diff(mr_data, M.state.files[M.state.current_file_index])
  end
end

--- Navigate to previous file in MR
function M.prev_file()
  if #M.state.files == 0 then
    utils.notify('No files to navigate', 'warn')
    return
  end

  M.state.current_file_index = M.state.current_file_index - 1
  if M.state.current_file_index < 1 then
    M.state.current_file_index = #M.state.files
  end

  local mrreviewer = require('mrreviewer')
  local mr_data = mrreviewer.state.current_mr and mrreviewer.state.current_mr.data

  if mr_data then
    M.close()
    M.open_file_diff(mr_data, M.state.files[M.state.current_file_index])
  end
end

--- Set up keymaps for diff navigation
local function setup_keymaps()
  local config = require('mrreviewer.config')
  local keymaps = config.get_value('keymaps')

  if not keymaps then
    return
  end

  -- Set keymaps for both buffers
  for _, buf in pairs(M.state.buffers) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_set_keymap(buf, 'n', keymaps.next_file or ']f', '', {
        callback = M.next_file,
        noremap = true,
        silent = true,
        desc = 'Next file in MR',
      })

      vim.api.nvim_buf_set_keymap(buf, 'n', keymaps.prev_file or '[f', '', {
        callback = M.prev_file,
        noremap = true,
        silent = true,
        desc = 'Previous file in MR',
      })

      vim.api.nvim_buf_set_keymap(buf, 'n', keymaps.close or 'q', '', {
        callback = M.close,
        noremap = true,
        silent = true,
        desc = 'Close diff view',
      })
    end
  end
end

--- Open diff view for an MR
--- @param mr_data table MR details
function M.open(mr_data)
  if not mr_data then
    utils.notify('No MR data provided', 'error')
    return
  end

  -- Get changed files
  local files = M.get_changed_files(mr_data)
  if #files == 0 then
    utils.notify('No changed files in MR', 'warn')
    return
  end

  M.state.files = files
  M.state.current_file_index = 1

  -- Open first file
  M.open_file_diff(mr_data, files[1])

  -- Set up keymaps
  setup_keymaps()
end

return M
