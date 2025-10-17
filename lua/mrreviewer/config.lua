-- lua/mrreviewer/config.lua
-- Configuration management with user settings and defaults

local M = {}
local utils = require('mrreviewer.utils')

-- Default configuration
local defaults = {
  -- Comment display mode: 'float', 'split', or 'virtual_text'
  -- 'float': Show comments in floating windows (like diagnostics) - recommended
  -- 'split': Show all comments in a separate sidebar window
  -- 'virtual_text': Show comments inline at the end of lines
  comment_display_mode = 'float',

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
    -- Toggle comment display mode (cycles through float -> split -> virtual_text)
    toggle_comments = '<leader>tc',
    -- Show comment for current line in floating window (always works, regardless of mode)
    show_comment = 'K',
    -- List all comments in MR with Telescope
    list_comments = '<leader>cl',
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

  -- Logging settings
  logging = {
    -- Enable file logging
    enabled = true,
    -- Log level: 'DEBUG', 'INFO', 'WARN', 'ERROR'
    level = 'INFO',
    -- Log file path (nil uses default: ~/.local/state/nvim/mrreviewer.log)
    file_path = nil,
    -- Maximum log file size in bytes before rotation (10MB)
    max_file_size = 10 * 1024 * 1024,
    -- Number of old log files to keep
    max_backups = 3,
  },
}

-- Current active configuration
M.options = {}

--- Setup configuration with user options
--- @param opts table|nil User configuration options
function M.setup(opts)
  opts = opts or {}

  -- Deep copy defaults
  M.options = vim.deepcopy(defaults)

  -- Merge user options
  M.options = utils.merge_tables(M.options, opts)
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
