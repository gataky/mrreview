-- Minimal init file for running tests
-- This sets up the necessary paths for plenary and the plugin

local plenary_dir = os.getenv('PLENARY_DIR') or '/tmp/plenary.nvim'
local is_not_a_directory = vim.fn.isdirectory(plenary_dir) == 0

if is_not_a_directory then
  vim.fn.system({ 'git', 'clone', 'https://github.com/nvim-lua/plenary.nvim', plenary_dir })
end

vim.opt.rtp:append('.')
vim.opt.rtp:append(plenary_dir)

-- Add tests directory to package path for test helper modules
local tests_dir = vim.fn.getcwd() .. '/tests'
package.path = package.path .. ';' .. tests_dir .. '/?.lua'
package.path = package.path .. ';' .. tests_dir .. '/?/init.lua'

vim.cmd('runtime plugin/plenary.vim')
require('plenary.busted')
