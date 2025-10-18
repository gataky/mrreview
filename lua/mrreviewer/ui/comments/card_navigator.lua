-- lua/mrreviewer/ui/comments/card_navigator.lua
-- Card-level navigation logic for comments panel
--
-- This module handles navigation between comment cards in the comments panel.
-- Navigation is card-based rather than line-based, treating each card as a
-- single unit for cursor movement.

local M = {}
local logger = require('mrreviewer.core.logger')

--- Find the card at the current cursor line
--- @param buf number Buffer ID
--- @param line_num number Line number (1-indexed)
--- @return table|nil Card object or nil if not found
function M.find_card_at_line(buf, line_num)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    logger.warn('card_navigator', 'Invalid buffer')
    return nil
  end

  -- Get card map from buffer variable
  local ok, card_map = pcall(vim.api.nvim_buf_get_var, buf, 'mrreviewer_card_map')
  if not ok or not card_map then
    logger.debug('card_navigator', 'No card map found in buffer')
    return nil
  end

  -- Check if this line has a card
  local card = card_map[line_num]
  if card then
    logger.debug('card_navigator', 'Found card at line', {
      line = line_num,
      card_id = card.id,
      is_thread = card.is_thread,
    })
    return card
  end

  logger.debug('card_navigator', 'No card found at line', { line = line_num })
  return nil
end

--- Move cursor to the next card in the buffer
--- @param buf number Buffer ID
--- @param win number Window ID
--- @return boolean Success status
function M.move_to_next_card(buf, win)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    logger.warn('card_navigator', 'Invalid buffer')
    return false
  end

  if not win or not vim.api.nvim_win_is_valid(win) then
    logger.warn('card_navigator', 'Invalid window')
    return false
  end

  -- Get current cursor position
  local cursor = vim.api.nvim_win_get_cursor(win)
  local current_line = cursor[1]

  -- Get card map
  local ok, card_map = pcall(vim.api.nvim_buf_get_var, buf, 'mrreviewer_card_map')
  if not ok or not card_map then
    logger.debug('card_navigator', 'No card map found')
    return false
  end

  -- Find current card to determine its end
  local current_card = M.find_card_at_line(buf, current_line)
  local search_start_line = current_line

  -- If we're in a card, start searching after the current card
  if current_card then
    -- Find the end of the current card by scanning forward
    for line = current_line, vim.api.nvim_buf_line_count(buf) do
      if card_map[line] ~= current_card then
        search_start_line = line
        break
      end
    end
  end

  -- Search for the next card
  local line_count = vim.api.nvim_buf_line_count(buf)
  for line = search_start_line + 1, line_count do
    local card = card_map[line]
    if card then
      -- Check if this is actually a different card (not the same one)
      if not current_card or card.id ~= current_card.id then
        -- Move cursor to the first line of this card
        vim.api.nvim_win_set_cursor(win, { line, 0 })
        logger.info('card_navigator', 'Moved to next card', {
          from_line = current_line,
          to_line = line,
          card_id = card.id,
        })
        return true
      end
    end
  end

  -- No next card found, wrap to first card
  for line = 1, current_line do
    local card = card_map[line]
    if card then
      vim.api.nvim_win_set_cursor(win, { line, 0 })
      logger.info('card_navigator', 'Wrapped to first card', {
        from_line = current_line,
        to_line = line,
        card_id = card.id,
      })
      return true
    end
  end

  logger.debug('card_navigator', 'No next card found')
  return false
end

--- Move cursor to the previous card in the buffer
--- @param buf number Buffer ID
--- @param win number Window ID
--- @return boolean Success status
function M.move_to_prev_card(buf, win)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    logger.warn('card_navigator', 'Invalid buffer')
    return false
  end

  if not win or not vim.api.nvim_win_is_valid(win) then
    logger.warn('card_navigator', 'Invalid window')
    return false
  end

  -- Get current cursor position
  local cursor = vim.api.nvim_win_get_cursor(win)
  local current_line = cursor[1]

  -- Get card map
  local ok, card_map = pcall(vim.api.nvim_buf_get_var, buf, 'mrreviewer_card_map')
  if not ok or not card_map then
    logger.debug('card_navigator', 'No card map found')
    return false
  end

  -- Find current card to determine its start
  local current_card = M.find_card_at_line(buf, current_line)
  local search_start_line = current_line

  -- If we're in a card, start searching before the current card
  if current_card then
    -- Find the start of the current card by scanning backward
    for line = current_line, 1, -1 do
      if card_map[line] ~= current_card then
        search_start_line = line
        break
      end
      -- If we reached line 1 and still in current card, start search from line 0
      if line == 1 then
        search_start_line = 0
      end
    end
  end

  -- Search backward for the previous card
  for line = search_start_line - 1, 1, -1 do
    local card = card_map[line]
    if card then
      -- Check if this is actually a different card (not the same one)
      if not current_card or card.id ~= current_card.id then
        -- Find the first line of this card by scanning backward
        local card_start_line = line
        for scan_line = line - 1, 1, -1 do
          if card_map[scan_line] == card then
            card_start_line = scan_line
          else
            break
          end
        end

        -- Move cursor to the first line of this card
        vim.api.nvim_win_set_cursor(win, { card_start_line, 0 })
        logger.info('card_navigator', 'Moved to previous card', {
          from_line = current_line,
          to_line = card_start_line,
          card_id = card.id,
        })
        return true
      end
    end
  end

  -- No previous card found, wrap to last card
  local line_count = vim.api.nvim_buf_line_count(buf)
  for line = line_count, current_line, -1 do
    local card = card_map[line]
    if card then
      -- Find the first line of this card
      local card_start_line = line
      for scan_line = line - 1, 1, -1 do
        if card_map[scan_line] == card then
          card_start_line = scan_line
        else
          break
        end
      end

      vim.api.nvim_win_set_cursor(win, { card_start_line, 0 })
      logger.info('card_navigator', 'Wrapped to last card', {
        from_line = current_line,
        to_line = card_start_line,
        card_id = card.id,
      })
      return true
    end
  end

  logger.debug('card_navigator', 'No previous card found')
  return false
end

--- Find the next file section header in the buffer
--- @param buf number Buffer ID
--- @param start_line number Starting line number (1-indexed)
--- @return number|nil Line number of next file section or nil if not found
function M.find_next_file_section(buf, start_line)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    logger.warn('card_navigator', 'Invalid buffer')
    return nil
  end

  local line_count = vim.api.nvim_buf_line_count(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  -- Search forward for next file header (lines starting with 📁)
  for line_num = start_line + 1, line_count do
    local line = lines[line_num]
    if line and line:match('^📁') then
      logger.debug('card_navigator', 'Found next file section', {
        from_line = start_line,
        to_line = line_num,
      })
      return line_num
    end
  end

  logger.debug('card_navigator', 'No next file section found', {
    from_line = start_line,
  })
  return nil
end

--- Find the previous file section header in the buffer
--- @param buf number Buffer ID
--- @param start_line number Starting line number (1-indexed)
--- @return number|nil Line number of previous file section or nil if not found
function M.find_prev_file_section(buf, start_line)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    logger.warn('card_navigator', 'Invalid buffer')
    return nil
  end

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  -- Search backward for previous file header (lines starting with 📁)
  for line_num = start_line - 1, 1, -1 do
    local line = lines[line_num]
    if line and line:match('^📁') then
      logger.debug('card_navigator', 'Found previous file section', {
        from_line = start_line,
        to_line = line_num,
      })
      return line_num
    end
  end

  logger.debug('card_navigator', 'No previous file section found', {
    from_line = start_line,
  })
  return nil
end

return M
