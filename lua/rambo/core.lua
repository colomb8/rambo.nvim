------------------------------------------------------------------------------
--[[

Rambo.nvim

Author: Dario Colombotto
  email: dario.colombotto@outlook.com
  Telegram: https://t.me/colomb8

License: MIT (see LICENSE)

--]]
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Lua/Neovim Utility Functions
------------------------------------------------------------------------------

local function byteToUtf(line, col)
  local utf_32_index, utf_16_index = vim.str_utfindex(line, col and col - 1)
  return utf_32_index
end

local function utfToByte(line, index)
  return vim.str_byteindex(line, index) + 1
end

local function splitStr(str, sep)
  sep = sep or '%s'
  local t = {}
  for field, s in string.gmatch(str, "([^"..sep.."]*)("..sep.."?)") do
    table.insert(t, field)
    if s == "" then
      return t
    end
  end
end

local function sendKeys(keys, mode)
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes(keys, true, false, true),
    mode,
    true)
end

local function deleteLine(row)
  vim.api.nvim_buf_set_lines(
      0, -- buffer, 0 for current
      row - 1, -- start line, 0-based, inclusive
      row, -- end line, 0-based, exclusive
      true, -- strict_indexing
      {} -- replacement
    )
end

local function cutLine(row)
  local line = vim.fn.getline(row)
  vim.api.nvim_buf_set_lines(
      0, -- buffer, 0 for current
      row - 1, -- start line, 0-based, inclusive
      row, -- end line, 0-based, exclusive
      true, -- strict_indexing
      {} -- replacement
    )
  return line
end

local function insertLine(row, line)
  vim.api.nvim_buf_set_lines(
      0, -- buffer, 0 for current
      row - 1, -- start line, 0-based, inclusive
      row - 1, -- end line, 0-based, exclusive
      true, -- strict_indexing
      {line} -- replacement
    )
end

local function setCursor(row, col)
  vim.api.nvim_win_set_cursor(
    0, -- buffer, 0 for current
    {
      row, -- 1-based
      col - 1, -- 0-based
    })
end

local function getSelectionRawBounds()
  -- raw! no logic here!
  local mode = vim.fn.mode()
  local valid_modes = {
    ['v'] = true, -- visual
    ['V'] = true, -- visual line
    ['\22'] = true, -- visual block (^V)
    ['s'] = true, -- select
    ['S'] = true, -- select line
    ['\19'] = true, -- select block (^S)
    }
  assert(valid_modes[mode], 'Invalid mode: -' .. mode .. '-')
  --
  local _, r1, c1, _ = unpack(vim.fn.getpos("v"))
  local _, r2, c2, _ = unpack(vim.fn.getpos("."))
  --
  return r1, c1, r2, c2
end

local function normalizeBoundsGetDirection(r1, c1, r2, c2)
  local dir, _r1, _c1, _r2, _c2
  -- sort bounds
  if r1 < r2 or (r1 == r2 and c1 <= c2) then
    dir = 1
    _r1, _c1, _r2, _c2 = r1, c1, r2, c2
  else
    dir = -1
    _r1, _c1, _r2, _c2 = r2, c2, r1, c1
  end
  _c2 = _c2 - 1
  return _r1, _c1, _r2, _c2, dir
end

local function getSelectionBoundsAndDirection()
  -- this is only a quicker way to get normalized bounds.
  -- no logic here!
  local r1, c1, r2, c2 = getSelectionRawBounds()
  local _r1, _c1, _r2, _c2, dir = normalizeBoundsGetDirection(r1, c1, r2, c2)
  return _r1, _c1, _r2, _c2, dir
end

local function getTextFromBounds(r1, c1, r2, c2)
  local tmp = vim.api.nvim_buf_get_text(
    0, -- buffer, 0 for current
    r1 - 1, -- start_row, 0-based, inclusive
    c1 - 1, -- start_col, 0-based, inclusive
    r2 - 1, -- end_row, 0-based, inclusive
    c2, -- end_col, 0-based, exclusive
    {} -- opts
    )
  return tmp
end

local function getSelectionText()
  local mode = vim.fn.mode()
  local valid_modes = {
    ['v'] = true, -- visual
    ['V'] = true, -- visual line
    -- ['\22'] = true, -- visual block (^V)
    ['s'] = true, -- select
    ['S'] = true, -- select line
    -- ['\19'] = true, -- select block (^S)
    }
  assert(valid_modes[mode], 'Invalid mode: -' .. mode .. '-')
  --
  local r1, c1, r2, c2, _ = getSelectionBoundsAndDirection()
  --
  if mode == 'V' or mode == 'S' then
    c1 = 1
    c2 = vim.fn.getline(r2):len() + 1
  end
  --
  return getTextFromBounds(r1, c1, r2, c2)
