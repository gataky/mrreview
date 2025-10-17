-- lua/mrreviewer/parsers.lua
-- JSON parsers for MR data, comments, and position info

local M = {}
local utils = require('mrreviewer.utils')

--- Parse MR list output from glab
--- @param json_str string JSON output from `glab mr list --output json`
--- @return table|nil, string|nil List of MRs or nil and error message
function M.parse_mr_list(json_str)
  local data, err = utils.json_decode(json_str)
  if not data then
    return nil, 'Failed to parse MR list JSON: ' .. (err or 'unknown error')
  end

  -- Handle empty list
  if type(data) ~= 'table' or #data == 0 then
    return {}, nil
  end

  local mrs = {}
  for _, mr in ipairs(data) do
    table.insert(mrs, {
      iid = mr.iid or mr.number,
      title = mr.title or '',
      state = mr.state or 'opened',
      author = {
        username = mr.author and mr.author.username or 'unknown',
        name = mr.author and mr.author.name or 'Unknown',
      },
      source_branch = mr.source_branch or mr.head_ref_name or '',
      target_branch = mr.target_branch or mr.base_ref_name or 'main',
      created_at = mr.created_at or '',
      updated_at = mr.updated_at or '',
      web_url = mr.web_url or '',
    })
  end

  return mrs, nil
end

--- Parse MR details output from glab
--- @param json_str string JSON output from `glab mr view <id> --output json`
--- @return table|nil, string|nil MR details or nil and error message
function M.parse_mr_details(json_str)
  local data, err = utils.json_decode(json_str)
  if not data then
    return nil, 'Failed to parse MR details JSON: ' .. (err or 'unknown error')
  end

  -- Extract relevant MR information
  local mr = {
    iid = data.iid or data.number,
    title = data.title or '',
    description = data.description or '',
    state = data.state or 'opened',
    author = {
      username = data.author and data.author.username or 'unknown',
      name = data.author and data.author.name or 'Unknown',
    },
    source_branch = data.source_branch or data.head_ref_name or '',
    target_branch = data.target_branch or data.base_ref_name or 'main',
    created_at = data.created_at or '',
    updated_at = data.updated_at or '',
    merged_at = data.merged_at or '',
    closed_at = data.closed_at or '',
    web_url = data.web_url or '',
    diff_refs = data.diff_refs or {},
    changes = data.changes or {},
  }

  return mr, nil
end

--- Parse comment position data
--- @param position table Position data from GitLab comment
--- @return table|nil Parsed position info or nil
local function parse_position(position)
  if not position or type(position) ~= 'table' then
    return nil
  end

  local parsed = {
    base_sha = position.base_sha,
    head_sha = position.head_sha,
    start_sha = position.start_sha,
    new_path = position.new_path,
    old_path = position.old_path,
    new_line = position.new_line,
    old_line = position.old_line,
    position_type = position.position_type or 'text',
  }

  -- Handle line range for multi-line comments
  if position.line_range then
    parsed.line_range = {
      start = {
        line_code = position.line_range.start and position.line_range.start.line_code,
        new_line = position.line_range.start and position.line_range.start.new_line,
        old_line = position.line_range.start and position.line_range.start.old_line,
        type = position.line_range.start and position.line_range.start.type,
      },
      ['end'] = {
        line_code = position.line_range['end'] and position.line_range['end'].line_code,
        new_line = position.line_range['end'] and position.line_range['end'].new_line,
        old_line = position.line_range['end'] and position.line_range['end'].old_line,
        type = position.line_range['end'] and position.line_range['end'].type,
      },
    }
  end

  return parsed
end

--- Parse comments output from glab
--- @param json_str string JSON output from `glab mr view <id> --comments --output json`
--- @return table|nil, string|nil List of comments or nil and error message
function M.parse_comments(json_str)
  local data, err = utils.json_decode(json_str)
  if not data then
    return nil, 'Failed to parse comments JSON: ' .. (err or 'unknown error')
  end

  -- Comments might be in a 'notes' field or at the root
  local notes = data.notes or data
  if type(notes) ~= 'table' then
    return {}, nil
  end

  local comments = {}
  for _, note in ipairs(notes) do
    -- Only include diff notes (comments on code)
    if note.type == 'DiffNote' or note.noteable_type == 'MergeRequest' then
      local comment = {
        id = note.id,
        body = note.body or '',
        author = {
          username = note.author and note.author.username or 'unknown',
          name = note.author and note.author.name or 'Unknown',
          avatar_url = note.author and note.author.avatar_url or '',
        },
        created_at = note.created_at or '',
        updated_at = note.updated_at or '',
        system = note.system or false,
        resolvable = note.resolvable or false,
        resolved = note.resolved or false,
        position = parse_position(note.position),
      }

      -- Only include comments with valid positions (actual code comments)
      if comment.position and comment.position.new_path then
        table.insert(comments, comment)
      end
    end
  end

  return comments, nil
end

--- Filter comments by file path
--- @param comments table List of comments
--- @param file_path string File path to filter by
--- @return table Filtered comments
function M.filter_comments_by_file(comments, file_path)
  local filtered = {}

  for _, comment in ipairs(comments) do
    if comment.position and comment.position.new_path == file_path then
      table.insert(filtered, comment)
    elseif comment.position and comment.position.old_path == file_path then
      table.insert(filtered, comment)
    end
  end

  return filtered
end

--- Sort comments by line number
--- @param comments table List of comments
--- @return table Sorted comments
function M.sort_comments_by_line(comments)
  local sorted = vim.deepcopy(comments)

  table.sort(sorted, function(a, b)
    local a_line = (a.position and a.position.new_line) or 0
    local b_line = (b.position and b.position.new_line) or 0
    return a_line < b_line
  end)

  return sorted
end

return M
