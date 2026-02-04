local autocmd = require("abide.autocmd")
local utils = require("abide.utils")

---@alias StyluaFiletype "lua"

---@class StyluaOptions
---@field enabled? boolean DEFAULT: false
---@field filetypes? StyluaFiletype[] DEFAULT: { "lua" }
---@field disable_filetypes? StyluaFiletype[] DEFAULT: {}
---@field additional_args? string[] DEFAULT: {}

---@class StyluaModule
---@field default StyluaOptions
---@field prerequisites fun(): boolean
---@field setup fun(opts: StyluaOptions): nil
---
---@type StyluaModule
local M = {}

---@type StyluaOptions
M.default = {
	enabled = false,
	filetypes = { "lua" },
	disable_filetypes = {},
	additional_args = {},
}

---@return boolean
M.prerequisites = function()
	return utils.check_executable("stylua")
end

---@param opts StyluaOptions
---@return nil
M.setup = function(opts)
	local filetypes = utils.filter_filetypes(opts.filetypes, opts.disable_filetypes)

	autocmd.New(filetypes, function(o)
		local stdin = utils.get_buffer_lines(o.buf)
		local argv = { "stylua" }

		for _, arg in ipairs(opts.additional_args or {}) do
			table.insert(argv, arg)
		end
		table.insert(argv, "-")

		utils.format({ buf = o.buf, argv = argv, stdin = stdin })
	end)
end

return M
