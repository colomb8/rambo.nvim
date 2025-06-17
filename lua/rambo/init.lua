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
    operations_key = 'C',
  },
  user_opts or {})

  local core = require("rambo.core")

  core.setup(config)

end

return M
