-- lua/mrreviewer/diff/navigation.lua
-- File and comment navigation for diff view

local M = {}
local utils = require('mrreviewer.utils')
local comments = require('mrreviewer.comments')

--- Navigate to next file in MR
--- @param state table Diff state
--- @param view table View module with load_file_in_existing_windows function
function M.next_file(state, view)
  if #state.files == 0 then
    utils.notify('No files to navigate', 'warn')
    return
  end

  state.current_file_index = state.current_file_index + 1
  if state.current_file_index > #state.files then
    state.current_file_index = 1
  end

  local mrreviewer = require('mrreviewer')
  local mr_data = mrreviewer.state.current_mr and mrreviewer.state.current_mr.data

  if mr_data then
    -- Clear comments but keep windows open
    comments.clear()

    -- Load the new file diff in existing windows
    view.load_file_in_existing_windows(mr_data, state.files[state.current_file_index])
  end
end

--- Navigate to previous file in MR
--- @param state table Diff state
--- @param view table View module with load_file_in_existing_windows function
function M.prev_file(state, view)
  if #state.files == 0 then
    utils.notify('No files to navigate', 'warn')
    return
  end

  state.current_file_index = state.current_file_index - 1
  if state.current_file_index < 1 then
    state.current_file_index = #state.files
  end

  local mrreviewer = require('mrreviewer')
  local mr_data = mrreviewer.state.current_mr and mrreviewer.state.current_mr.data

  if mr_data then
    -- Clear comments but keep windows open
    comments.clear()

    -- Load the new file diff in existing windows
    view.load_file_in_existing_windows(mr_data, state.files[state.current_file_index])
  end
end

--- Close the current diff view
--- @param state table Diff state
function M.close(state)
  -- Clear comments
  comments.clear()

  -- Close windows safely (only if not the last window)
  local total_windows = #vim.api.nvim_list_wins()
  local windows_to_close = vim.tbl_count(state.windows)

  -- Only close windows if there will be at least one window remaining
  if total_windows > windows_to_close then
    for _, win in pairs(state.windows) do
      if vim.api.nvim_win_is_valid(win) then
        pcall(vim.api.nvim_win_close, win, true)
      end
    end
  else
    -- If these are the last windows, just wipe the buffers instead
    for _, buf in pairs(state.buffers) do
      if vim.api.nvim_buf_is_valid(buf) then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end
  end

  -- Clear state
  state.buffers = {}
  state.windows = {}
  state.current_file_index = 1
  state.files = {}
end

return M
