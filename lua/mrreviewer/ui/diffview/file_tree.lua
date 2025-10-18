-- lua/mrreviewer/ui/diffview/file_tree.lua
-- Node-based tree data structure for hierarchical file display

local M = {}
local logger = require('mrreviewer.core.logger')

--- Node class for tree structure
--- @class Node
--- @field name string Node name (filename or directory name)
--- @field path string Full path from root
--- @field kind string Node type: "file" or "dir"
--- @field parent Node|nil Parent node reference
--- @field children Node[] List of child nodes (for directories)
--- @field depth number Indentation level (0-based)
--- @field collapsed boolean Whether directory is collapsed (only for dirs)
--- @field comment_count table|nil Comment counts: {resolved: number, total: number} (only for files)
local Node = {}
Node.__index = Node

--- Create a new Node
--- @param name string Node name (filename or directory name)
--- @param path string Full path from root
--- @param kind string Node type: "file" or "dir"
--- @param parent Node|nil Parent node reference (nil for root)
--- @param depth number Indentation level (0-based)
--- @return Node New node instance
function Node.new(name, path, kind, parent, depth)
  local self = setmetatable({}, Node)

  self.name = name
  self.path = path
  self.kind = kind
  self.parent = parent
  self.children = {}
  self.depth = depth or 0
  self.collapsed = false -- Directories are expanded by default
  self.comment_count = nil -- Will be set for files only

  logger.debug('file_tree', 'Created new node', {
    name = name,
    path = path,
    kind = kind,
    depth = depth,
  })

  return self
end

--- Add a child node to this node
--- @param child_node Node The child node to add
--- @return boolean Success status
function Node:add_child(child_node)
  if not child_node then
    logger.warn('file_tree', 'Attempted to add nil child node', {
      parent_path = self.path,
    })
    return false
  end

  if self.kind ~= 'dir' then
    logger.warn('file_tree', 'Attempted to add child to non-directory node', {
      parent_path = self.path,
      parent_kind = self.kind,
    })
    return false
  end

  table.insert(self.children, child_node)

  logger.debug('file_tree', 'Added child node', {
    parent_path = self.path,
    child_path = child_node.path,
    child_kind = child_node.kind,
  })

  return true
end

--- Check if this node is a file
--- @return boolean True if node is a file
function Node:is_file()
  return self.kind == 'file'
end

--- Check if this node is a directory
--- @return boolean True if node is a directory
function Node:is_dir()
  return self.kind == 'dir'
end

--- Get the full path of this node
--- @return string Full path from root
function Node:get_full_path()
  return self.path
end

-- Export Node constructor to module
M.Node = Node

--- Build a tree structure from a flat list of file paths
--- @param file_paths table List of file paths (strings)
--- @param comments table|nil Optional list of comments for comment count integration
--- @return Node Root node of the tree
function M.build_tree(file_paths, comments)
  if not file_paths or #file_paths == 0 then
    logger.warn('file_tree', 'build_tree called with empty file list')
    return Node.new('root', '', 'dir', nil, -1)
  end

  -- Create virtual root node
  local root = Node.new('root', '', 'dir', nil, -1)

  logger.info('file_tree', 'Building tree from file paths', {
    file_count = #file_paths,
    has_comments = comments ~= nil,
  })

  -- Process each file path
  for _, file_path in ipairs(file_paths) do
    -- Parse path into components (task 2.2)
    local parts = vim.split(file_path, '/', { plain = true })

    local current_node = root
    local current_path = ''

    -- Build directory hierarchy (tasks 2.3, 2.4, 2.5)
    for i, part in ipairs(parts) do
      if part ~= '' then
        local is_last = (i == #parts)
        current_path = current_path == '' and part or (current_path .. '/' .. part)

        -- Check if child already exists
        local existing_child = nil
        for _, child in ipairs(current_node.children) do
          if child.name == part then
            existing_child = child
            break
          end
        end

        if existing_child then
          current_node = existing_child
        else
          -- Create new node (directory or file)
          local kind = is_last and 'file' or 'dir'
          local depth = current_node.depth + 1
          local new_node = Node.new(part, current_path, kind, current_node, depth)

          current_node:add_child(new_node)
          current_node = new_node

          logger.debug('file_tree', 'Created tree node', {
            name = part,
            path = current_path,
            kind = kind,
            depth = depth,
          })
        end
      end
    end
  end

  -- Sort children recursively (task 2.6)
  M.sort_tree(root)

  -- Attach comment counts to file nodes (task 2.7)
  if comments then
    M.attach_comment_counts(root, comments)
  end

  logger.info('file_tree', 'Tree building complete', {
    total_nodes = M.count_nodes(root),
  })

  return root
end

--- Calculate comment counts for a specific file (from file_panel)
--- @param file_path string The file path to count comments for
--- @param comments table List of all comments
--- @return table Comment counts: {resolved: number, total: number}
local function calculate_comment_counts(file_path, comments)
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

--- Attach comment counts to file nodes in the tree
--- @param node Node Root or intermediate node
--- @param comments table List of all comments
function M.attach_comment_counts(node, comments)
  if not node or not comments then
    return
  end

  -- If this is a file node, calculate and attach comment counts
  if node:is_file() then
    local counts = calculate_comment_counts(node.path, comments)
    node.comment_count = counts

    if counts.total > 0 then
      logger.debug('file_tree', 'Attached comment counts to file node', {
        path = node.path,
        resolved = counts.resolved,
        total = counts.total,
      })
    end
  end

  -- Recursively process children
  for _, child in ipairs(node.children) do
    M.attach_comment_counts(child, comments)
  end
end

--- Sort tree children recursively (directories before files, alphabetical)
--- @param node Node The node whose children to sort
local function sort_children(node)
  if not node:is_dir() or #node.children == 0 then
    return
  end

  -- Sort children: directories first, then alphabetically
  table.sort(node.children, function(a, b)
    if a.kind ~= b.kind then
      return a.kind == 'dir' -- directories come first
    end
    return a.name < b.name
  end)

  -- Recursively sort children's children
  for _, child in ipairs(node.children) do
    sort_children(child)
  end
end

--- Sort entire tree recursively
--- @param root Node Root node of the tree
function M.sort_tree(root)
  sort_children(root)
  logger.debug('file_tree', 'Tree sorted recursively')
end

--- Count total nodes in tree (for debugging)
--- @param node Node Root node
--- @return number Total node count
function M.count_nodes(node)
  local count = 1
  for _, child in ipairs(node.children) do
    count = count + M.count_nodes(child)
  end
  return count
end

--- Flatten tree into visible nodes (depth-first traversal)
--- Skips children of collapsed directories
--- @param node Node Root or intermediate node
--- @param collapsed_state table Map of collapsed directory paths {[path] = true}
--- @param result table|nil Accumulator for results (optional)
--- @return table List of visible nodes in display order
function M.flatten_visible_nodes(node, collapsed_state, result)
  result = result or {}
  collapsed_state = collapsed_state or {}

  -- Skip the virtual root node itself (depth = -1)
  if node.depth >= 0 then
    table.insert(result, node)
  end

  -- If this is a collapsed directory, skip its children
  if node:is_dir() and collapsed_state[node.path] then
    logger.debug('file_tree', 'Skipping children of collapsed directory', {
      path = node.path,
    })
    return result
  end

  -- Recursively process children (already sorted)
  for _, child in ipairs(node.children) do
    M.flatten_visible_nodes(child, collapsed_state, result)
  end

  return result
end

return M
