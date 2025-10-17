-- lua/mrreviewer/diff.lua
-- Diff view creation, layout, and buffer management

local M = {}
local utils = require('mrreviewer.utils')
local Job = require('plenary.job')
local comments = require('mrreviewer.comments')

-- Store current diff view state
M.state = {
  buffers = {},
  windows = {},
  current_file_index = 1,
  files = {},
}

--- Get changed files from MR data using git diff
--- @param mr_data table MR details with diff_refs
--- @return table List of changed files
function M.get_changed_files(mr_data)
  local files = {}

  if not mr_data then
    return files
  end

  -- First try to use changes from API if available
  if mr_data.changes and #mr_data.changes > 0 then
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

  -- Fall back to using git diff to get changed files
  local base_sha = mr_data.diff_refs and mr_data.diff_refs.base_sha
  local head_sha = mr_data.diff_refs and mr_data.diff_refs.head_sha

  if not base_sha or not head_sha then
    utils.notify('Missing diff refs (base_sha/head_sha) in MR data', 'error')
    return files
  end

  -- Get repo root for running git commands
  local project = require('mrreviewer.project')
  local repo_root = project.get_repo_root()

  -- Ensure we have the commits locally by fetching if needed
  local fetch_job = Job:new({
    command = 'git',
    args = { 'fetch', 'origin', base_sha, head_sha },
    cwd = repo_root,
  })

  pcall(function()
    fetch_job:sync(10000) -- 10 second timeout for fetch
  end)

  -- Use git diff to get list of changed files
  local job = Job:new({
    command = 'git',
    args = { 'diff', '--name-status', base_sha, head_sha },
    cwd = repo_root,
  })

  local ok, result = pcall(function()
    job:sync(5000)
    return job:result()
  end)

  if not ok or job.code ~= 0 then
    utils.notify('Failed to get changed files using git diff', 'error')
    return files
  end

  -- Parse git diff output
  -- Format is: <status><tab><file_path>
  -- Status can be: A (added), M (modified), D (deleted), R (renamed)
  for _, line in ipairs(result) do
    local status, path = line:match('^(%a)%s+(.+)$')
    if status and path then
      table.insert(files, {
        path = path,
        old_path = path,
        new_path = path,
        new_file = status == 'A',
        deleted_file = status == 'D',
        renamed_file = status == 'R',
      })
    end
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

  -- Get repo root for running git commands
  local project = require('mrreviewer.project')
  local repo_root = project.get_repo_root()

  local job = Job:new({
    command = 'git',
    args = { 'show', ref .. ':' .. file_path },
    cwd = repo_root,
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

--- Create unified diff view (single buffer with highlighted changes)
--- @param old_lines table Lines from target branch
--- @param new_lines table Lines from source branch
--- @param file_info table File information
--- @return number Buffer number
function M.create_unified_view(old_lines, new_lines, file_info)
  -- Ensure signs are defined
  local highlights = require('mrreviewer.highlights')
  highlights.define_signs()

  -- Create a namespace for diff highlights
  local ns_id = vim.api.nvim_create_namespace('mrreviewer_diff')

  -- Get or create the main window
  local win = vim.api.nvim_get_current_win()

  -- Create buffer for the new version
  local buf = vim.api.nvim_create_buf(false, true)

  -- Set buffer in window
  vim.api.nvim_win_set_buf(win, buf)

  -- Set buffer content (new version)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)

  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'readonly', true)

  -- Set filetype for syntax highlighting
  local file_path = file_info.new_path or file_info.path
  if file_path then
    local ft = vim.filetype.match({ filename = file_path })
    if ft then
      vim.api.nvim_buf_set_option(buf, 'filetype', ft)
    end
  end

  -- Set buffer name
  vim.api.nvim_buf_set_name(buf, 'MRReviewer://' .. (file_info.new_path or file_info.path))

  -- Compute diff and highlight changes
  local diff_result = vim.diff(table.concat(old_lines, '\n'), table.concat(new_lines, '\n'), {
    result_type = 'indices',
    algorithm = 'histogram',
  })

  -- Apply highlights for changed lines
  if diff_result then
    for _, hunk in ipairs(diff_result) do
      local old_start, old_count, new_start, new_count = hunk[1], hunk[2], hunk[3], hunk[4]

      -- Highlight added lines (green background)
      if old_count == 0 and new_count > 0 then
        for i = 0, new_count - 1 do
          vim.api.nvim_buf_set_extmark(buf, ns_id, new_start - 1 + i, 0, {
            end_line = new_start + i,
            hl_group = 'DiffAdd',
            hl_eol = true,
            priority = 100,
          })
          -- Add sign for added lines
          vim.fn.sign_place(0, 'MRReviewerDiff', 'MRReviewerDiffAdd', buf, {
            lnum = new_start + i,
            priority = 10,
          })
        end
      -- Highlight deleted lines (show as virtual text)
      elseif old_count > 0 and new_count == 0 then
        -- Show deletion indicator at the line before
        local line = math.max(0, new_start - 1)
        vim.api.nvim_buf_set_extmark(buf, ns_id, line, 0, {
          virt_lines = { { { string.format('  ▼ %d line(s) deleted', old_count), 'DiffDelete' } } },
          virt_lines_above = false,
          priority = 100,
        })
      -- Highlight modified lines (yellow background)
      elseif old_count > 0 and new_count > 0 then
        for i = 0, new_count - 1 do
          vim.api.nvim_buf_set_extmark(buf, ns_id, new_start - 1 + i, 0, {
            end_line = new_start + i,
            hl_group = 'DiffChange',
            hl_eol = true,
            priority = 100,
          })
          -- Add sign for changed lines
          vim.fn.sign_place(0, 'MRReviewerDiff', 'MRReviewerDiffChange', buf, {
            lnum = new_start + i,
            priority = 10,
          })
        end
      end
    end
  end

  -- Store state (single buffer now)
  M.state.buffers = { new = buf }
  M.state.windows = { new = win }

  return buf
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

  -- Create unified diff view
  local buf = M.create_unified_view(old_lines, new_lines, file_info)

  -- Display comments for the buffer
  comments.display_for_file(file_info.new_path or file_info.path, buf)

  utils.notify('Loaded diff for ' .. file_info.path, 'info')
