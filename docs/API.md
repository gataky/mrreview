# MRReviewer API Documentation

This document describes the public API for MRReviewer, useful for plugin developers and advanced users.

## Table of Contents

- [Setup API](#setup-api)
- [Configuration API](#configuration-api)
- [Commands API](#commands-api)
- [State API](#state-api)
- [Error Handling API](#error-handling-api)
- [Logger API](#logger-api)

---

## Setup API

### `require('mrreviewer').setup(opts)`

Initialize the MRReviewer plugin with optional configuration.

**Parameters:**
- `opts` (table|nil) - Configuration options (see [Configuration API](#configuration-api))

**Returns:** None

**Example:**
```lua
require('mrreviewer').setup({
  comment_display_mode = 'float',
  window = {
    comment_width = 50,
  },
  keymaps = {
    next_file = '<C-n>',
    prev_file = '<C-p>',
  },
})
```

### `require('mrreviewer').is_initialized()`

Check if the plugin has been initialized.

**Returns:** `boolean` - true if initialized

**Example:**
```lua
if require('mrreviewer').is_initialized() then
  print('MRReviewer is ready')
end
```

### `require('mrreviewer').get_state()`

Get the current plugin state (session state only).

**Returns:** `table` - Current session state

**Example:**
```lua
local state = require('mrreviewer').get_state()
if state.current_mr then
  print('Currently viewing MR #' .. state.current_mr.data.iid)
end
```

### `require('mrreviewer').clear_state()`

Clear the current MR state (closes diff view and clears current MR data).

**Returns:** None

**Example:**
```lua
require('mrreviewer').clear_state()
```

---

## Configuration API

### `require('mrreviewer.config').setup(opts)`

Configure the plugin (usually called by main setup function).

**Parameters:**
- `opts` (table|nil) - Configuration options

**Returns:** None

### `require('mrreviewer.config').get()`

Get the entire configuration.

**Returns:** `table` - Current configuration

**Example:**
```lua
local config = require('mrreviewer.config').get()
print('Comment mode:', config.comment_display_mode)
```

### `require('mrreviewer.config').get_value(key)`

Get a specific configuration value using dot notation.

**Parameters:**
- `key` (string) - Configuration key (supports nested keys like `'window.comment_width'`)

**Returns:** `any` - Configuration value or nil

**Example:**
```lua
local width = require('mrreviewer.config').get_value('window.comment_width')
local next_key = require('mrreviewer.config').get_value('keymaps.next_file')
```

### Configuration Schema

```lua
{
  -- Comment display mode: 'float', 'split', or 'virtual_text'
  comment_display_mode = 'float',

  -- Window layout options
  window = {
    comment_width = 40,        -- Width of comment split
    vertical_split = true,     -- Use vertical split
    sync_scroll = true,        -- Synchronized scrolling
  },

  -- Keymaps for diff view navigation
  keymaps = {
    next_file = ']f',
    prev_file = '[f',
    next_comment = ']c',
    prev_comment = '[c',
    close = 'q',
    toggle_comments = '<leader>tc',
    show_comment = 'K',
    list_comments = '<leader>cl',
  },

  -- Highlight group customization
  highlights = {
    custom = true,
  },

  -- GitLab/glab CLI options
  glab = {
    path = 'glab',
    timeout = 30000,  -- milliseconds
  },

  -- Notification settings
  notifications = {
    enabled = true,
    level = 'info',  -- 'error', 'warn', 'info', 'debug'
  },

  -- Logging settings
  logging = {
    enabled = true,
    level = 'INFO',  -- 'DEBUG', 'INFO', 'WARN', 'ERROR'
    file_path = nil,  -- nil uses default: ~/.local/state/nvim/mrreviewer.log
    max_file_size = 10 * 1024 * 1024,  -- 10MB
    max_backups = 3,
  },
}
```

---

## Commands API

These functions can be called programmatically instead of using `:MR*` commands.

### `require('mrreviewer.commands').list()`

Browse and select from open merge requests.

**Returns:** None

**Example:**
```lua
vim.keymap.set('n', '<leader>ml', function()
  require('mrreviewer.commands').list()
end, { desc = 'List MRs' })
```

### `require('mrreviewer.commands').current()`

Detect and open MR for the current git branch.

**Returns:** None

**Example:**
```lua
vim.keymap.set('n', '<leader>mc', function()
  require('mrreviewer.commands').current()
end, { desc = 'Current branch MR' })
```

### `require('mrreviewer.commands').review(mr_number)`

Review a specific merge request by number.

**Parameters:**
- `mr_number` (string|number) - MR number (e.g., `"123"` or `123`)

**Returns:** None

**Example:**
```lua
-- Review MR !123
require('mrreviewer.commands').review(123)

-- Or bind to keymap
vim.keymap.set('n', '<leader>mr', function()
  local mr = vim.fn.input('MR number: ')
  require('mrreviewer.commands').review(mr)
end, { desc = 'Review MR' })
```

### `require('mrreviewer.commands').list_comments()`

List all comments in current MR using Telescope.

**Returns:** None

**Example:**
```lua
vim.keymap.set('n', '<leader>mC', function()
  require('mrreviewer.commands').list_comments()
end, { desc = 'List MR comments' })
```

### `require('mrreviewer.commands').logs()`

Open log file in a vertical split window.

**Returns:** None

### `require('mrreviewer.commands').clear_logs()`

Clear all log files (main and backups).

**Returns:** None

---

## State API

The state module provides centralized state management with validation.

### `require('mrreviewer.state').get()`

Get the entire state object.

**Returns:** `table` - Complete state (session, diff, comments)

### `require('mrreviewer.state').get_session()`

Get session state only.

**Returns:** `table` - Session state

**Example:**
```lua
local session = require('mrreviewer.state').get_session()
if session.current_mr then
  print('MR:', session.current_mr.data.title)
end
```

### `require('mrreviewer.state').get_diff()`

Get diff view state.

**Returns:** `table` - Diff state (buffers, windows, files, current_file_index)

### `require('mrreviewer.state').get_comments()`

Get comments state.

**Returns:** `table` - Comments state (displayed_comments, namespace_id, windows)

### `require('mrreviewer.state').get_value(path)`

Get a specific state value using dot notation.

**Parameters:**
- `path` (string) - State path (e.g., `'session.initialized'`, `'diff.current_file_index'`)

**Returns:** `any` - State value or nil

**Example:**
```lua
local is_init = require('mrreviewer.state').get_value('session.initialized')
local file_index = require('mrreviewer.state').get_value('diff.current_file_index')
```

### `require('mrreviewer.state').set_value(path, value)`

Set a specific state value using dot notation.

**Parameters:**
- `path` (string) - State path
- `value` (any) - New value

**Returns:** `boolean, error|nil` - Success status and error object

**Example:**
```lua
local ok, err = require('mrreviewer.state').set_value('diff.current_file_index', 3)
if not ok then
  print('Error:', err.message)
end
```

### `require('mrreviewer.state').is_initialized()`

Check if plugin is initialized.

**Returns:** `boolean`

### `require('mrreviewer.state').set_initialized(value)`

Set initialization status.

**Parameters:**
- `value` (boolean) - Initialization status

### `require('mrreviewer.state').get_current_mr()`

Get current MR data.

**Returns:** `table|nil` - Current MR data or nil

### `require('mrreviewer.state').set_current_mr(mr_data)`

Set current MR data.

**Parameters:**
- `mr_data` (table|nil) - MR data or nil to clear

### State Structure

```lua
{
  session = {
    initialized = false,
    current_mr = nil,  -- or { data = {...}, comments = {...} }
    current_diff_buffers = {},
  },
  diff = {
    buffers = {},  -- { [file_path] = buffer_number }
    windows = {},  -- { base = win_id, head = win_id }
    current_file_index = 1,
    files = {},  -- List of changed files
  },
  comments = {
    displayed_comments = {},
    comment_buffer = nil,
    comment_window = nil,
    comment_float_win = nil,
    comment_float_buf = nil,
    namespace_id = <number>,
  },
}
```

---

## Error Handling API

The error module provides standardized error handling across the plugin.

### Error Types

- `ErrorType.GIT` - Git operation errors
- `ErrorType.NETWORK` - Network/glab errors
- `ErrorType.PARSE` - JSON/data parsing errors
- `ErrorType.CONFIG` - Configuration errors
- `ErrorType.VALIDATION` - Input validation errors
- `ErrorType.IO` - File I/O errors
- `ErrorType.UNKNOWN` - Unknown errors

### `require('mrreviewer.errors').new(type, message, context)`

Create a new error object.

**Parameters:**
- `type` (string) - Error type (one of ErrorType values)
- `message` (string) - Error message
- `context` (table|nil) - Additional context data

**Returns:** `table` - Error object

**Example:**
```lua
local errors = require('mrreviewer.errors')
local err = errors.new(errors.ErrorType.VALIDATION, 'Invalid MR number', {
  input = mr_number,
  expected = 'positive integer',
})
```

### Error Constructor Functions

Convenience functions for creating typed errors:

```lua
local errors = require('mrreviewer.errors')

-- Create specific error types
local git_err = errors.git_error('Git command failed', { command = 'git status' })
local net_err = errors.network_error('API request failed', { url = '...' })
local parse_err = errors.parse_error('Invalid JSON', { data = '...' })
local config_err = errors.config_error('Invalid config', { key = 'timeout' })
local val_err = errors.validation_error('Invalid input', { field = 'mr_number' })
local io_err = errors.io_error('File not found', { path = '/tmp/file' })
```

### `require('mrreviewer.errors').wrap(message, err)`

Wrap an existing error with additional context.

**Parameters:**
- `message` (string) - Context message
- `err` (table|string) - Existing error or error message

**Returns:** `table` - Wrapped error object

**Example:**
```lua
local result, err = git_operation()
if not result then
  return nil, errors.wrap('Failed to get current branch', err)
end
```

### `require('mrreviewer.errors').try(fn, context)`

Execute a function with automatic error wrapping.

**Parameters:**
- `fn` (function) - Function to execute
- `context` (string|nil) - Context message for errors

**Returns:** `result, error|nil` - Function result and error tuple

**Example:**
```lua
local result, err = errors.try(function()
  return risky_operation()
end, 'Failed to perform risky operation')

if not result then
  print('Error:', err.message)
end
```

### `require('mrreviewer.errors').is_error(obj)`

Check if an object is an error object.

**Parameters:**
- `obj` (any) - Object to check

**Returns:** `boolean`

### `require('mrreviewer.errors').format(err)`

Format an error for display to users.

**Parameters:**
- `err` (table|string) - Error object or message

**Returns:** `string` - Formatted error message

---

## Logger API

The logger module provides file-based logging with rotation.

### Log Levels

```lua
local logger = require('mrreviewer.logger')

logger.levels.DEBUG  -- 1
logger.levels.INFO   -- 2
logger.levels.WARN   -- 3
logger.levels.ERROR  -- 4
```

### `require('mrreviewer.logger').setup(opts)`

Configure the logger.

**Parameters:**
- `opts` (table) - Logger configuration

**Example:**
```lua
require('mrreviewer.logger').setup({
  enabled = true,
  level = 'DEBUG',
  file_path = '/tmp/mrreviewer.log',
  max_file_size = 5 * 1024 * 1024,  -- 5MB
  max_backups = 5,
})
```

### Logging Functions

```lua
local logger = require('mrreviewer.logger')

-- Log at different levels
logger.debug('module_name', 'Debug message', { context = 'data' })
logger.info('module_name', 'Info message')
logger.warn('module_name', 'Warning message')
logger.error('module_name', 'Error message')

-- Log an error object
logger.log_error('module_name', error_object)
```

### `require('mrreviewer.logger').get_log_path()`

Get the current log file path.

**Returns:** `string` - Log file path

### `require('mrreviewer.logger').get_recent_logs(count)`

Get recent log entries.

**Parameters:**
- `count` (number|nil) - Number of entries to retrieve (default: 50)

**Returns:** `table` - List of log entry strings

### `require('mrreviewer.logger').clear_logs()`

Clear all log files (main and backups).

**Returns:** None

### `require('mrreviewer.logger').open_logs(split_cmd)`

Open log file in a split window.

**Parameters:**
- `split_cmd` (string|nil) - Split command (default: `'split'`, can use `'vsplit'`)

**Returns:** None

---

## Integration Examples

### Custom Keymap Integration

```lua
local mrr = require('mrreviewer')

-- Setup
mrr.setup()

-- Custom keymaps
vim.keymap.set('n', '<leader>ml', function()
  require('mrreviewer.commands').list()
end, { desc = 'MR: List' })

vim.keymap.set('n', '<leader>mc', function()
  require('mrreviewer.commands').current()
end, { desc = 'MR: Current branch' })

vim.keymap.set('n', '<leader>mr', function()
  local mr = vim.fn.input('MR !: ')
  if mr ~= '' then
    require('mrreviewer.commands').review(mr)
  end
end, { desc = 'MR: Review by number' })
```

### Statusline Integration

```lua
-- Show current MR in statusline
function _G.mrreviewer_statusline()
  local state = require('mrreviewer.state').get_current_mr()
  if state and state.data then
    return string.format('MR !%s', state.data.iid)
  end
  return ''
end

-- In your statusline config
vim.opt.statusline:append('%{v:lua.mrreviewer_statusline()}')
```

### Autocmd Integration

```lua
-- Auto-open MR when entering a GitLab project
vim.api.nvim_create_autocmd('VimEnter', {
  pattern = '*',
  callback = function()
    -- Check if in a git repo with gitlab remote
    local git = require('mrreviewer.git')
    if git.is_git_repo() then
      local url, _ = git.get_remote_url()
      if url and url:match('gitlab') then
        -- Auto-load current branch MR
        vim.defer_fn(function()
          require('mrreviewer.commands').current()
        end, 1000)
      end
    end
  end,
})
```

---

## Type Definitions

For Lua LSP support, key type structures:

```lua
---@class MRData
---@field iid number MR internal ID
---@field title string MR title
---@field description string MR description
---@field author table Author info
---@field source_branch string Source branch name
---@field target_branch string Target branch name
---@field web_url string MR URL
---@field state string MR state (opened, merged, closed)
---@field created_at string ISO timestamp
---@field updated_at string ISO timestamp

---@class Comment
---@field id number Comment ID
---@field body string Comment text
---@field author table Author info
---@field created_at string ISO timestamp
---@field resolved boolean Resolution status
---@field position table|nil Position in diff

---@class ErrorObject
---@field type string Error type
---@field message string Error message
---@field context table|nil Additional context
```

---

## Notes

- All functions return `(result, error)` tuples for error handling
- State is managed centrally via the `state` module
- Configuration is immutable after setup (requires restart to change)
- Logging is async and doesn't block operations
- All git operations use plenary.job for safety

For more examples, see [CONTRIBUTING.md](../CONTRIBUTING.md).