end

local function setExtmark(params)
  local r1 = params['row_start']
  local c1 = params['col_start']
  local r2 = params['row_end']
  local c2 = params['col_end']
  --
  if c2 == vim.fn.getline(r2):len() + 1 then -- onemore
    if r2 < vim.fn.line('$') then -- not last line
      r2 = r2 + 1
      c2 = 0
    else -- last line
      c2 = c2 - 1
    end
  end
  local extmark_id = vim.api.nvim_buf_set_extmark(
    0, -- {buffer}
    params['ns_id'], -- {ns_id}
    r1 - 1, -- {line}, 0-based, inclusive
    c1 - 1, -- {col}, 0-based, inclusive
    { -- {opts}
      end_row = r2 - 1, -- 0-based, inclusive
      end_col = c2, -- (0-based, exclusive) or (1-based, inclusive)
      hl_group = params['hl_group'],
      priority = params['priority'],
    })
  return extmark_id
end

local function delExtmark(params)
  local success = vim.api.nvim_buf_del_extmark(
    0, -- {buffer}
    params['ns_id'], -- {ns_id}
    params['extmark_id'] -- {id}
    )
  return success
end

local blink_text_ns_id = vim.api.nvim_create_namespace("blink_text_ns")

local function blinkText(params)
  local extmark_id = setExtmark({
    ['buffer'] = 0,
    ['ns_id'] = blink_text_ns_id,
    ['row_start'] = params['row_start'],
    ['col_start'] = params['col_start'],
    ['row_end'] = params['row_end'],
    ['col_end'] = params['col_end'],
    ['hl_group'] = params['hl_group'],
    ['priority'] = params['priority'],
  })
  vim.defer_fn(function()
    local del_success = delExtmark({
      ['buffer'] = 0,
      ['ns_id'] = blink_text_ns_id,
      ['extmark_id'] = extmark_id,
    })
    assert(del_success)
  end,
  params['blink_time'] -- delay ms
  )
end

local function setText(r1, c1, r2, c2, lines)
  vim.api.nvim_buf_set_text(
    0, -- {buffer}
    r1 - 1, -- {start_row}
    c1 - 1, -- {start_col}
    r2 - 1, -- {end_row}
    c2, -- {end_col}
    lines -- {replacement}
  )
end

local function insertText(row, col, lines)
  setText(
    row,
    col,
    row,
    col - 1,
    lines
    )
end

local function deleteText(r1, c1, r2, c2)
  local _r1 = r1
  local _c1 = c1
  local _r2 = r2
  local _c2 = c2
  --
  if _c2 == vim.fn.getline(_r2):len() + 1 then -- onemore
    if _r2 < vim.fn.line('$') then -- not last line
      _r2 = _r2 + 1
      _c2 = 0
    else -- last line
      _c2 = _c2 - 1
    end
  end
  --
  vim.api.nvim_buf_set_text(
    0, -- {buffer}
    _r1 - 1, -- {start_row}
    _c1 - 1, -- {start_col}
    _r2 - 1, -- {end_row}
    _c2, -- {end_col}
    {''} -- {replacement}
  )
end

local function advanceCursorFromLines(lines)
  local row = vim.fn.line('.')
  local col = vim.fn.col('.')
  local row_col_offset = #lines - 1
  local row_target = row + row_col_offset
  local col_target
  if row_col_offset == 0 then
    col_target = col + lines[#lines]:len()
  else
    col_target = lines[#lines]:len() + 1
  end
  setCursor(row_target, col_target)
end

------------------------------------------------------------------------------
-- Rambo.nvim Variables
------------------------------------------------------------------------------

local rambo_register_lines

local insert_special = false

local selection_original_value = vim.o.selection

local M = {}

------------------------------------------------------------------------------
-- Rambo.nvim Autocommands
------------------------------------------------------------------------------

vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = "*:ni[IRV]",
  callback = function(args)
    vim.o.selection = 'exclusive'
    insert_special = true
  end,
})

vim.api.nvim_create_autocmd("InsertEnter", {
  callback = function()
    vim.o.selection = selection_original_value
    insert_special = false
    rambo_register_lines = nil
      or rambo_register_lines
      or splitStr(vim.fn.getreg('"'), '\n')
      or splitStr(vim.fn.getreg('+'), '\n')
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", { -- yank or delete
  callback = function()
    if vim.fn.mode():match("[nvV\22]") then -- normal or any visual
      rambo_register_lines = splitStr(vim.fn.getreg('"'), '\n')
    end
  end,
})