end

--- Close the current diff view
function M.close()
  -- Clear comments
  comments.clear()

  -- Close windows safely (only if not the last window)
  local total_windows = #vim.api.nvim_list_wins()
  local windows_to_close = vim.tbl_count(M.state.windows)

  -- Only close windows if there will be at least one window remaining
  if total_windows > windows_to_close then
    for _, win in pairs(M.state.windows) do
      if vim.api.nvim_win_is_valid(win) then
        pcall(vim.api.nvim_win_close, win, true)
      end
    end
  else
    -- If these are the last windows, just wipe the buffers instead
    for _, buf in pairs(M.state.buffers) do
      if vim.api.nvim_buf_is_valid(buf) then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
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
    -- Clear comments but keep windows open
    comments.clear()

    -- Load the new file diff in existing windows
    M.load_file_in_existing_windows(mr_data, M.state.files[M.state.current_file_index])
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
    -- Clear comments but keep windows open
    comments.clear()

    -- Load the new file diff in existing windows
    M.load_file_in_existing_windows(mr_data, M.state.files[M.state.current_file_index])
  end
end

--- Load a new file in existing window
--- @param mr_data table MR details
--- @param file_info table File information
function M.load_file_in_existing_windows(mr_data, file_info)
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

  -- Get existing buffer
  local buf = M.state.buffers.new

  if buf and vim.api.nvim_buf_is_valid(buf) then
    -- Clear all extmarks from previous file
    local ns_id = vim.api.nvim_create_namespace('mrreviewer_diff')
    vim.api.nvim_buf_clear_namespace(buf, ns_id, 0, -1)
    vim.fn.sign_unplace('MRReviewerDiff', { buffer = buf })

    -- Make buffer modifiable temporarily and do all modifications
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_option(buf, 'readonly', false)

    -- Update buffer content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)

    -- Update buffer name
    pcall(vim.api.nvim_buf_set_name, buf, 'MRReviewer://' .. (file_info.new_path or file_info.path))

    -- Update filetype
    local ft = vim.filetype.match({ filename = file_info.new_path or file_info.path })
    if ft then
      vim.api.nvim_buf_set_option(buf, 'filetype', ft)
    end

    -- Set back to readonly
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    vim.api.nvim_buf_set_option(buf, 'readonly', true)

    -- Re-apply diff highlights
    local diff_result = vim.diff(table.concat(old_lines, '\n'), table.concat(new_lines, '\n'), {
      result_type = 'indices',
      algorithm = 'histogram',
    })

    if diff_result then
      for _, hunk in ipairs(diff_result) do
        local old_start, old_count, new_start, new_count = hunk[1], hunk[2], hunk[3], hunk[4]

        if old_count == 0 and new_count > 0 then
          for i = 0, new_count - 1 do
            vim.api.nvim_buf_set_extmark(buf, ns_id, new_start - 1 + i, 0, {
              end_line = new_start + i,
              hl_group = 'DiffAdd',
              hl_eol = true,
              priority = 100,
            })
            vim.fn.sign_place(0, 'MRReviewerDiff', 'MRReviewerDiffAdd', buf, {
              lnum = new_start + i,
              priority = 10,
            })
          end
        elseif old_count > 0 and new_count == 0 then
          local line = math.max(0, new_start - 1)
          vim.api.nvim_buf_set_extmark(buf, ns_id, line, 0, {
            virt_lines = { { { string.format('  ▼ %d line(s) deleted', old_count), 'DiffDelete' } } },
            virt_lines_above = false,
            priority = 100,
          })
        elseif old_count > 0 and new_count > 0 then
          for i = 0, new_count - 1 do
            vim.api.nvim_buf_set_extmark(buf, ns_id, new_start - 1 + i, 0, {
              end_line = new_start + i,
              hl_group = 'DiffChange',
              hl_eol = true,
              priority = 100,
            })
            vim.fn.sign_place(0, 'MRReviewerDiff', 'MRReviewerDiffChange', buf, {
              lnum = new_start + i,
              priority = 10,
            })
          end
        end
      end
    end
  end

  -- Display comments for the new file
  comments.display_for_file(file_info.new_path or file_info.path, buf)

  utils.notify('Loaded diff for ' .. file_info.path, 'info')
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

      vim.api.nvim_buf_set_keymap(buf, 'n', keymaps.next_comment or ']c', '', {
        callback = comments.next_comment,
        noremap = true,
        silent = true,
        desc = 'Next comment',
      })

      vim.api.nvim_buf_set_keymap(buf, 'n', keymaps.prev_comment or '[c', '', {
        callback = comments.prev_comment,
        noremap = true,
        silent = true,
        desc = 'Previous comment',
      })

      vim.api.nvim_buf_set_keymap(buf, 'n', keymaps.toggle_comments or '<leader>tc', '', {
        callback = comments.toggle_mode,
        noremap = true,
        silent = true,
        desc = 'Toggle comment display mode',
      })

      vim.api.nvim_buf_set_keymap(buf, 'n', keymaps.show_comment or 'K', '', {
        callback = comments.show_float_for_current_line,
        noremap = true,
        silent = true,
        desc = 'Show comment for current line',
      })

      vim.api.nvim_buf_set_keymap(buf, 'n', keymaps.list_comments or '<leader>cl', '', {
        callback = function()
          require('mrreviewer.commands').list_comments()
        end,
        noremap = true,
        silent = true,
        desc = 'List all comments in MR',
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
