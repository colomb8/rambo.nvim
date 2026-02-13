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
    false)
end

local function move_range_rel(r1, r2, shift)
  if shift == 0 then
    return
  end
  local target
  if shift > 0 then
    target = r2 + shift
  else
    target = r1 + shift - 1
  end
  local move_cmd = ("%d,%dmove %d"):format(r1, r2, target)
  vim.cmd(move_cmd)
end

local function deleteLines(row1, row2)
  vim.api.nvim_buf_set_lines(
      0, -- buffer, 0 for current
      row1 - 1, -- start line, 0-based, inclusive
      row2, -- end line, 0-based, exclusive
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

local function insertLines(row, lines)
  vim.api.nvim_buf_set_lines(
      0, -- buffer, 0 for current
      row - 1, -- start line, 0-based, inclusive
      row - 1, -- end line, 0-based, exclusive
      true, -- strict_indexing
      lines -- replacement
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

local rambo_register_lines = nil

local insert_special = false

local opt_selection_original_value = vim.o.selection

local M = {}

------------------------------------------------------------------------------
-- Rambo.nvim Autocommands
------------------------------------------------------------------------------

vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = "*:ni*", -- "*:ni[IRV]"
  callback = function()
    vim.o.selection = 'exclusive'
    insert_special = true
  end,
})

-- update rambo internal register on yank
vim.api.nvim_create_autocmd("TextYankPost", { -- yank or delete
  -- from documentation: "TextYankPost Just after a yank or deleting command,
  -- but not if the black hole register quote_ is used nor for setreg()"
  callback = function()
    local mode = vim.fn.mode(1)
    -- if mode:match("[nvV\22]*") then -- normal or any visual
    if mode ~= 'niI' then -- exclude Select-Insert
      rambo_register_lines = splitStr(vim.fn.getreg('"'), '\n')
    end
  end,
})

-- restore " and + registers if Select while typing
vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = "*[sS\19]:niI",
  callback = function()
    local tmp = table.concat(rambo_register_lines or {}, '\n')
    vim.fn.setreg('*', tmp, 'c')
    vim.fn.setreg('"', tmp, 'c')
    vim.fn.setreg('+', tmp, 'c')
    vim.fn.setreg('0', tmp, 'c')
  end,
})

