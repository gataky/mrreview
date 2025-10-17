-- lua/mrreviewer/highlights.lua
-- Highlight group definitions for diff and comments

local M = {}

-- Define highlight groups
local highlights = {
  -- Diff highlights
  MRReviewerDiffAdd = { link = 'DiffAdd' },
  MRReviewerDiffDelete = { link = 'DiffDelete' },
  MRReviewerDiffChange = { link = 'DiffChange' },
  MRReviewerDiffText = { link = 'DiffText' },

  -- Comment highlights
  MRReviewerComment = { link = 'Comment' },
  MRReviewerCommentUnresolved = { fg = '#ff9e64', bold = true },
  MRReviewerCommentResolved = { fg = '#565f89', italic = true },
  MRReviewerCommentAuthor = { link = 'Identifier' },
  MRReviewerCommentTimestamp = { link = 'NonText' },
  MRReviewerCommentBody = { link = 'Normal' },

  -- Sign column indicators
  MRReviewerSignComment = { fg = '#7aa2f7', bold = true },
  MRReviewerSignCommentResolved = { fg = '#565f89' },

  -- Virtual text highlights
  MRReviewerVirtualText = { fg = '#7aa2f7', italic = true },
  MRReviewerVirtualTextResolved = { fg = '#565f89', italic = true },

  -- UI highlights
  MRReviewerTitle = { link = 'Title' },
  MRReviewerBorder = { link = 'FloatBorder' },
  MRReviewerSelection = { link = 'Visual' },
}

--- Setup highlight groups
function M.setup()
  local config = require('mrreviewer.config')

  -- Only set up custom highlights if enabled in config
  if not config.get_value('highlights.custom') then
    return
  end

  -- Create highlight groups
  for group, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, opts)
  end
end

--- Get the name of a highlight group for a specific element
--- @param element string Element name (e.g., 'diff_add', 'comment_unresolved')
--- @return string Highlight group name
function M.get_group(element)
  local group_map = {
    diff_add = 'MRReviewerDiffAdd',
    diff_delete = 'MRReviewerDiffDelete',
    diff_change = 'MRReviewerDiffChange',
    diff_text = 'MRReviewerDiffText',
    comment = 'MRReviewerComment',
    comment_unresolved = 'MRReviewerCommentUnresolved',
    comment_resolved = 'MRReviewerCommentResolved',
    comment_author = 'MRReviewerCommentAuthor',
    comment_timestamp = 'MRReviewerCommentTimestamp',
    comment_body = 'MRReviewerCommentBody',
    sign_comment = 'MRReviewerSignComment',
    sign_comment_resolved = 'MRReviewerSignCommentResolved',
    virtual_text = 'MRReviewerVirtualText',
    virtual_text_resolved = 'MRReviewerVirtualTextResolved',
    title = 'MRReviewerTitle',
    border = 'MRReviewerBorder',
    selection = 'MRReviewerSelection',
  }

  return group_map[element] or 'Normal'
end

--- Define custom signs for the sign column
function M.define_signs()
  -- Comment signs
  vim.fn.sign_define('MRReviewerComment', {
    text = '💬',
    texthl = 'MRReviewerSignComment',
  })

  vim.fn.sign_define('MRReviewerCommentResolved', {
    text = '✓',
    texthl = 'MRReviewerSignCommentResolved',
  })

  -- Diff signs
  vim.fn.sign_define('MRReviewerDiffAdd', {
    text = '+',
    texthl = 'DiffAdd',
  })

  vim.fn.sign_define('MRReviewerDiffChange', {
    text = '~',
    texthl = 'DiffChange',
  })
end

return M
