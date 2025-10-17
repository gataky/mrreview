-- lua/mrreviewer/config.lua
-- Configuration management with user settings and defaults

local M = {}

-- Default configuration
local defaults = {
  -- Comment display mode: 'split' or 'virtual_text'
  comment_display_mode = 'split',

  -- Window layout options
  window = {
    -- Width of comment split buffer (when using split mode)
    comment_width = 40,
    -- Whether to use vertical split (true) or horizontal (false)
    vertical_split = true,
    -- Enable synchronized scrolling between diff buffers
    sync_scroll = true,
  },

  -- Keymaps for diff view navigation
  keymaps = {
    -- Navigate to next file in MR
    next_file = ']f',
    -- Navigate to previous file in MR
    prev_file = '[f',
    -- Navigate to next comment
    next_comment = ']c',
    -- Navigate to previous comment
    prev_comment = '[c',
    -- Close diff view
    close = 'q',
    -- Toggle comment display mode
    toggle_comments = '<leader>tc',
  },

  -- Highlight group customization
  highlights = {
    -- Use custom highlight groups (if false, uses default groups)
    custom = true,
  },

  -- GitLab/glab CLI options
  glab = {
    -- Path to glab executable (defaults to 'glab' in PATH)
    path = 'glab',
    -- Timeout for glab commands in milliseconds
    timeout = 30000,
  },

  -- Notification settings
  notifications = {
    -- Enable notifications
    enabled = true,
    -- Log level: 'error', 'warn', 'info', 'debug'
    level = 'info',
  },
}

-- Current active configuration
M.options = {}

--- Deep merge two tables
--- @param target table
--- @param source table
--- @return table
local function merge(target, source)
  for key, value in pairs(source) do
    if type(value) == 'table' and type(target[key]) == 'table' then
      target[key] = merge(target[key], value)
    else
      target[key] = value
    end
  end
  return target
end

--- Setup configuration with user options
--- @param opts table|nil User configuration options
function M.setup(opts)
  opts = opts or {}

  -- Deep copy defaults
  M.options = vim.deepcopy(defaults)

  -- Merge user options
  M.options = merge(M.options, opts)
end

--- Get current configuration
--- @return table Current configuration
function M.get()
  return M.options
end

--- Get a specific configuration value
--- @param key string Configuration key (supports nested keys with dot notation, e.g., 'window.comment_width')
--- @return any Configuration value
function M.get_value(key)
  local keys = vim.split(key, '.', { plain = true })
  local value = M.options

  for _, k in ipairs(keys) do
    if type(value) ~= 'table' then
      return nil
    end
    value = value[k]
  end

  return value
end

return M
