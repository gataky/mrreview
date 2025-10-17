-- lua/mrreviewer/diff/init.lua
-- Diff view creation, layout, and buffer management

local M = {}

-- Store current diff view state
M.state = {
  buffers = {},
  windows = {},
  current_file_index = 1,
  files = {},
}

-- Load submodules
local view = require('mrreviewer.diff.view')
local navigation_module = require('mrreviewer.diff.navigation')
local keymaps_module = require('mrreviewer.diff.keymaps')

-- Re-export view functions
M.get_changed_files = view.get_changed_files
M.fetch_file_versions = view.fetch_file_versions

--- Create unified diff view
--- @param old_lines table Lines from target branch
--- @param new_lines table Lines from source branch
--- @param file_info table File information
--- @return number Buffer number
function M.create_unified_view(old_lines, new_lines, file_info)
  return view.create_unified_view(old_lines, new_lines, file_info, M.state)
end

--- Open diff view for a specific file in the MR
--- @param mr_data table MR details with diff_refs
--- @param file_info table File information
function M.open_file_diff(mr_data, file_info)
  view.open_file_diff(mr_data, file_info, M.state, function()
    keymaps_module.setup(M.state, M)
  end)
end

--- Load a new file in existing window
--- @param mr_data table MR details
--- @param file_info table File information
function M.load_file_in_existing_windows(mr_data, file_info)
  view.load_file_in_existing_windows(mr_data, file_info, M.state)
end

--- Close the current diff view
function M.close()
  navigation_module.close(M.state)
end

--- Navigate to next file in MR
function M.next_file()
  navigation_module.next_file(M.state, M)
end

--- Navigate to previous file in MR
function M.prev_file()
  navigation_module.prev_file(M.state, M)
end

--- Open diff view for an MR
--- @param mr_data table MR details
function M.open(mr_data)
  local utils = require('mrreviewer.utils')

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
  keymaps_module.setup(M.state, M)
end

return M
