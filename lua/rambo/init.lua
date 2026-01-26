------------------------------------------------------------------------------
--[[

Rambo.nvim

Author: Dario Colombotto
  email: dario.colombotto@outlook.com
  Telegram: https://t.me/colomb8

License: MIT (see LICENSE)

--]]
------------------------------------------------------------------------------

local M = {}

function M.setup(user_opts)

  local config = vim.tbl_deep_extend("force", {
    c_right_mode = 'bow', -- 'bow' or 'eow'
    op_prefix = '', -- '' or '<C-q>' or '<C-g>'
    hl_select_spec = { -- hl_spec or false
      bg = '#732BF5', -- Neon Violet
    },
  },
  user_opts or {})

  local core = require("rambo.core")

  core.setup(config)

end

return M