------------------------------------------------------------------------------
-- Rambo.nvim Functions
------------------------------------------------------------------------------

local function getFirstEndOfWord(line)
  -- inclusive
  -- vim.regex uses vim.o.iskeyword !
  local r = vim.regex(""
    .. "\\("
      -- punct/symbol              ,  kw or blank
      .. "[^[:keyword:][:blank:]]" .. "[[:keyword:][:blank:]]"
    .. "\\)"
    .. "\\|" -- or
    .. "\\("
      -- kw              ,  blank or punct/symbol
      .. "[[:keyword:]]" .. "[^[:keyword:]]"
    .. "\\)"
  )
  local _, to = r:match_str(line .. " ") -- <--
  return to and to - 1
end

local function getLastBeginningOfWord(line)
  -- vim.regex uses vim.o.iskeyword !
  local tmp = getFirstEndOfWord(line:reverse())
  return tmp and line:len() - tmp + 1
end

local function getFirstBeginningOfWord(line)
  -- vim.regex uses vim.o.iskeyword !
  local r = vim.regex(""
    .. "\\("
      -- blank         ,  kw or punct/symbol
      .. "[[:blank:]]" .. "[^[:blank:]]"
    .. "\\)"
  )
  local from, to = r:match_str(" " .. line) -- <--
  return to and to - 1
end

local function rmbMotionCRight()
  local col = vim.fn.col('.')
  local row = vim.fn.line('.')
  local line = vim.fn.getline('.')
  local line_len = line:len()
  --
  local line_l = line:sub(0, col - 1)
  local line_r = line:sub(col)
  local col_feow_r = getFirstEndOfWord(line_r)
  --
  local row_target = row
  local col_target
  if col < line_len then
    if not col_feow_r then
      col_target = line_len + 1
    else
      col_target = line_l:len() + col_feow_r + 1
    end
  elseif col == line_len then
    col_target = line_len + 1
  else -- col > line_len (onemore)
    if row < vim.fn.line('$') then
      row_target = row + 1
      col_target = 1
    else
      col_target = col -- (return)
    end
  end
  --
  setCursor(row_target, col_target)
end

local function rmbMotionCLeft()
  local col = vim.fn.col('.')
  local row = vim.fn.line('.')
  local line = vim.fn.getline('.')
  local line_l = line:sub(0, col - 1)
  local col_lbow_l = getLastBeginningOfWord(line_l)
  --
  local row_target = row
  local col_target
  if col_lbow_l then
    col_target = col_lbow_l
  elseif col <= 1 then
    if row > 1 then
      col_target = vim.fn.getline(row - 1):len() + 1
      row_target = row_target - 1
    else
      return nil
    end
  else
    col_target = 1
  end
  setCursor(row_target, col_target)
end

local function rmbMotionHome()
  -- cycle between col 1 and first word
  local col = vim.fn.col('.')
  local row = vim.fn.line('.')
  local line = vim.fn.getline('.')
  local col_fbow = getFirstBeginningOfWord(line)
  local line_l = line:sub(0, col - 1)
  local col_fbow_l = getFirstBeginningOfWord(line_l)
  --
  local row_target = row
  local col_target
  if col == 1 and col_fbow then
    col_target = col_fbow
  elseif col_fbow_l then
    col_target = col_fbow_l
  else
    col_target = 1
  end
  setCursor(row_target, col_target)
end

local function rmbMotionEnd()
  local col = vim.fn.col('.')
  local row = vim.fn.line('.')
  local line = vim.fn.getline('.')
  local line_len = line:len()
  --
  local row_target = row
  local col_target
  if col == line_len + 1 then -- onemore
    return nil
  else
    col_target = line_len + 1
  end
  setCursor(row_target, col_target)
end

local function rmbMotionLeft()
  local col = vim.fn.col('.')
  local row = vim.fn.line('.')
  --
  local row_target
  local col_target
  if col == 1 then
    if row == 1 then
      return nil
    else
      row_target = row - 1
      col_target = vim.fn.getline(row - 1):len() + 1
    end
  else
    row_target = row
    col_target = col - 1
  end
  setCursor(row_target, col_target)
end

local function rmbMotionRight()
  local col = vim.fn.col('.')
  local row = vim.fn.line('.')
  local line_len = vim.fn.getline('.'):len()
  local row_last = vim.fn.line('$')
  --
  local row_target = row
  local col_target
  if col <= line_len then
      col_target = col + 1
  else -- col > line_end (onemore) 
    if row == row_last then
      return nil
    else
      row_target = row + 1
      col_target = 1
    end
  end
  setCursor(row_target, col_target)
end

local function rmbMotionPageUp()
  local row = vim.fn.line('.')
  local col = vim.fn.col('.')
  local win_height = vim.api.nvim_win_get_height(0)
  --
  local row_target
  local col_target
  if row == 1 then
    if col == 1 then
      return nil
    else
      row_target = 1
      col_target = 1
    end
  else
    row_target = math.max(1, row - win_height)
    col_target = 1
  end
  setCursor(row_target, col_target)
end

local function rmbMotionPageDown()
  local row = vim.fn.line('.')
  local col = vim.fn.col('.')
  local win_height = vim.api.nvim_win_get_height(0)
  local buf_line_count = vim.api.nvim_buf_line_count(0)
  --
  local row_target
  local col_target
  if row == buf_line_count then
    local line_target_len = vim.fn.getline('.'):len()
    if col == line_target_len + 1 then
      return nil
    else
      row_target = row
      col_target = line_target_len + 1
    end
  else
    row_target = math.min(buf_line_count, row + win_height)
    col_target = 1
  end
  setCursor(row_target, col_target)
end

local function rmbMotionCUp()
  local r = vim.fn.line('.')
  --
  local line_x = vim.fn.getline(r)
  while r >= 2 do
    r = r - 1
    local line_y = vim.fn.getline(r)
    if line_x:len() > 0 and line_y:len() == 0 then
      break
    end
    line_x = line_y
  end
  local row_target = r
  local col_target = 1
  setCursor(row_target, col_target)
end

local function rmbMotionCDown()
  local r = vim.fn.line('.')
  local buf_line_count = vim.api.nvim_buf_line_count(0)
  --
  local line_x = vim.fn.getline(r)
  local line_y
  while r < buf_line_count do
    r = r + 1
    line_y = vim.fn.getline(r)
    if line_x:len() > 0 and line_y:len() == 0 then
      break
    end
    line_x = line_y
  end
  local row_target = r
  local col_target
  if not line_y then
    col_target = line_x:len() + 1
  elseif line_y:len() == 0 then
    col_target = 1
  else
    col_target = line_y:len() + 1
  end
  setCursor(row_target, col_target)
end

local function rmbMotionUp()
  sendKeys('<UP>', 'n')
end

local function rmbMotionDown()
  sendKeys('<DOWN>', 'n')
end

local function rmbLeaveSelectLeft()
  local r, c, _, _, _ = getSelectionBoundsAndDirection()
  sendKeys('<ESC>', 'n')
  vim.schedule(function() setCursor(r, c) end)
end

local function rmbLeaveSelectRight()
  local _, _, r, c, _ = getSelectionBoundsAndDirection()
  if c == vim.fn.getline(r):len() + 1 then -- onemore
    if r < vim.fn.line('$') then -- not last row
      r = r + 1
      c = 1
    end
  else
    c = c + 1
  end
  sendKeys('<ESC>', 'n')
  vim.schedule(function() setCursor(r, c) end)
end

local function rmbMotionCHome()
  local row_target = 1
  local col_target = 1
  setCursor(row_target, col_target)
end

local function rmbMotionCEnd()
  local row_last = vim.fn.line('$')
  local col_lastrow = vim.fn.getline(row_last):len() + 1
  local row_target = row_last
  local col_target = col_lastrow
  setCursor(row_target, col_target)
end

local function rmbMoveLineUp()
  local row = vim.fn.line('.')
  local col = vim.fn.col('.')
  --
  if row == 1 then return end
  local line = cutLine(row - 1)
  insertLine(row, line)
  setCursor(row - 1, col)
end

local function rmbMoveLineDown()
  local row = vim.fn.line('.')
  local col = vim.fn.col('.')
  local row_last = vim.fn.line('$')
  --
  if row == row_last then return end
  local line = cutLine(row)
  insertLine(row + 1, line)
  setCursor(row + 1, col)
end

local function rmbMoveLinesUp()
  local _, v_row_start, v_col_start, _ = unpack(vim.fn.getpos("v"))
  local _, v_row_end, v_col_end, _ = unpack(vim.fn.getpos("."))
  --
  local row_top = math.min(v_row_start, v_row_end)
  local row_bottom = math.max(v_row_start, v_row_end)
  --
  if row_top == 1 then return end
  local line_tmp = cutLine(row_top - 1)
  insertLine(row_bottom, line_tmp)
  --
  sendKeys('<ESC>', 'n')
  setCursor(v_row_start - 1, v_col_start)
  sendKeys('<C-o>v<C-g>', 'nx')
  setCursor(v_row_end - 1, v_col_end)
end

local function rmbMoveLinesDown()
  local _, v_row_start, v_col_start, _ = unpack(vim.fn.getpos("v"))
  local _, v_row_end, v_col_end, _ = unpack(vim.fn.getpos("."))
  local row_last = vim.fn.line('$')
  --
  local row_top = math.min(v_row_start, v_row_end)
  local row_bottom = math.max(v_row_start, v_row_end)
  --
  if row_bottom == row_last then return end
  local line_tmp = cutLine(row_bottom + 1)
  insertLine(row_top, line_tmp)
  --
  sendKeys('<ESC>', 'n')
  setCursor(v_row_start + 1, v_col_start)
  sendKeys('<C-o>v<C-g>', 'nx')
  setCursor(v_row_end + 1, v_col_end)
end

local function rmbCopy()
  local r1, c1, r2, c2, _ = getSelectionBoundsAndDirection()
  rambo_register_lines =  getTextFromBounds(r1, c1, r2, c2)
  local tmp = table.concat(rambo_register_lines, '\n')
  vim.fn.setreg('"', tmp, 'c')
  vim.fn.setreg('+', tmp, 'c')
  --
  blinkText({
    ['buffer'] = 0,
    ['row_start'] = r1,
    ['col_start'] = c1,
    ['row_end'] = r2,
    ['col_end'] = c2,
    ['hl_group'] = 'IncSearch', -- as vim.highlight.on_yank()
    -- Priority is useless because Visual/Select has
    -- always highest prio; so only foreground blinks
    -- ['priority'] = 1000,
    ['blink_time'] = 150,
  })
end

local function rmbCut()
  local r1, c1, r2, c2, _ = getSelectionBoundsAndDirection()
  rambo_register_lines = getTextFromBounds(r1, c1, r2, c2)
  local tmp = table.concat(rambo_register_lines, '\n')
  vim.fn.setreg('"', tmp, 'c')
  vim.fn.setreg('+', tmp, 'c')
  sendKeys('<ESC>', 'n')
  deleteText(r1, c1, r2, c2)
end

local function rmbPaste(submode)
  if submode == 'insert' then
    local row = vim.fn.line('.')
    local col = vim.fn.col('.')
    insertText(row, col, rambo_register_lines)
    advanceCursorFromLines(rambo_register_lines)
  elseif submode == 'select' then
    local r1, c1, r2, c2, _ = getSelectionBoundsAndDirection()
    sendKeys('<ESC>', 'n')
    deleteText(r1, c1, r2, c2)
    insertText(r1, c1, rambo_register_lines)
  else
    error(submode)
  end
end

local function setSelect(r1, c1, r2, c2, dir)
  -- if directly mapped
  -- add schedule and remove x in 'nx'
  -- print('ss', r1, c1, r2, c2, dir)
  --
  local _r2 = r2
  local _c2 = c2
  _c2 = _c2 + 1
  if dir == 1 then
    setCursor(r1, c1)
    sendKeys('<C-\\><C-o>v<C-g>', 'nx') -- warn! x
    -- vim.schedule(function()
      setCursor(_r2, _c2)
    -- end)
  elseif dir == -1 then
    setCursor(_r2, _c2)
    sendKeys('<C-\\><C-o>v<C-g>', 'nx') -- warn! x
    -- vim.schedule(function()
      setCursor(r1, c1)
    -- end)
  else
    error(dir)
  end
end

------------------------------------------------------------------------------
-- Rambo.nvim Keybindings
------------------------------------------------------------------------------

