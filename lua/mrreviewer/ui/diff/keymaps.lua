-- lua/mrreviewer/diff/keymaps.lua
-- Keymap setup for diff view navigation

local M = {}

--- Set up keymaps for diff navigation
--- @param state table Diff state with buffers
--- @param nav table Navigation module with next_file, prev_file functions
function M.setup(state, nav)
  local config = require('mrreviewer.core.config')
  local comments = require('mrreviewer.ui.comments')
  local keymaps = config.get_value('keymaps')

  if not keymaps then
    return
  end

  -- Set keymaps for both buffers
  for _, buf in pairs(state.buffers) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_set_keymap(buf, 'n', keymaps.next_file or ']f', '', {
        callback = nav.next_file,
        noremap = true,
        silent = true,
        desc = 'Next file in MR',
      })

      vim.api.nvim_buf_set_keymap(buf, 'n', keymaps.prev_file or '[f', '', {
        callback = nav.prev_file,
        noremap = true,
        silent = true,
        desc = 'Previous file in MR',
      })

      vim.api.nvim_buf_set_keymap(buf, 'n', keymaps.close or 'q', '', {
        callback = nav.close,
        noremap = true,
        silent = true,
        desc = 'Close diff view',
      })

      vim.api.nvim_buf_set_keymap(buf, 'n', keymaps.next_comment or ']c', '', {
        callback = comments.next_comment,
        noremap = true,
        silent = true,
        desc = 'Next comment',
      })

      vim.api.nvim_buf_set_keymap(buf, 'n', keymaps.prev_comment or '[c', '', {
        callback = comments.prev_comment,
        noremap = true,
        silent = true,
        desc = 'Previous comment',
      })

      vim.api.nvim_buf_set_keymap(buf, 'n', keymaps.toggle_comments or '<leader>tc', '', {
        callback = comments.toggle_mode,
        noremap = true,
        silent = true,
        desc = 'Toggle comment display mode',
      })

      vim.api.nvim_buf_set_keymap(buf, 'n', keymaps.show_comment or 'K', '', {
        callback = comments.show_float_for_current_line,
        noremap = true,
        silent = true,
        desc = 'Show comment for current line',
      })

      vim.api.nvim_buf_set_keymap(buf, 'n', keymaps.list_comments or '<leader>cl', '', {
        callback = function()
          require('mrreviewer.api.commands').list_comments()
        end,
        noremap = true,
        silent = true,
        desc = 'List all comments in MR',
      })
    end
  end
end

return M
