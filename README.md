# MRReviewer

A Neovim plugin for reviewing GitLab Merge Requests directly within your editor.

## Features

- 📋 Browse and select open merge requests
- 🔍 Automatically detect MR for current branch
- 💬 View MR comments inline with code
- 🔄 Side-by-side diff view
- ⚡ Async operations with no UI blocking

## Dependencies

### Required

- **Neovim** >= 0.8.0
- **[glab](https://gitlab.com/gitlab-org/cli)** - GitLab CLI tool
  ```bash
  # Install glab
  # macOS
  brew install glab

  # Linux
  # See: https://gitlab.com/gitlab-org/cli#installation

  # Authenticate
  glab auth login
  ```
- **[plenary.nvim](https://github.com/nvim-lua/plenary.nvim)** - Lua utilities
  ```lua
  -- With lazy.nvim
  { 'nvim-lua/plenary.nvim' }
  ```

### Optional

- **[telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)** - Enhanced UI for MR selection
  ```lua
  -- With lazy.nvim
  { 'nvim-telescope/telescope.nvim' }
  ```
  If Telescope is not installed, the plugin will fall back to `vim.ui.select`.

- **[diffview.nvim](https://github.com/sindrets/diffview.nvim)** - Enhanced diff viewing (planned integration)
  ```lua
  -- With lazy.nvim
  { 'sindrets/diffview.nvim' }
  ```

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'yourusername/mrreviewer',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',  -- Optional but recommended
  },
  config = function()
    require('mrreviewer').setup({
      -- Configuration options (see below)
    })
  end
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'yourusername/mrreviewer',
  requires = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',  -- Optional but recommended
  },
  config = function()
    require('mrreviewer').setup()
  end
}
```

### Using [mini.deps](https://github.com/echasnovski/mini.deps)

```lua
local add = require('mini.deps').add

-- Add dependencies first
add('nvim-lua/plenary.nvim')
add('nvim-telescope/telescope.nvim')  -- Optional but recommended

-- Add mrreviewer
add({
  source = 'yourusername/mrreviewer',
})

-- Setup the plugin
require('mrreviewer').setup({
  -- Configuration options (see below)
})
```

## Configuration

Default configuration:

```lua
require('mrreviewer').setup({
  -- Comment display mode: 'split' or 'virtual_text'
  comment_display_mode = 'split',

  -- Window layout options
  window = {
    comment_width = 40,
    vertical_split = true,
    sync_scroll = true,
  },

  -- Keymaps for diff view navigation
  keymaps = {
    next_file = ']f',
    prev_file = '[f',
    next_comment = ']c',
    prev_comment = '[c',
    close = 'q',
    toggle_comments = '<leader>tc',
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
})
```

## Usage

### Commands

- `:MRList` - Browse and select from open merge requests using Telescope (or vim.ui.select)
- `:MRCurrent` - Automatically detect and open MR for the current git branch
- `:MRReview <number>` - Review a specific MR by number (e.g., `:MRReview 123`)

### Default Keymaps

When viewing a diff:

| Keymap | Action | Description |
|--------|--------|-------------|
| `]f` | Next file | Navigate to next file in MR |
| `[f` | Previous file | Navigate to previous file in MR |
| `]c` | Next comment | Jump to next comment |
| `[c` | Previous comment | Jump to previous comment |
| `<leader>tc` | Toggle comments | Switch between split/virtual text comment display |
| `q` | Close | Close diff view |

### Workflow Example

```vim
" 1. Open MR for current branch
:MRCurrent

" 2. Or browse all open MRs with Telescope
:MRList

" 3. Or review a specific MR
:MRReview 123

" In diff view:
" - Use ]f / [f to navigate between changed files
" - Use ]c / [c to jump between comments
" - Use <leader>tc to toggle comment display mode
" - Press q to close the diff view
```

### Comment Display Modes

**Split Buffer Mode** (default):
- Comments appear in a separate vertical split on the right
- Shows all comments for the current file
- Formatted with author, timestamp, and resolved status

**Virtual Text Mode**:
- Comments appear inline as virtual text at the end of lines
- Compact view without separate window
- Toggle with `<leader>tc`

### Customizing Keymaps

```lua
require('mrreviewer').setup({
  keymaps = {
    next_file = ']f',           -- or '<C-n>'
    prev_file = '[f',           -- or '<C-p>'
    next_comment = ']c',        -- or '<C-j>'
    prev_comment = '[c',        -- or '<C-k>'
    close = 'q',                -- or '<Esc>'
    toggle_comments = '<leader>tc',
  },
})
```

## Troubleshooting

### glab not authenticated

**Error:** `glab is not authenticated`

**Solution:**
```bash
glab auth login
```

### Not in a git repository

**Error:** `Not in a git repository`

**Solution:** Make sure you're running the commands from within a git repository that has a GitLab remote.

### Failed to detect GitLab project

**Error:** `Remote URL does not appear to be a GitLab repository`

**Solution:** Ensure your git remote URL contains "gitlab":
```bash
git remote -v
# Should show something like: git@gitlab.com:user/repo.git
```

### No comments displayed

If comments aren't showing up:
1. Verify the MR actually has comments on code (not just discussion comments)
2. Check that comments are on the file you're viewing
3. Try toggling comment display mode with `<leader>tc`

### Diff not loading

If the diff view doesn't open:
1. Ensure the MR has changed files
2. Check that `git show` works in your repository
3. Verify the branch hasn't been deleted

## Development Status

This plugin is feature-complete for v1.0:

- ✅ Project setup and infrastructure
- ✅ GitLab integration layer (glab CLI wrapper with plenary.job)
- ✅ MR discovery and selection interface (with Telescope)
- ✅ Diff view system (using Neovim's built-in diff)
- ✅ Comment display system (dual modes: split/virtual text)
- ✅ Documentation and basic setup

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT
