-- lua/mrreviewer/ui/diffview/init.lua
-- Main diffview API and entry point

local M = {}
local state = require('mrreviewer.core.state')
local config = require('mrreviewer.core.config')
local logger = require('mrreviewer.core.logger')
local utils = require('mrreviewer.lib.utils')
local errors = require('mrreviewer.core.errors')

-- Import diffview modules
local layout = require('mrreviewer.ui.diffview.layout')
local file_panel = require('mrreviewer.ui.diffview.file_panel')
local diff_panel = require('mrreviewer.ui.diffview.diff_panel')
local comments_panel = require('mrreviewer.ui.diffview.comments_panel')
local navigation = require('mrreviewer.ui.diffview.navigation')

-- Import utilities from existing diff view
local view = require('mrreviewer.ui.diff.view')

--- Validate MR data has required fields
--- @param mr_data table MR data to validate
--- @return boolean,string Success status and error message if failed
local function validate_mr_data(mr_data)
  if not mr_data then
    return false, 'MR data is nil'
  end

  if not mr_data.diff_refs then
    return false, 'Missing diff_refs in MR data'
  end

  if not mr_data.diff_refs.base_sha or not mr_data.diff_refs.head_sha then
    return false, 'Missing base_sha or head_sha in diff_refs'
  end

  return true, nil
end

--- Get changed files from MR data
--- @param mr_data table MR data
--- @return table List of changed file paths
local function get_file_list(mr_data)
  local files = view.get_changed_files(mr_data)
  local file_paths = {}

  for _, file_info in ipairs(files) do
    table.insert(file_paths, file_info.new_path or file_info.path)
  end

  return file_paths
end

--- Get comments from MR data
--- @param mr_data table MR data
--- @return table List of comments
local function get_comments(mr_data)
  -- Check if comments are already in mr_data
  if mr_data.comments and type(mr_data.comments) == 'table' then
    return mr_data.comments
  end

  -- Otherwise, fetch from state
  local session = state.get_session()
  if session.mr_iid and session.project_id then
    -- Comments should have been fetched already
    local comments_state = state.get_comments()
    if comments_state.list and #comments_state.list > 0 then
      return comments_state.list
    end
  end

  -- Return empty list if no comments available
  return {}
end

--- Open diffview for an MR
--- @param mr_data table MR data with diff_refs and comments
--- @return boolean Success status
function M.open(mr_data)
  -- Show loading notification
  utils.notify('Opening diffview...', 'info')
  logger.info('diffview', 'Opening diffview for MR')

  -- Wrap in error handler
  local result, err = errors.try(function()
    -- Validate MR data
    local valid, err_msg = validate_mr_data(mr_data)
    if not valid then
      error(err_msg)
    end

    -- Get file list and comments
    local files = get_file_list(mr_data)
    if not files or #files == 0 then
      error('No changed files found in MR')
    end

    local comments = get_comments(mr_data)
    logger.info('diffview', 'Found files and comments', {
      file_count = #files,
      comment_count = #comments,
    })

    -- Create three-pane layout
    if not layout.create_layout(mr_data) then
      error('Failed to create diffview layout')
    end

    -- Get state references
    local diffview = state.get_diffview()
    local panel_buffers = diffview.panel_buffers
    local panel_windows = diffview.panel_windows

    -- Set up file selection callback
    local function on_file_selected(file_path)
      logger.info('diffview', 'File selected in file panel: ' .. file_path)
      diff_panel.update_file(mr_data, file_path)

      -- Scroll comments panel to the file section
      vim.schedule(function()
        comments_panel.scroll_to_file(file_path)
      end)

      -- Re-render comments panel to update highlighting
      comments_panel.render(
        comments,
        files,
        panel_buffers.comments,
        function(comment)
          -- Jump to comment and briefly show, then return focus to comments panel
          vim.schedule(function()
            navigation.jump_to_comment(comment, config.get_value('diffview.highlight_duration'), mr_data)
          end)
        end,
        function(comment)
          navigation.open_full_comment_thread(comment)
        end
      )
    end

    -- Render file panel
    file_panel.render(files, comments, panel_buffers.files, on_file_selected)

    -- Select and render first file
    if #files > 0 then
      local first_file = files[1]
      diffview.selected_file = first_file

      if not diff_panel.render(mr_data, first_file) then
        logger.warn('diffview', 'Failed to render initial diff for: ' .. first_file)
      end
    end

    -- Render comments panel
    comments_panel.render(
      comments,
      files,
      panel_buffers.comments,
      function(comment)
        -- Jump to comment and briefly show, then return focus to comments panel
        vim.schedule(function()
          navigation.jump_to_comment(comment, config.get_value('diffview.highlight_duration'), mr_data)
        end)
      end,
      function(comment)
        navigation.open_full_comment_thread(comment)
      end
    )

    -- Set up navigation (cursor tracking)
    navigation.setup_diff_cursor_moved(comments, mr_data)

    logger.info('diffview', 'Diffview opened successfully')
    utils.notify('Diffview ready', 'info')

    return true
  end)

  if err then
    local error_msg = err.message or tostring(err)
    logger.error('diffview', 'Failed to open diffview', { error = error_msg })
    utils.notify('Failed to open diffview: ' .. error_msg, 'error')

    -- Clean up any partial state
    M.close()

    return false
  end

  return true
end

--- Close diffview and clean up resources
--- @return boolean Success status
function M.close()
  logger.info('diffview', 'Closing diffview')

  local result, err = errors.try(function()
    -- Clean up navigation autocmds
    navigation.cleanup()

    -- Close layout (windows and buffers)
    layout.close()

    -- Clear diffview state (includes timer cleanup)
    state.clear_diffview()

    logger.info('diffview', 'Diffview closed successfully')
    return true
  end)

  if err then
    local error_msg = err.message or tostring(err)
    logger.error('diffview', 'Error while closing diffview', { error = error_msg })

    -- Try to force cleanup even if error occurred
    pcall(navigation.cleanup)
    pcall(layout.close)
    pcall(state.clear_diffview)

    return false
  end

  return true
end

--- Check if diffview is currently open
--- @return boolean True if diffview is open
function M.is_open()
  local diffview = state.get_diffview()
  return diffview.panel_windows
    and not vim.tbl_isempty(diffview.panel_windows)
    and vim.api.nvim_win_is_valid(diffview.panel_windows.files or -1)
end

--- Toggle diffview (open if closed, close if open)
--- @param mr_data table MR data (required if opening)
--- @return boolean Success status
function M.toggle(mr_data)
  if M.is_open() then
    return M.close()
  else
    if not mr_data then
      utils.notify('MR data required to open diffview', 'error')
      return false
    end
    return M.open(mr_data)
  end
end

--- Refresh diffview with updated data
--- @param mr_data table Updated MR data
--- @return boolean Success status
function M.refresh(mr_data)
  if not M.is_open() then
    logger.warn('diffview', 'Cannot refresh diffview: not currently open')
    return false
  end

  logger.info('diffview', 'Refreshing diffview')

  -- Save current state
  local diffview = state.get_diffview()
  local current_file = diffview.selected_file

  -- Close and reopen
  M.close()

  local success = M.open(mr_data)

  -- Try to restore previous file selection
  if success and current_file then
    local diffview_new = state.get_diffview()
    diffview_new.selected_file = current_file

    local ok, _ = pcall(diff_panel.update_file, mr_data, current_file)
    if not ok then
      logger.warn('diffview', 'Could not restore previous file selection')
    end
  end

  return success
end

return M
