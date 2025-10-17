-- lua/mrreviewer/commands.lua
-- Neovim command registration and handlers

local M = {}
local glab = require('mrreviewer.glab')
local parsers = require('mrreviewer.parsers')
local project = require('mrreviewer.project')
local utils = require('mrreviewer.utils')
local ui = require('mrreviewer.ui')

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

    -- TODO: Open diff view (will be implemented in task 4.0)
    utils.notify('Diff view not yet implemented. MR data stored in state.', 'warn')
  end)
end

return M