vim.api.nvim_create_autocmd("InsertEnter", {
  callback = function()
    vim.o.selection = opt_selection_original_value
    insert_special = false
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

local function getNextBeginningOfWord(line)
  -- inclusive
  -- vim.regex uses vim.o.iskeyword !
  local r = vim.regex(""
    .. "\\("
      -- kw or blank            , punct/symbol
    .. "[[:keyword:][:blank:]]" .. "[^[:keyword:][:blank:]]"
    .. "\\)"
    .. "\\|" -- or
    .. "\\("
      -- blank or punct/symbol, kw
       .. "[^[:keyword:]]" .. "[[:keyword:]]"
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
  local _, to = r:match_str(" " .. line) -- <--
  return to and to - 1
end

local rmbMotionCLeft = {
  dir = -1,
  move = function()
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
}

local rmbMotionCRight = {
  dir = 1,
  move = function(c_right_mode)
    local col = vim.fn.col('.')
    local row = vim.fn.line('.')
    local line = vim.fn.getline('.')
    local line_len = line:len()
    --
    local line_l = line:sub(0, col - 1)
    local line_r = line:sub(col)
    local col_cright
    if c_right_mode == 'eow' then
      col_cright = getFirstEndOfWord(line_r)
    elseif c_right_mode == 'bow' then
      col_cright = getNextBeginningOfWord(line_r)
    else
      error(tostring(c_right_mode))
    end
    --
    local row_target = row
    local col_target
    if col < line_len then
      if not col_cright then
        col_target = line_len + 1
      else
        col_target = line_l:len() + col_cright + 1
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
}

local rmbMotionHome = {
  dir = -1,
  move = function()
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
}

local rmbMotionEnd = {
  dir = 1,
  move = function()
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
}

local rmbMotionLeft = {
  dir = -1,
  move = function()
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
}

local rmbMotionRight = {
  dir = 1,
  move = function()
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
}

local rmbMotionPageUp = {
  dir = -1,
  move = function()
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
}

local rmbMotionPageDown = {
  dir = 1,
  move = function()
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
}

local rmbMotionCUp = {
  dir = -1,
  move = function()
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
}

local rmbMotionCDown = {
  dir = 1,
  move = function()
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
}

local rmbMotionUp = {
  dir = -1,
  move = function()
    local r = vim.fn.line('.')
    if r == 1 then return nil end
    local c = vim.fn.col('.')
    local row_target = r - 1
    local line_target_len = vim.fn.getline(row_target):len()
    local col_target = math.min(c, line_target_len + 1)
    setCursor(row_target, col_target)
  end
}

local rmbMotionDown = {
  dir = 1,
  move = function()
    local r = vim.fn.line('.')
    if r >= vim.fn.line('$') then return nil end
    local c = vim.fn.col('.')
    local row_target = r + 1
    local line_target_len = vim.fn.getline(row_target):len()
    local col_target = math.min(c, line_target_len + 1)
    setCursor(row_target, col_target)
  end
}

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

local rmbMotionCHome = {
  dir = -1,
  move = function()
    local row_target = 1
    local col_target = 1
    setCursor(row_target, col_target)
  end
}

local rmbMotionCEnd = {
  dir = 1,
  move = function()
    local row_last = vim.fn.line('$')
    local col_lastrow = vim.fn.getline(row_last):len() + 1
    local row_target = row_last
    local col_target = col_lastrow
    setCursor(row_target, col_target)
  end
}

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
  sendKeys('<C-o>V<C-g>', 'nx')
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
  sendKeys('<C-o>V<C-g>', 'nx')
  setCursor(v_row_end + 1, v_col_end)
end

local function rmbCopy(opts)
  opts = opts or {}
  local r1, c1, r2, c2, _ = getSelectionBoundsAndDirection()
  if opts['is_lines'] then
    c1 = 1
    c2 = vim.fn.getline(r2):len()
  end
  rambo_register_lines =  getTextFromBounds(r1, c1, r2, c2)
  local tmp = table.concat(rambo_register_lines, '\n')
  vim.fn.setreg('*', tmp, 'c')
  vim.fn.setreg('"', tmp, 'c')
  vim.fn.setreg('+', tmp, 'c')
  vim.fn.setreg('0', tmp, 'c')
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

local function rmbCut(opts)
  opts = opts or {}
  local r1, c1, r2, c2, _ = getSelectionBoundsAndDirection()
  if r1 == r2 and c1 == c2 + 1 then return nil end
  if opts['is_lines'] then
    c1 = 1
    c2 = vim.fn.getline(r2):len()
  end
  rambo_register_lines = getTextFromBounds(r1, c1, r2, c2)
  local tmp = table.concat(rambo_register_lines, '\n')
  vim.fn.setreg('*', tmp, 'c')
  vim.fn.setreg('"', tmp, 'c')
  vim.fn.setreg('+', tmp, 'c')
  vim.fn.setreg('0', tmp, 'c')
  sendKeys('<ESC>', 'n')
  deleteText(r1, c1, r2, c2)
end

local function rmbPaste(opts)
  rambo_register_lines = nil
    or rambo_register_lines
    or splitStr(vim.fn.getreg('*'), '\n')
    or splitStr(vim.fn.getreg('"'), '\n')
    or splitStr(vim.fn.getreg('+'), '\n')
    or splitStr(vim.fn.getreg('0'), '\n')
  opts = opts or {}
  if opts['submode'] == 'insert' then
    local row = vim.fn.line('.')
    local col = vim.fn.col('.')
    insertText(row, col, rambo_register_lines)
    advanceCursorFromLines(rambo_register_lines)
  elseif opts['submode'] == 'select' then
    local r1, c1, r2, c2, _ = getSelectionBoundsAndDirection()
    sendKeys('<ESC>', 'n')
    deleteText(r1, c1, r2, c2)
    insertText(r1, c1, rambo_register_lines)
  else
    error(tostring(opts['submode']))
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
    error(tostring(dir))
  end
end

local function save()
  vim.cmd(":w")
end

local function rmbMoveSel(rmbMotion, opts)
  opts = opts or {}
  local r1, c1, r2, c2, dir = getSelectionBoundsAndDirection()
  if opts['submode'] == 's' then
    -- move Select selection
    assert(r1 == r2)
    local r = r1
    if c1 == c2 + 1 then return nil end
    local text = getTextFromBounds(r, c1, r, c2)
    sendKeys('<ESC>', 'n')
    deleteText(r, c1, r, c2)
    rmbMotion.move(opts['c_right_mode'])
    local row_target = vim.fn.line('.')
    local col_target = vim.fn.col('.')
    insertText(row_target, col_target, text)
    setSelect(row_target, col_target, row_target, col_target + (c2 - c1), dir)
  elseif opts['submode'] == 'S' then
    -- move Select-Line selection
    local _c1 = 1
    local _c2 = vim.fn.getline(r2):len()
    local text = getTextFromBounds(r1, _c1, r2, _c2)
    sendKeys('<ESC>', 'n')
    if rmbMotion.dir == -1 then
      setCursor(r1, 1)
    elseif rmbMotion.dir == 1 then
      setCursor(r2, 1)
    else
      error(tostring(rmbMotion.dir))
    end
    rmbMotion.move(opts['c_right_mode'])
    local row_motion = vim.fn.line('.')
    local shift
    if rmbMotion.dir == -1 then
      shift = row_motion - r1
    elseif rmbMotion.dir == 1 then
      shift = row_motion - r2
    else
      error(tostring(rmbMotion.dir))
    end
    move_range_rel(r1, r2, shift)
    setSelect(
      r1 + shift,
      c1,
      r2 + shift,
      c2,
      dir
    )
    sendKeys('<C-g>V<C-g>', 'n')
  else
    error(tostring(opts['submode']))
  end
end

-- if single line and not Select-Line: move by 1 char
-- if multi line or Select-Line: indent/dedent
local function rmbMoveSelLeft(opts) rmbMoveSel(rmbMotionLeft, opts) end
local function rmbMoveSelRight(opts) rmbMoveSel(rmbMotionRight, opts) end

-- only single line
local function rmbMoveSelCLeft(opts) rmbMoveSel(rmbMotionCLeft, opts) end
local function rmbMoveSelCRight(opts) rmbMoveSel(rmbMotionCRight, opts) end
local function rmbMoveSelHome(opts) rmbMoveSel(rmbMotionHome, opts) end
local function rmbMoveSelEnd(opts) rmbMoveSel(rmbMotionEnd, opts) end

-- if Select:
--   if multiline: switch to S-Line
--   if no multiline: move text
-- if Select-Line: move Lines
local function rmbMoveSelUp(opts) rmbMoveSel(rmbMotionUp, opts) end
local function rmbMoveSelCUp(opts) rmbMoveSel(rmbMotionCUp, opts) end
local function rmbMoveSelPageUp(opts) rmbMoveSel(rmbMotionPageUp, opts) end
local function rmbMoveSelCHome(opts) rmbMoveSel(rmbMotionCHome, opts) end
local function rmbMoveSelDown(opts) rmbMoveSel(rmbMotionDown, opts) end
local function rmbMoveSelCDown(opts) rmbMoveSel(rmbMotionCDown, opts) end
local function rmbMoveSelPageDown(opts) rmbMoveSel(rmbMotionPageDown, opts) end
local function rmbMoveSelCEnd(opts) rmbMoveSel(rmbMotionCEnd, opts) end

-- TODO
-- aggiornare readme
---- no licence
-- pushare e propagare

------------------------------------------------------------------------------
-- Rambo.nvim Keybindings
------------------------------------------------------------------------------

function M.setup(cfg)

  -- Cfg validation ------------------------------------------------------------

  for k, _ in pairs(cfg) do
    assert(vim.list_contains({
      'c_right_mode',
      'op_prefix',
      'hl_select_spec',
    }, k), 'unknown configuration name: ' .. k)
  end

  assert(
    vim.list_contains({'eow', 'bow'}, cfg.c_right_mode),
    '`c_right_mode` supports only "eow" or "bow"; received: '
    .. tostring(cfg.c_right_mode))

  assert(
    vim.list_contains({'', '<C-q>', '<C-g>'}, cfg.op_prefix),
    '`op_prefix` supports only "", "<C-q>", "<C-g>"; received: '
    .. tostring(cfg.op_prefix))

  -- Functions cfg dependant  ----------------------------------------------------------

  local rmbMotionCRight_cfg = {
    dir = rmbMotionCRight.dir,
    move = function()
      rmbMotionCRight.move(cfg.c_right_mode)
    end
  }

  local function rmbMoveSelCRight_cfg(opts)
    opts = vim.tbl_extend(
      "force",
      { c_right_mode = cfg.c_right_mode }, -- default
      opts or {}
    )
    return rmbMoveSelCRight(opts)
  end

  local function getOpMappingLhs(key)
    assert(key:len() == 1)
    if cfg.op_prefix == '' then
      return '<C-' .. key .. '>'
    else
      return cfg.op_prefix .. key
    end
  end

  -- Setup color of Select mode -----------------------------------------------------

  if cfg.hl_select_spec then
    local hl_group = vim.api.nvim_create_augroup("RamboSelectHL", { clear = true })

    local function get_visual_hl()
      return vim.api.nvim_get_hl(0, { name = "Visual", link = true })
    end

    local function restore_visual(h)
      if not h then return end
      if h.link and h.link ~= "" then
        vim.api.nvim_set_hl(0, "Visual", { link = h.link })
      else
        vim.api.nvim_set_hl(0, "Visual", h)
      end
    end

    local hl_visual_orig
    local in_select = false

    vim.api.nvim_create_autocmd("ModeChanged", {
      group = hl_group,
      pattern = "*:[sS\19]*",
      callback = function()
        if in_select then return end
        in_select = true
        hl_visual_orig = get_visual_hl()
        vim.api.nvim_set_hl(0, "Visual", cfg.hl_select_spec)
      end,
    })

    vim.api.nvim_create_autocmd("ModeChanged", {
      group = hl_group,
      pattern = "[sS\19]*:*",
      callback = function()
        if not in_select then return end
        in_select = false
        restore_visual(hl_visual_orig)
        hl_visual_orig = nil
      end,
    })

    vim.api.nvim_create_autocmd("ColorScheme", {
      group = hl_group,
      callback = function()
        if not in_select then return end
        hl_visual_orig = get_visual_hl()
        vim.api.nvim_set_hl(0, "Visual", cfg.hl_select_spec)
      end,
    })
  end

  -- Fix inserting tab in select mode -----------------------------------------------

  vim.keymap.set('s', '<TAB>', '<C-g>c<C-v><TAB>')

  -- Go to the other end of selection -----------------------------------------------

  vim.keymap.set('s', getOpMappingLhs('o'), '<C-o>o',
    { desc = 'Go to the other end of selection' })

  -- Scroll window 1 line

  vim.keymap.set({'i', 's'}, '<M-S-UP>', '<C-o><C-y>')
  vim.keymap.set({'i', 's'}, '<M-S-DOWN>', '<C-o><C-e>')

  -- Move cursor in Insert ----------------------------------------------------------

  for k, f in pairs({
    ['<LEFT>'] = rmbMotionLeft,
    ['<RIGHT>'] = rmbMotionRight,
    ['<UP>'] = rmbMotionUp,
    ['<DOWN>'] = rmbMotionDown,
    ['<C-LEFT>'] = rmbMotionCLeft,
    ['<C-RIGHT>'] = rmbMotionCRight_cfg,
    ['<C-UP>'] = rmbMotionCUp,
    ['<C-DOWN>'] = rmbMotionCDown,
    ['<HOME>'] = rmbMotionHome,
    ['<KHOME>'] = rmbMotionHome,
    ['<END>'] = rmbMotionEnd,
    ['<KEND>'] = rmbMotionEnd,
    ['<C-HOME>'] = rmbMotionCHome,
    ['<C-KHOME>'] = rmbMotionCHome,
    ['<C-END>'] = rmbMotionCEnd,
    ['<C-KEND>'] = rmbMotionCEnd,
    ['<PAGEUP>'] = rmbMotionPageUp,
    ['<KPAGEUP>'] = rmbMotionPageUp,
    ['<PAGEDOWN>'] = rmbMotionPageDown,
    ['<KPAGEDOWN>'] = rmbMotionPageDown,
    }) do
    vim.keymap.set('i', k, function()
      if vim.fn.complete_info({ "pum_visible" }).pum_visible == 1 then
        sendKeys('<C-e>', 'n')
      else
        f.move()
      end
    end)
  end

  -- Start Select-in-Insert mode -----------------------------------------------

  for k, f in pairs({
    ['<S-LEFT>'] = rmbMotionLeft,
    ['<S-UP>'] = rmbMotionUp,
    ['<C-S-LEFT>'] = rmbMotionCLeft,
    ['<C-S-UP>'] = rmbMotionCUp,
    -- ['<S-HOME>'] = rmbMotionHome,
    -- ['<S-KHOME>'] = rmbMotionHome,
    ['<C-S-HOME>'] = rmbMotionCHome,
    ['<C-S-KHOME>'] = rmbMotionCHome,
    ['<S-PAGEUP>'] = rmbMotionPageUp,
    ['<S-KPAGEUP>'] = rmbMotionPageUp,
    }) do
    --
    vim.keymap.set('i', k, function()
      if vim.fn.col('.') == 1 and vim.fn.line('.') == 1 -- BOF
        then return end
      sendKeys('<C-\\><C-o>v<C-g>', 'n')
      vim.schedule(f.move)
    end)
  end

  vim.keymap.set('i', '<S-HOME>', function()
    if vim.fn.col('.') == 1 then return end
    sendKeys('<C-\\><C-o>v<C-g>', 'n')
    vim.schedule(rmbMotionHome.move)
  end)

  vim.keymap.set('i', '<S-KHOME>', function()
    if vim.fn.col('.') == 1 then return end
    sendKeys('<C-\\><C-o>v<C-g>', 'n')
    vim.schedule(rmbMotionHome.move)
  end)

  for k, f in pairs({
    ['<S-RIGHT>'] = rmbMotionRight,
    ['<S-DOWN>'] = rmbMotionDown,
    ['<C-S-RIGHT>'] = rmbMotionCRight_cfg,
    ['<C-S-DOWN>'] = rmbMotionCDown,
    -- ['<S-END>'] = rmbMotionEnd,
    -- ['<S-KEND>'] = rmbMotionEnd,
    ['<C-S-END>'] = rmbMotionCEnd,
    ['<C-S-KEND>'] = rmbMotionCEnd,
    ['<S-PAGEDOWN>'] = rmbMotionPageDown,
    ['<S-KPAGEDOWN>'] = rmbMotionPageDown,
    }) do
    --
    vim.keymap.set('i', k, function()
      if vim.fn.col('.') == vim.fn.col('$')
        and vim.fn.line('.') == vim.fn.line('$') -- EOF
      then return end
      sendKeys('<C-\\><C-o>v<C-g>', 'n')
      vim.schedule(f.move)
    end)
  end

  vim.keymap.set('i', '<S-END>', function()
    if vim.fn.col('.') == vim.fn.getline('.'):len() + 1 then return end
    sendKeys('<C-\\><C-o>v<C-g>', 'n')
    vim.schedule(rmbMotionEnd.move)
  end)

  vim.keymap.set('i', '<S-KEND>', function()
    if vim.fn.col('.') == vim.fn.getline('.'):len() + 1 then return end
    sendKeys('<C-\\><C-o>v<C-g>', 'n')
    vim.schedule(rmbMotionEnd.move)
  end)

  -- Changing selection --------------------------------------------------------

  for k, f in pairs({
    ['<S-LEFT>'] = rmbMotionLeft,
    ['<S-RIGHT>'] = rmbMotionRight,
    ['<S-UP>'] = rmbMotionUp,
    ['<S-DOWN>'] = rmbMotionDown,
    ['<C-S-LEFT>'] = rmbMotionCLeft,
    ['<C-S-RIGHT>'] = rmbMotionCRight_cfg,
    ['<C-S-UP>'] = rmbMotionCUp,
    ['<C-S-DOWN>'] = rmbMotionCDown,
    ['<S-HOME>'] = rmbMotionHome,
    ['<S-KHOME>'] = rmbMotionHome,
    ['<S-END>'] = rmbMotionEnd,
    ['<S-KEND>'] = rmbMotionEnd,
    ['<C-S-HOME>'] = rmbMotionCHome,
    ['<C-S-KHOME>'] = rmbMotionCHome,
    ['<C-S-END>'] = rmbMotionCEnd,
    ['<C-S-KEND>'] = rmbMotionCEnd,
    ['<S-PAGEUP>'] = rmbMotionPageUp,
    ['<S-KPAGEUP>'] = rmbMotionPageUp,
    ['<S-PAGEDOWN>'] = rmbMotionPageDown,
    ['<S-KPAGEDOWN>'] = rmbMotionPageDown,
    }) do
    vim.keymap.set('s', k, f.move)
  end

  -- Stop Select-in-Insert mode ------------------------------------------------

  vim.keymap.set('s', '<LEFT>', rmbLeaveSelectLeft)
  vim.keymap.set('s', '<RIGHT>', rmbLeaveSelectRight)
  for k, f in pairs({
    ['<UP>'] = rmbMotionUp,
    ['<DOWN>'] = rmbMotionDown,
    ['<C-LEFT>'] = rmbMotionCLeft,
    ['<C-RIGHT>'] = rmbMotionCRight_cfg,
    ['<C-UP>'] = rmbMotionCUp,
    ['<C-DOWN>'] = rmbMotionCDown,
    ['<HOME>'] = rmbMotionHome,
    ['<KHOME>'] = rmbMotionHome,
    ['<END>'] = rmbMotionEnd,
    ['<KEND>'] = rmbMotionEnd,
    ['<C-HOME>'] = rmbMotionCHome,
    ['<C-KHOME>'] = rmbMotionCHome,
    ['<C-END>'] = rmbMotionCEnd,
    ['<C-KEND>'] = rmbMotionCEnd,
    ['<PAGEUP>'] = rmbMotionPageUp,
    ['<KPAGEUP>'] = rmbMotionPageUp,
    ['<PAGEDOWN>'] = rmbMotionPageDown,
    ['<KPAGEDOWN>'] = rmbMotionPageDown,
    }) do
    vim.keymap.set('s', k, function()
      sendKeys('<ESC>', 'n')
      vim.schedule(f.move)
    end)
  end

  -- Move Lines ------------------------------------------------------

  -- When try to do a line op in insert mode,
  -- at first switch to Select-Line
  for _, k in ipairs({
    '<M-UP>',
    '<M-DOWN>',
    '<M-LEFT>',
    '<M-RIGHT>',
    '<M-HOME>',
    '<M-KHOME>',
    '<M-END>',
    '<M-KEND>',
    '<M-PAGEUP>',
    '<M-KPAGEUP>',
    '<M-PAGEDOWN>',
    '<M-KPAGEDOWN>',
    '<C-M-UP>',
    '<C-M-DOWN>',
    '<C-M-LEFT>',
    '<C-M-RIGHT>',
    '<C-M-HOME>',
    '<C-M-KHOME>',
    '<C-M-END>',
    '<C-M-KEND>',
    '<C-M-PAGEUP>',
    '<C-M-KPAGEUP>',
    '<C-M-PAGEDOWN>',
    '<C-M-KPAGEDOWN>',
  }) do
    vim.keymap.set('i', k, '<C-\\><C-o>V<C-g>')
  end

  -- move selection one col backward or forward, or indent / dedent

  vim.keymap.set('s', '<M-LEFT>', function()
    local mode = vim.fn.mode()
    if mode:match('[s]') then -- Select
      local r1, _, r2, _ = getSelectionRawBounds()
      if r1 == r2 then -- same line
        rmbMoveSelLeft({ submode = 's' })
      else -- different lines
        sendKeys('<C-g>V<C-g>', 'n') -- at first switch to Select-Line
      end
    elseif mode:match('[S]') then -- Select-Line
      sendKeys('<C-g><gv<C-g>', 'n')
    elseif mode:match('[\19]') then -- Select-block (^S)
      return nil
    else
      error(tostring(mode))
    end
  end)
  vim.keymap.set('s', '<M-RIGHT>', function()
    local mode = vim.fn.mode()
    if mode:match('[s]') then -- Select
      local r1, _, r2, _ = getSelectionRawBounds()
      if r1 == r2 then -- same line
        rmbMoveSelRight({ submode = 's' })
      else -- different lines
        sendKeys('<C-g>V<C-g>', 'n') -- at first switch to Select-Line
      end
    elseif mode:match('[S]') then -- Select-Line
      sendKeys('<C-g>>gv<C-g>', 'n')
    elseif mode:match('[\19]') then -- Select-block (^S)
      return nil
    else
      error(tostring(mode))
    end
  end)

  if false then
    vim.keymap.set('s', '<S-TAB>', function()
      local mode = vim.fn.mode()
      if mode:match('[s]') then -- Select
        local r1, _, r2, _ = getSelectionRawBounds()
        if r1 == r2 then -- same line
          sendKeys('<C-g>V<C-g>', 'n') -- at first switch to Select-Line
        else -- different lines
          sendKeys('<C-g>V<C-g>', 'n') -- at first switch to Select-Line
        end
      elseif mode:match('[S]') then -- Select-Line
        sendKeys('<C-g><gv<C-g>', 'n')
      elseif mode:match('[\19]') then -- Select-block (^S)
        return nil
      else
        error(tostring(mode))
      end
    end)
    vim.keymap.set('s', '<TAB>', function()
      local mode = vim.fn.mode()
      if mode:match('[s]') then -- Select
        local r1, _, r2, _ = getSelectionRawBounds()
        if r1 == r2 then -- same line
          sendKeys('<C-g>V<C-g>', 'n') -- at first switch to Select-Line
        else -- different lines
          sendKeys('<C-g>V<C-g>', 'n') -- at first switch to Select-Line
        end
      elseif mode:match('[S]') then -- Select-Line
        sendKeys('<C-g>>gv<C-g>', 'n')
      elseif mode:match('[\19]') then -- Select-block (^S)
        return nil
      else
        error(tostring(mode))
      end
    end)
  end

  for k, f in pairs({
    ['<C-M-LEFT>'] = rmbMoveSelCLeft, -- move selection one word backward
    ['<C-M-RIGHT>'] = rmbMoveSelCRight_cfg, -- move selection one word forward
    ['<M-HOME>'] = rmbMoveSelHome, -- move selection to BOL
    ['<M-KHOME>'] = rmbMoveSelHome, -- move selection to BOL
    ['<M-END>'] = rmbMoveSelEnd, -- move selection to EOL
    ['<M-KEND>'] = rmbMoveSelEnd, -- move selection to EOL
    }) do
    vim.keymap.set('s', k, function()
      local mode = vim.fn.mode()
      if mode:match('[s]') then -- Select
        local r1, _, r2, _ = getSelectionRawBounds()
        if r1 == r2 then -- same line
          f({ submode = 's' })
        else -- different lines
          return nil
        end
      elseif mode:match('[S]') then -- Select-Line
        return nil
      elseif mode:match('[\19]') then -- Select-block (^S)
        return nil
      else
        error(tostring(mode))
      end
    end)
  end

  for k, f in pairs({
    ['<M-UP>'] = rmbMoveSelUp, -- move sel up
    ['<M-DOWN>'] = rmbMoveSelDown, -- move sel down
    ['<C-M-UP>'] = rmbMoveSelCUp, -- move sel to prev par
    ['<C-M-DOWN>'] = rmbMoveSelCDown, -- move sel to next par
    ['<M-PAGEUP>'] = rmbMoveSelPageUp, -- move sel to prev page
    ['<M-KPAGEUP>'] = rmbMoveSelPageUp, -- move sel to prev page
    ['<M-PAGEDOWN>'] = rmbMoveSelPageDown, -- move sel to next page
    ['<M-KPAGEDOWN>'] = rmbMoveSelPageDown, -- move sel to next page
    ['<C-M-HOME>'] = rmbMoveSelCHome, -- move sel to BOF
    ['<C-M-KHOME>'] = rmbMoveSelCHome, -- move sel to BOF
    ['<C-M-END>'] = rmbMoveSelCEnd, -- move sel to EOF
    ['<C-M-KEND>'] = rmbMoveSelCEnd, -- move sel to EOF
    }) do
    vim.keymap.set('s', k, function()
      local mode = vim.fn.mode()
      if mode:match('[s]') then -- Select
        local r1, c1, r2, c2, _ = getSelectionBoundsAndDirection()
        local sel_multiline = r1 ~= r2
        -- local sel_whole_lines = c1 == 1 and c2 == vim.fn.getline(r2):len()
        if
          sel_multiline
          -- or sel_whole_lines
          then
          sendKeys('<C-g>V<C-g>', 'n') -- at first switch to Select-Line
        else
           -- move text
           f({ submode = 's' })
        end
      elseif mode:match('[S]') then -- Select-Line
        -- move lines
        f({ submode = 'S' })
      elseif mode:match('[\19]') then -- Select-block (^S)
        return nil
      else
        error(tostring(mode))
      end
    end)
  end

  -- Operations ----------------------------------------------------------------

  -- Select mode: Copy to { ", rambo_register_lines }
  vim.keymap.set('s', getOpMappingLhs('c'), function()
    local mode = vim.fn.mode()
    if mode:match('[s]') then -- Select
      rmbCopy({ is_lines = false })
    elseif mode:match('[S]') then -- Select-Line
      rmbCopy({ is_lines = true })
    elseif mode:match('[\19]') then -- Select-block (^S)
      return nil
    else
      error(tostring(mode))
    end
  end,
  { desc = 'Copy' })

  -- Select mode: Cut to { ", rambo_register_lines }
  vim.keymap.set('s', getOpMappingLhs('x'), function()
    local mode = vim.fn.mode()
    if mode:match('[s]') then -- Select
      rmbCut({ is_lines = false })
    elseif mode:match('[S]') then -- Select-Line
      rmbCut({ is_lines = true })
    elseif mode:match('[\19]') then -- Select-block (^S)
      return nil
    else
      error(tostring(mode))
    end
  end,
  { desc = 'Cut' })

  -- Select mode: Paste from rambo_register_lines
  vim.keymap.set('s', getOpMappingLhs('v'), function()
    rmbPaste({ submode = 'select' }) end,
    { desc = 'Paste' })

  -- -- Insert mode: Copy -> No Op.
  -- vim.keymap.set('i', getOpMappingLhs('c'), '<NOP>',
  --   { desc = '' })

  -- -- Insert mode: Cut -> No Op.
  -- vim.keymap.set('i', '<C-x>', '<NOP>',
  --   { desc = '' })

  -- Insert mode: Paste from rambo_register_lines
  vim.keymap.set('i', getOpMappingLhs('v'), function()
    rmbPaste({ submode = 'insert' }) end,
    { desc = 'Paste' })

  -- Save in Insert/Select
  vim.keymap.set('i', getOpMappingLhs('s'), save,
    { desc = 'Save' })
  vim.keymap.set('s', getOpMappingLhs('s'), save,
    { desc = 'Save' })

  -- Undo in Insert/Select
  vim.keymap.set('i', getOpMappingLhs('z'), '<C-o>u',
    { desc = 'Undo' })
  vim.keymap.set('s', getOpMappingLhs('z'), '<ESC>ui',
    { desc = 'Undo' })

  -- Redo in Insert/Select
  -- commented because C-Z doesn't work
  -- vim.keymap.set('i', '<C-Z>', '<C-o><C-r>')
  -- vim.keymap.set('s', '<C-Z>', '<ESC><C-r>i')
  vim.keymap.set('i', getOpMappingLhs('y'), '<C-o><C-r>',
    { desc = 'Redo' })
  vim.keymap.set('s', getOpMappingLhs('y'), '<ESC><C-r>i',
    { desc = 'Redo' })

  -- Select all
  vim.keymap.set('i', getOpMappingLhs('a'), function()
      sendKeys('<ESC>gg0i<C-\\><C-o>vG$<C-g>', 'n')
    end,
    { desc = 'Select All' })

  vim.keymap.set('s', getOpMappingLhs('a'), function()
    sendKeys('<ESC><ESC>gg0i<C-\\><C-o>vG$<C-g>', 'n')
    end,
    { desc = 'Select All' })

  -- Search in Insert mode
  vim.keymap.set('i', getOpMappingLhs('f'), '<C-o>/',
    { desc = 'Search' })

  -- F3 / F4 and S-F3 for jump between search results
  -- vim.keymap.set({'i', 's'}, '<F3>',  '<C-o>n')
  -- vim.keymap.set({'i', 's'}, '<F15>', '<C-o>N') -- = S-<F3>
  -- vim.keymap.set({'i', 's'}, '<F2>', '<C-o>N') -- = S-<F3>

  -- Insert: search forward
  vim.keymap.set('i', '<F3>', function()
    sendKeys('<C-o>gn<C-g>', 'n')
  end)

  -- Insert: search backward
  vim.keymap.set('i', '<F2>', function()
    sendKeys('<C-o>gN<C-g>', 'n')
  end)

  -- Select: search forward
  vim.keymap.set('s', '<F3>', function()
    sendKeys('<ESC><C-\\><C-o>gn<C-g>', 'nx')
  end)
  -- vim.keymap.set('n', '<F3>', function()
  --   sendKeys('i<C-\\><C-o>gn<C-g>', 'nx')
  -- end)

  -- Select: search backward
  vim.keymap.set('s', '<F2>', function()
    rmbMotionLeft.move()
    sendKeys('<ESC><C-\\><C-o>gN<C-g>', 'nx')
  end)
  -- vim.keymap.set('n', '<F2>', function()
  --   rmbMotionLeft.move()
  --   sendKeys('i<C-\\><C-o>gN<C-g>', 'nx')
  -- end)

  -- Disable hlsearch
  vim.keymap.set({'n', 'i', 's'}, '<F4>',  '<cmd>:nohl<CR>')

  -- Search text under Selection
  vim.keymap.set('s', getOpMappingLhs('f'), function()
      sendKeys('<C-g>', 'n')
      vim.schedule(function() sendKeys('*', 'n') end)
    end,
    { desc = 'Search Selection' })

  -- Del/BS in Select (blackhole reg)
  vim.keymap.set('s', '<DEL>', '<C-g>"_d')
  vim.keymap.set('s', '<BS>', '<C-g>"_d')

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

  -- S-SPACE not always captured
  -- use M-something instead
  -- -- Toggle Select <-> Select Line
  -- vim.keymap.set('s', '<S-SPACE>', function()
  --   local mode = vim.fn.mode()
  --   if insert_special then
  --     if mode:match('[S]') then -- Select-Line
  --       sendKeys('<C-g>v<C-g>', 'n')
  --     else -- select or select block
  --       sendKeys('<C-g>V<C-g>', 'n')
  --     end
  --   else
  --     sendKeys('<C-l>', 'n')
  --   end
  -- end)

  -- Wrapping utilities: (), [], {}, "", '', <>
  for _, wrap_spec in pairs({
    {'(', '( ', ' )'}, {')', '(', ')'},
    {'[', '[ ', ' ]'}, {']', '[', ']'},
    {'{', '{ ', ' }'}, {'}', '{', '}'},
    {'<', '< ', ' >'}, {'>', '<', '>'},
    {'"', '"', '"'},
    {"'", "'", "'"},
    {"`", "`", "`"},
    {"*", "*", "*"},
    -- commented because user can repeat it manually
    -- {'"""', '"""', '"""'},
    -- {"```", "```", "```"},
    }) do
    local key, op, cl = wrap_spec[1], wrap_spec[2], wrap_spec[3]
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

    -- test ----------------------------------------------------

    local function byteToUtf(line, col)
      local utf_32_index, utf_16_index = vim.str_utfindex(line, col and col - 1)
      return utf_32_index
    end

    local function utfToByte(line, index)
      return vim.str_byteindex(line, index) + 1
    end

    local function visualCoversWholeLines(dir)
      local _, v_row_start, v_col_start, _ = unpack(vim.fn.getpos("v"))
      local _, v_row_end, v_col_end, _ = unpack(vim.fn.getpos("."))
      --
      local v_line_start = vim.fn.getline(v_row_start)
      local v_line_end = vim.fn.getline(v_row_end)
      --
      local v_starts_at_bol = (v_col_start == 1) or (#v_line_start == 0)
      local v_ends_at_eol =
        (v_col_end >= #v_line_end) or (#v_line_end == 0)
      local v_starts_at_eol =
        (v_col_start >= #v_line_start) or (#v_line_start == 0)
      local v_ends_at_bol = (v_col_end == 1) or (#v_line_end == 0)
      -- local dir = VisualDirection()
      if dir ==  1 then
        return (v_starts_at_bol and v_ends_at_eol)
      end
      if dir == -1 then
        return (v_starts_at_eol and v_ends_at_bol)
      end
    end

    vim.keymap.set('x', '=', function()
      local vmode = vim.fn.mode():sub(1, 1)
      assert(vmode == 'v' or vmode == 'V', 'vmode: ' .. vmode)
      local _, _, _, _, dir = getSelectionBoundsAndDirection()
      -- local dir = getVisualOrSelectDirection()
      assert(dir == 1 or dir == -1, 'dir: ' .. dir)
      --
      local ypexpr = '"zy"zP'
      --
      local res = ''
      if vmode == 'V' then
        --
        res = res .. ypexpr
        if dir == 1 then
          res = res .. "'[V']"
        elseif dir == -1 then
          res = res .. "']V'["
        end
        --
      elseif vmode == 'v' then
        local cwl = visualCoversWholeLines(dir)
        if cwl then
          res = res .. 'V'
          --
          res = res .. ypexpr
          if dir == 1 then
            res = res .. "'[V']"
          elseif dir == -1 then
            res = res .. "']V'["
          end
          --
        else
          res = res .. ypexpr
          if dir == 1 then
            res = res .. "`<v`>"
          elseif dir == -1 then
            res = res .. "`>v`<"
          end
        end
      end
      return res
    end, { expr = true, desc = 'Duplicate selection' })

    Modes:

    ['v'] = true, -- visual
    ['V'] = true, -- visual line
    ['\22'] = true, -- visual block (^V)
    ['s'] = true, -- select
    ['S'] = true, -- select line
    ['\19'] = true, -- select block (^S)

  Functions:

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
