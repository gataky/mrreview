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

- `:MRList` - Browse and select from open merge requests
- `:MRCurrent` - Open MR for the current git branch
- `:MRReview <number>` - Review a specific MR by number

### Workflow Example

```vim
" Open MR for current branch
:MRCurrent

" Or browse all open MRs
:MRList

" Or review a specific MR
:MRReview 123
```

## Development Status

This plugin is under active development. Current status:

- ✅ Project setup and infrastructure
- ✅ GitLab integration layer (glab CLI wrapper)
- ✅ MR discovery and selection interface
- 🚧 Diff view system (in progress)
- 🚧 Comment display system (in progress)
- ⏳ Documentation and testing (planned)

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT
