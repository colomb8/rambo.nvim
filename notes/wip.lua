
------------------------------------------------------------------------------
-- Scratch / Notes
------------------------------------------------------------------------------

--[[ test playground

reg
vecchia%strega

ciao di da--talo    
mamma s $ciao ciao 
              
$vecchia vecchia    -- plλto antanoidculo*
-
    - mamma - cia%
-

inclusive - tutto ok
  paste in insert
  paste in select dir 1
  paste in select dir -1

exclusive
  paste in insert
  paste in select dir 1
  paste in select dir -1

Se questa è la forma di democrazia che intendete usare per chiudere le parole
del presidente del Consiglio europeo, vi posso dire che dovreste venire...
come turisti in Italia, ma che qui sembrate turisti della democrazia,
dei turisti della democrazia!

--
ciao cippa-lippa
lipa
lpa

]]--



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

-- FIXME:
-- dopo selezione ed eliminazione, per uscire si deve premere esc 2 volte
-- copiare in select line non fa lampeggiare tutte le linee ma solo una sotto selezione
-- move up/down
  -- refactoring con nuove funzioni
  -- sposta anche il vertical split...misteriosamente
-- unicode support
  -- plλto -- incollare questo va male, ciao vecc€ia -- casino con simbolo Euro
-- undo con ripristino del select
-- final boss: multicursor


€x

--]]

if false then


  vim.keymap.set({'x', 's'}, '<F5>', function()
    print(
    --  vim.inspect(
        getSelectionRawBounds()
    --  )
    )
  end)

  vim.keymap.set({'x', 's'}, '<F6>', function()
    print(
    --  vim.inspect(
        normalizeBoundsGetDirection(getSelectionRawBounds())
    --  )
    )
  end)

  vim.keymap.set('i', '<F9>', function()
    setSelect(1111, 7, 1111, 8, 1)
  end)


--[[

dari(odariodariodariodariodariodariodario
culoc==)uloculoculoculoculoculoculoculoculo



-- prova fatto  fattissimo


--λciao€weeee

ciao

--]]


  local function rmbMotionRight()
    local row = vim.fn.line('.')
    local line = vim.fn.getline('.')
    local line_num_chars = byteToUtf(line)
    local char_index = byteToUtf(line, vim.fn.col('.'))
    --
    local row_target = row
    local col_target
    if char_index < line_num_chars then
      col_target = utfToByte(line, char_index + 1)
    elseif row == vim.fn.line('$') then
      return nil
    else
      row_target = row + 1
      col_target = 1
    end
    setCursor(row_target, col_target)
  end

end

if false then
  -- test
  vim.o.selection = 'inclusive'
  vim.o.selection = 'exclusive'

-- Cleaning
  local keyscomb = {'<', '<S-', '<C-', '<C-S-', '<M-', '<C-M-', '<S-M-', '<C-M-'}
  for _, a in ipairs(keyscomb) do
    -- Clean C, S + dir in Normal, Visual and Select mode
    for _, b in ipairs({'LEFT>', 'RIGHT>', 'UP>', 'DOWN>'}) do
      vim.keymap.set({'n', 'x', 'i', 's'}, a .. b, '<NOP>')
    end
    -- Clean Home, End, PageUp and PageDown in insert mode
    for _, b in ipairs({'HOME>', 'END>', 'PAGEUP>', 'PAGEDOWN>'}) do
      vim.keymap.set({'i'}, a .. b, '<NOP>')
    end
  end
end
