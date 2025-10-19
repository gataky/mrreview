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

  -- Diffview-specific highlights
  MRReviewerCommentCount = { fg = '#7aa2f7', italic = true },
  MRReviewerCommentHighlight = { bg = '#3d59a1', bold = true },
  MRReviewerSelectedComment = { link = 'CursorLine' },
  MRReviewerCommentFileHeader = { fg = '#bb9af7', bold = true },
  MRReviewerResolvedComment = { fg = '#565f89', italic = true },
  MRReviewerUnresolvedComment = { fg = '#ff9e64' },

  -- Card-based UI highlights
  MRReviewerCardSelected = { fg = '#ff9e64', bold = true, underline = true }, -- Highlighted selected card border (bright orange, bold + underline)
  MRReviewerCardResolved = { fg = '#565f89', italic = true }, -- Dimmed resolved cards
  MRReviewerCardBorder = { fg = '#7aa2f7' }, -- Card border characters

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

  -- File tree highlights (inspired by diffview.nvim)
  MRReviewerFilePanelTitle = { fg = '#7aa2f7', bold = true },
  MRReviewerFilePanelCounter = { fg = '#bb9af7', bold = true },
  MRReviewerFilePanelFileName = { link = 'Normal' },
  MRReviewerFilePanelPath = { link = 'Comment' },
  MRReviewerFilePanelSelected = { link = 'CursorLine' },

  -- Directory/folder highlights
  MRReviewerFolderName = { link = 'Directory' },
  MRReviewerFolderSign = { link = 'PreProc' },

  -- File node highlights
  MRReviewerFileName = { link = 'Normal' },
  MRReviewerFileSign = { fg = '#565f89' },

  -- Tree structure indentation (subtle guide)
  MRReviewerTreeIndent = { fg = '#3b4261' },
}

--- Setup highlight groups
function M.setup()
  local config = require('mrreviewer.core.config')

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
    comment_count = 'MRReviewerCommentCount',
    comment_highlight = 'MRReviewerCommentHighlight',
    selected_comment = 'MRReviewerSelectedComment',
    comment_file_header = 'MRReviewerCommentFileHeader',
    sign_comment = 'MRReviewerSignComment',
    sign_comment_resolved = 'MRReviewerSignCommentResolved',
    virtual_text = 'MRReviewerVirtualText',
    virtual_text_resolved = 'MRReviewerVirtualTextResolved',
    title = 'MRReviewerTitle',
    border = 'MRReviewerBorder',
    selection = 'MRReviewerSelection',
    -- File tree highlights
    file_panel_title = 'MRReviewerFilePanelTitle',
    file_panel_counter = 'MRReviewerFilePanelCounter',
    file_panel_filename = 'MRReviewerFilePanelFileName',
    file_panel_path = 'MRReviewerFilePanelPath',
    file_panel_selected = 'MRReviewerFilePanelSelected',
    folder_name = 'MRReviewerFolderName',
    folder_sign = 'MRReviewerFolderSign',
    file_name = 'MRReviewerFileName',
    file_sign = 'MRReviewerFileSign',
    tree_indent = 'MRReviewerTreeIndent',
    -- Card highlights
    card_selected = 'MRReviewerCardSelected',
    card_resolved = 'MRReviewerCardResolved',
    card_border = 'MRReviewerCardBorder',
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

  -- Comment range bracket signs (for multi-line comments)
  vim.fn.sign_define('MRReviewerCommentRangeTop', {
    text = '┌',
    texthl = 'MRReviewerSignComment',
  })

  vim.fn.sign_define('MRReviewerCommentRangeMiddle', {
    text = '│',
    texthl = 'MRReviewerSignComment',
  })

  vim.fn.sign_define('MRReviewerCommentRangeBottom', {
    text = '└',
    texthl = 'MRReviewerSignComment',
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
