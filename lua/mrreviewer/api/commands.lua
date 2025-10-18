-- lua/mrreviewer/commands.lua
-- Neovim command registration and handlers

local M = {}
local glab = require('mrreviewer.integrations.glab')
local parsers = require('mrreviewer.lib.parsers')
local project = require('mrreviewer.integrations.project')
local utils = require('mrreviewer.lib.utils')
local ui = require('mrreviewer.ui.ui')
local diff = require('mrreviewer.ui.diff')

--- Check prerequisites before running commands
--- @return boolean, string|nil Returns true if ready, or false and error message
local function check_prerequisites()
  -- Check if glab is installed and authenticated
  local ok, err = glab.check_installation()
  if not ok then
    utils.notify(err, 'error')
    return false, err
  end

  -- Check if we're in a git repository
  if not utils.is_git_repo() then
    local err_msg = 'Not in a git repository'
    utils.notify(err_msg, 'error')
    return false, err_msg
  end

  -- Check if we can detect GitLab project
  local project_info, project_err = project.get_project_info()
  if not project_info then
    utils.notify(project_err or 'Failed to detect GitLab project', 'error')
    return false, project_err
  end

  return true, nil
end

--- List open merge requests
function M.list()
  utils.notify('Fetching merge requests...', 'info')

  -- Check prerequisites
  local ok, err = check_prerequisites()
  if not ok then
    return
  end

  -- Fetch MR list
  local args = glab.build_mr_list_args('opened')
  glab.execute_async(args, function(exit_code, stdout, stderr)
    if exit_code ~= 0 then
      utils.notify('Failed to fetch MR list: ' .. stderr, 'error')
      return
    end

    -- Parse MR list
    local mrs, parse_err = parsers.parse_mr_list(stdout)
    if not mrs then
      utils.notify(parse_err or 'Failed to parse MR list', 'error')
      return
    end

    if #mrs == 0 then
      utils.notify('No open merge requests found', 'info')
      return
    end

    -- Display MRs using UI module
    ui.select_mr(mrs, function(selected_mr, idx)
      M.review(tostring(selected_mr.iid))
    end)
  end)
end

--- Open merge request for current branch
function M.current()
  utils.notify('Detecting MR for current branch...', 'info')

  -- Check prerequisites
  local ok, err = check_prerequisites()
  if not ok then
    return
  end

  -- Get current branch
  local branch = project.get_current_branch()
  if not branch then
    utils.notify('Could not detect current branch', 'error')
    return
  end

  utils.notify('Searching for MR from branch: ' .. branch, 'info')

  -- Fetch all MRs and find the one matching current branch
  local args = glab.build_mr_list_args('opened')
  glab.execute_async(args, function(exit_code, stdout, stderr)
    if exit_code ~= 0 then
      utils.notify('Failed to fetch MR list: ' .. stderr, 'error')
      return
    end

    -- Parse MR list
    local mrs, parse_err = parsers.parse_mr_list(stdout)
    if not mrs then
      utils.notify(parse_err or 'Failed to parse MR list', 'error')
      return
    end

    -- Find MR with matching source branch
    local matching_mr = nil
    for _, mr in ipairs(mrs) do
      if mr.source_branch == branch then
        matching_mr = mr
        break
      end
    end

    if not matching_mr then
      utils.notify('No open MR found for branch: ' .. branch, 'warn')
      return
    end

    utils.notify('Found MR !' .. matching_mr.iid .. ': ' .. matching_mr.title, 'info')
    M.review(tostring(matching_mr.iid))
  end)
end

--- Review a specific merge request by number
--- @param mr_number string|number MR number
function M.review(mr_number)
  if not mr_number or mr_number == '' then
    utils.notify('MR number is required', 'error')
    return
  end

  utils.notify('Loading MR !' .. mr_number .. '...', 'info')

  -- Check prerequisites
  local ok, err = check_prerequisites()
  if not ok then
    return
  end

  -- Fetch MR details with comments
  local args = glab.build_mr_view_args(mr_number, true)
  glab.execute_async(args, function(exit_code, stdout, stderr)
    if exit_code ~= 0 then
      utils.notify('Failed to fetch MR details: ' .. stderr, 'error')
      return
    end

    -- Parse MR details
    local mr_data, parse_err = parsers.parse_mr_details(stdout)
    if not mr_data then
      utils.notify(parse_err or 'Failed to parse MR details', 'error')
      return
    end

    -- Parse comments
    local comments, comment_err = parsers.parse_comments(stdout)
    if not comments then
      utils.notify(comment_err or 'Failed to parse comments', 'error')
      return
    end

    -- Store comments in MR data for diffview
    mr_data.comments = comments

    -- Store MR data in plugin state
    local mrreviewer = require('mrreviewer')
    mrreviewer.state.current_mr = {
      data = mr_data,
      comments = comments,
    }

    utils.notify(
      string.format(
        'Loaded MR !%s: %s (%d comments)',
        mr_data.iid,
        mr_data.title,
        #comments
      ),
      'info'
    )

    -- Open diffview (new three-pane interface)
    local diffview = require('mrreviewer.ui.diffview')
    local success = diffview.open(mr_data)

    -- Fallback to old diff view if diffview fails
    if not success then
      utils.notify('Falling back to classic diff view', 'warn')
      diff.open(mr_data)
    end
  end)
end

--- Debug command to dump raw JSON from glab
--- @param mr_number string|number MR number
function M.debug_json(mr_number)
  if not mr_number or mr_number == '' then
    utils.notify('MR number is required', 'error')
    return
  end

  local args = glab.build_mr_view_args(mr_number, true)
  glab.execute_async(args, function(exit_code, stdout, stderr)
    if exit_code ~= 0 then
      utils.notify('Failed to fetch MR: ' .. stderr, 'error')
      return
    end

    -- Write to temp file
    local temp_file = '/tmp/mrreviewer_debug_' .. mr_number .. '.json'
    local file = io.open(temp_file, 'w')
    if file then
      file:write(stdout)
      file:close()
      utils.notify('JSON written to: ' .. temp_file, 'info')
      vim.cmd('edit ' .. temp_file)
    else
      utils.notify('Failed to write debug file', 'error')
    end
  end)
end

--- Open log file in a split window
function M.logs()
  local logger = require('mrreviewer.core.logger')
  logger.open_logs('vsplit')
end

--- Clear all log files
function M.clear_logs()
  local logger = require('mrreviewer.core.logger')
  logger.clear_logs()
  utils.notify('Log files cleared', 'info')
end

--- List all comments in current MR using Telescope
function M.list_comments()
  local mrreviewer = require('mrreviewer')

  -- Check if we have an MR loaded
  if not mrreviewer.state.current_mr or not mrreviewer.state.current_mr.comments then
    utils.notify('No MR loaded. Please open an MR first with :MRReview or :MRList', 'warn')
    return
  end

  local comments = mrreviewer.state.current_mr.comments
  if #comments == 0 then
    utils.notify('No comments in this MR', 'info')
    return
  end

  -- Check if Telescope is available
  local has_telescope, telescope = pcall(require, 'telescope')
  if not has_telescope then
    utils.notify('Telescope.nvim is required for this feature', 'error')
    return
  end

  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local conf = require('telescope.config').values
  local actions = require('telescope.actions')
  local action_state = require('telescope.actions.state')

  -- Format comments for display
  local entries = {}
  for _, comment in ipairs(comments) do
    local resolved = comment.resolved and '✓' or '•'
    local file = comment.position and comment.position.new_path or 'unknown'
    local line = comment.position and comment.position.new_line or '?'
    local author = comment.author.username or comment.author.name
    local body_preview = comment.body:gsub('\n', ' '):sub(1, 80)

    table.insert(entries, {
      display = string.format('%s %s:%s - %s: %s', resolved, file, line, author, body_preview),
      ordinal = string.format('%s %s %s', file, author, comment.body),
      file = file,
      line = line,
      comment = comment,
    })
  end

  pickers.new({}, {
    prompt_title = 'MR Comments',
    finder = finders.new_table({
      results = entries,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.display,
          ordinal = entry.ordinal,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if not selection then
          return
        end

        local entry = selection.value
        local mr_data = mrreviewer.state.current_mr.data

        -- Find the file in the MR
        local diff_mod = require('mrreviewer.ui.diff')
        local files = diff_mod.get_changed_files(mr_data)

        -- Find matching file
        local file_info = nil
        for _, file in ipairs(files) do
          if file.new_path == entry.file or file.path == entry.file then
            file_info = file
            break
          end
        end

        if not file_info then
          utils.notify('Could not find file: ' .. entry.file, 'error')
          return
        end

        -- Open the file
        diff_mod.open_file_diff(mr_data, file_info)

        -- Jump to the comment line
        if entry.line and entry.line ~= '?' then
          vim.schedule(function()
            pcall(vim.api.nvim_win_set_cursor, 0, { tonumber(entry.line), 0 })
            -- Show the comment float
            vim.defer_fn(function()
              local comment_mod = require('mrreviewer.ui.comments')
              comment_mod.show_float_for_current_line()
            end, 100)
          end)
        end
      end)
      return true
    end,
  }):find()
end

return M