function M.setup(cfg)

  -- Cfg validation ------------------------------------------------------------
  for k, _ in pairs(cfg) do
    assert(vim.list_contains({
      'operations_key',
    }, k), 'unknown configuration name: ' .. k)
  end

  assert(
    vim.list_contains({'C', 'M'}, cfg.operations_key),
    '`operations_key` supports only "C" or "M"; received ' .. cfg.operations_key)


  -- Moving in Insert ----------------------------------------------------------

  for k, f in pairs({
    ['<LEFT>'] = rmbMotionLeft,
    ['<RIGHT>'] = rmbMotionRight,
    ['<UP>'] = rmbMotionUp,
    ['<DOWN>'] = rmbMotionDown,
    ['<C-LEFT>'] = rmbMotionCLeft,
    ['<C-RIGHT>'] = rmbMotionCRight,
    ['<C-UP>'] = rmbMotionCUp,
    ['<C-DOWN>'] = rmbMotionCDown,
    ['<HOME>'] = rmbMotionHome,
    ['<END>'] = rmbMotionEnd,
    ['<C-HOME>'] = rmbMotionCHome,
    ['<C-END>'] = rmbMotionCEnd,
    ['<PAGEUP>'] = rmbMotionPageUp,
    ['<PAGEDOWN>'] = rmbMotionPageDown,
    }) do
    vim.keymap.set('i', k, f)
  end

  -- Start Select-in-Insert mode -----------------------------------------------

  for k, f in pairs({
    ['<S-LEFT>'] = rmbMotionLeft,
    ['<S-UP>'] = rmbMotionUp,
    ['<C-S-LEFT>'] = rmbMotionCLeft,
    ['<C-S-UP>'] = rmbMotionCUp,
    -- ['<S-HOME>'] = rmbMotionHome,
    ['<C-S-HOME>'] = rmbMotionCHome,
    ['<S-PAGEUP>'] = rmbMotionPageUp,
    }) do
             --
    vim.keymap.set('i', k, function()
      if vim.fn.col('.') == 1 and vim.fn.line('.') == 1 -- BOF
        then return end
      sendKeys('<C-\\><C-o>v<C-g>', 'n')
      vim.schedule(f)
    end)
  end

  vim.keymap.set('i', '<S-HOME>', function()
    if vim.fn.col('.') == 1 then return end
    sendKeys('<C-\\><C-o>v<C-g>', 'n')
    vim.schedule(rmbMotionHome)
  end)

  for k, f in pairs({
    ['<S-RIGHT>'] = rmbMotionRight,
    ['<S-DOWN>'] = rmbMotionDown,
    ['<C-S-RIGHT>'] = rmbMotionCRight,
    ['<C-S-DOWN>'] = rmbMotionCDown,
    -- ['<S-END>'] = rmbMotionEnd,
    ['<C-S-END>'] = rmbMotionCEnd,
    ['<S-PAGEDOWN>'] = rmbMotionPageDown,
    }) do
    --
    vim.keymap.set('i', k, function()
      if vim.fn.col('.') == vim.fn.col('$')
        and vim.fn.line('.') == vim.fn.line('$') -- EOF
      then return end
      sendKeys('<C-\\><C-o>v<C-g>', 'n')
      vim.schedule(f)
    end)
  end

  vim.keymap.set('i', '<S-END>', function()
    if vim.fn.col('.') == vim.fn.getline('.'):len() + 1 then return end
    sendKeys('<C-\\><C-o>v<C-g>', 'n')
    vim.schedule(rmbMotionEnd)
  end)

  -- Changing selection --------------------------------------------------------

  for k, f in pairs({
    ['<S-LEFT>'] = rmbMotionLeft,
    ['<S-RIGHT>'] = rmbMotionRight,
    ['<S-UP>'] = rmbMotionUp,
    ['<S-DOWN>'] = rmbMotionDown,
    ['<C-S-LEFT>'] = rmbMotionCLeft,
    ['<C-S-RIGHT>'] = rmbMotionCRight,
    ['<C-S-UP>'] = rmbMotionCUp,
    ['<C-S-DOWN>'] = rmbMotionCDown,
    ['<S-HOME>'] = rmbMotionHome,
    ['<S-END>'] = rmbMotionEnd,
    ['<C-S-HOME>'] = rmbMotionCHome,
    ['<C-S-END>'] = rmbMotionCEnd,
    ['<S-PAGEUP>'] = rmbMotionPageUp,
    ['<S-PAGEDOWN>'] = rmbMotionPageDown,
    }) do
    vim.keymap.set('s', k, f)
  end

  -- Stop Select-in-Insert mode ------------------------------------------------

  vim.keymap.set('s', '<LEFT>', rmbLeaveSelectLeft)
  vim.keymap.set('s', '<RIGHT>', rmbLeaveSelectRight)
  for k, f in pairs({
    ['<UP>'] = rmbMotionUp,
    ['<DOWN>'] = rmbMotionDown,
    ['<C-LEFT>'] = rmbMotionCLeft,
    ['<C-RIGHT>'] = rmbMotionCRight,
    ['<C-UP>'] = rmbMotionCUp,
    ['<C-DOWN>'] = rmbMotionCDown,
    ['<HOME>'] = rmbMotionHome,
    ['<END>'] = rmbMotionEnd,
    ['<C-HOME>'] = rmbMotionCHome,
    ['<C-END>'] = rmbMotionCEnd,
    ['<PAGEUP>'] = rmbMotionPageUp,
    ['<PAGEDOWN>'] = rmbMotionPageDown,
    }) do
    vim.keymap.set('s', k, function()
      sendKeys('<ESC>', 'n')
      vim.schedule(f)
    end)
  end

  -- rmbMove Lines in Insert ---------------------------------------------------

  vim.keymap.set('i', '<M-UP>', rmbMoveLineUp)
  vim.keymap.set('i', '<M-DOWN>', rmbMoveLineDown)
  vim.keymap.set('s', '<M-UP>', rmbMoveLinesUp)
  vim.keymap.set('s', '<M-DOWN>', rmbMoveLinesDown)


  -- Tab for indent in Select mode ---------------------------------------------

  vim.keymap.set('s', '<TAB>', function()
    local mode = vim.fn.mode()
    if mode == 's' or mode == '\19' -- Select or Select-block (^S)
      then
      return '<C-g>V>gv<C-g>'
    elseif vim.fn.mode() == 'S' then
      return '<C-g>>gv<C-g>'
    else
      error(mode)
    end
  end,
  { expr = true, desc = 'Indent' })

  vim.keymap.set('s', '<S-TAB>', function()
    local mode = vim.fn.mode()
    if mode == 's' or mode == '\19' -- Select or Select-block (^S)
      then
      return '<C-g>V<gv<C-g>'
    elseif vim.fn.mode() == 'S' then
      return '<C-g><gv<C-g>'
    else
      error(mode)
    end
  end,
  { expr = true, desc = 'Dedent' })

  -- Operations ----------------------------------------------------------------

  -- Select mode: Copy to { ", rambo_register_lines }
  vim.keymap.set('s', '<' .. cfg.operations_key .. '-c>', rmbCopy)

  -- Select mode: Cut to { ", rambo_register_lines }
  vim.keymap.set('s', '<' .. cfg.operations_key .. '-x>', rmbCut)

  -- Select mode: Paste from rambo_register_lines
  vim.keymap.set('s', '<' .. cfg.operations_key .. '-v>', function() rmbPaste('select') end)

  -- Insert mode: Copy -> No Op.
  vim.keymap.set('i', '<' .. cfg.operations_key .. '-c>', '<NOP>')

  -- Insert mode: Cut -> No Op.
  vim.keymap.set('i', '<' .. cfg.operations_key .. '-x>', '<NOP>')

  -- Insert mode: Paste from rambo_register_lines
  vim.keymap.set('i', '<' .. cfg.operations_key .. '-v>', function() rmbPaste('insert') end)

  -- Undo/Redo in Insert/Select
  vim.keymap.set('i', '<' .. cfg.operations_key .. '-z>', '<C-o>u')
  vim.keymap.set('s', '<' .. cfg.operations_key .. '-z>', '<ESC>ui')
  -- vim.keymap.set('i', '<' .. cfg.operations_key .. '-Z>', '<C-o><C-r>') -- ko w C-
  -- vim.keymap.set('s', '<' .. cfg.operations_key .. '-Z>', '<ESC><C-r>i') -- ko w C-
  vim.keymap.set('i', '<' .. cfg.operations_key .. '-y>', '<C-o><C-r>')
  vim.keymap.set('s', '<' .. cfg.operations_key .. '-y>', '<ESC><C-r>i')

  -- Select all
  vim.keymap.set('i', '<' .. cfg.operations_key .. '-a>', function()
    rmbMotionCHome()
    sendKeys('<C-o>v<C-g>', 'n')
    vim.schedule(function() rmbMotionCEnd() end)
  end)

  -- Search in Insert mode
  vim.keymap.set('i', '<' .. cfg.operations_key .. '-f>', '<C-o>/')

  -- F3 / F4 and S-F3 for jump between search results
  -- vim.keymap.set({'i', 's'}, '<F3>',  '<C-o>n')
  -- vim.keymap.set({'i', 's'}, '<F15>', '<C-o>N') -- = S-<F3>
  -- vim.keymap.set({'i', 's'}, '<F2>', '<C-o>N') -- = S-<F3>

  -- Insert: search forward
  vim.keymap.set('i', '<F3>', function()
    sendKeys('<C-o>gn<C-g>', 'n')
  end)

  -- Insert: search backward
  vim.keymap.set('i', '<F15>', function()
    sendKeys('<C-o>gN<C-g>', 'n')
  end)
  vim.keymap.set('i', '<F2>', function()
    sendKeys('<C-o>gN<C-g>', 'n')
  end)

  -- Select: search forward
  vim.keymap.set('s', '<F3>', function()
    sendKeys('<ESC><C-\\><C-o>gn<C-g>', 'nx')
  end)
  vim.keymap.set('n', '<F3>', function()
    sendKeys('i<C-\\><C-o>gn<C-g>', 'nx')
  end)

  -- Select: search backward
  vim.keymap.set('s', '<F15>', function()
    rmbMotionLeft()
    sendKeys('<ESC><C-\\><C-o>gN<C-g>', 'nx')
  end)
  vim.keymap.set('n', '<F15>', function()
    rmbMotionLeft()
    sendKeys('i<C-\\><C-o>gN<C-g>', 'nx')
  end)
  vim.keymap.set('s', '<F2>', function()
    rmbMotionLeft()
    sendKeys('<ESC><C-\\><C-o>gN<C-g>', 'nx')
  end)
  vim.keymap.set('n', '<F2>', function()
    rmbMotionLeft()
    sendKeys('i<C-\\><C-o>gN<C-g>', 'nx')
  end)

  -- Disable hlsearch
  vim.keymap.set({'n', 'i', 's'}, '<F4>',  '<cmd>:nohl<CR>')

  -- Search text under Selection
  vim.keymap.set('s', '<' .. cfg.operations_key .. '-f>', function()
    sendKeys('<C-g>', 'n')
    vim.schedule(function() sendKeys('*', 'n') end)
  end)

  -- Del/BS in Select (blackhole reg)
  vim.keymap.set('s', '<DEL>', '<C-g>"_c' )
  vim.keymap.set('s', '<BS>', '<C-g>"_c' )

  -- Cycle between ins-special-Visual and ins-special-Select modes
  vim.keymap.set('x', '<INSERT>', function()
    if insert_special then
      sendKeys('<C-g>', 'n')
    else
      sendKeys('<INSERT>', 'n')
    end
  end)
  vim.keymap.set('s', '<INSERT>', function()
    if insert_special then
      sendKeys('<C-g>', 'n')
    else
      sendKeys('<INSERT>', 'n')
    end
  end)

  -- Switch Select to Select Line
  vim.keymap.set('s', '<' .. cfg.operations_key .. '-l>', function()
    if insert_special then
      sendKeys('<C-g>V<C-g>', 'n')
    else
      sendKeys('<C-l>', 'n')
    end
  end)

  -- Wrapping utilities: (), [], {}, "", '', <>
  for _, cfg in pairs({
    {'(', '( ', ' )'}, {')', '(', ')'},
    {'[', '[ ', ' ]'}, {']', '[', ']'},
    {'{', '{ ', ' }'}, {'}', '{', '}'},
    {'<', '< ', ' >'}, {'>', '<', '>'},
    {'"', '"', '"'},
    {"'", "'", "'"},
    {"`", "`", "`"},
    -- commented becomes repeating it manually is better
    -- {'"""', '"""', '"""'},
    -- {"```", "```", "```"},
    }) do
    local key, op, cl = cfg[1], cfg[2], cfg[3]
    --
    vim.keymap.set('s', key, function()
      local r1, c1, r2, c2, dir = getSelectionBoundsAndDirection()
      local len_l = op:len()
      sendKeys('<ESC>', 'n')
      insertText(r2, c2 + 1, {cl})
      insertText(r1, c1, {op})
      setSelect(
        r1,
        c1 + len_l,
        r2,
        c2 + (r1 == r2 and len_l or 0),
        dir)
    end)
  end

  ------------------------------------------------------------------------------
  -- Scratch / Notes
  ------------------------------------------------------------------------------

  --[[


  1) function getSelectionRawBounds()
    - dep: none
    - returns: r1, c1, r2, c2
    - assert: we are in visual/select mode
    - Inclusive/Esclusive Logic: NO

  2) function normalizeBoundsGetDirection(r1, c1, r2, c2)
    - dep: none
    - returns: r1, c1, r2, c2, dir
    - assert: none
    - Inclusive/Esclusive Logic: YES

  3) function getSelectionBoundsAndDirection()
    - dep: 1, 2
    - returns: r1, c1, r2, c2, dir
    - assert: none
    - Inclusive/Esclusive Logic: NO

  4) function getTextFromBounds(r1, c1, r2, c2)
    - dep: none
    - returns: {lines}
    - assert: none
    - Inclusive/Esclusive Logic: NO

  5) function getSelectionText()
    - dep: 3, 4
    - returns: {lines}
    - assert: we are in visual/select mode, no block
    - Inclusive/Esclusive Logic: NO

  6) function rmbCopy()
    - dep: 5
    - returns: none
    - assert: none
    - Inclusive/Esclusive Logic: NO

  --]]

end

return M
