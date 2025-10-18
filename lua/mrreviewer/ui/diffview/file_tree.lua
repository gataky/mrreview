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

return M
