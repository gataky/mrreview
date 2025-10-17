-- plugin/mrreviewer.lua
-- Main entry point for the MR Reviewer plugin
-- This file is automatically loaded by Neovim

-- Prevent loading twice
if vim.g.loaded_mrreviewer == 1 then
  return
end
vim.g.loaded_mrreviewer = 1

-- Create user commands
vim.api.nvim_create_user_command('MRList', function()
  require('mrreviewer.commands').list()
end, {
  desc = 'List open merge requests'
})

vim.api.nvim_create_user_command('MRCurrent', function()
  require('mrreviewer.commands').current()
end, {
  desc = 'Open merge request for current branch'
})

vim.api.nvim_create_user_command('MRReview', function(opts)
  require('mrreviewer.commands').review(opts.args)
end, {
  nargs = 1,
  desc = 'Review a specific merge request by number'
})

vim.api.nvim_create_user_command('MRDebugJSON', function(opts)
  require('mrreviewer.commands').debug_json(opts.args)
end, {
  nargs = 1,
  desc = 'Debug: dump raw JSON from glab for an MR'
})

vim.api.nvim_create_user_command('MRComments', function()
  require('mrreviewer.commands').list_comments()
end, {
  desc = 'List all comments in current MR using Telescope'
})
