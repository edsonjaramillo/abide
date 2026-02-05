local autocmd = require("abide.autocmd")
local config = require("abide.config")
local utils = require("abide.utils")

---@alias TaploFiletype "toml"

---@class TaploOptions
---@field enabled? boolean DEFAULT: false
---@field filetypes? TaploFiletype[] DEFAULT: { "toml" }
---@field disable_filetypes? TaploFiletype[] DEFAULT: {}
---@field additional_args? string[] DEFAULT: {}

---@class TaploModule
---@field default TaploOptions
---@field prerequisites fun(): boolean
---@field setup fun(): nil
---
---@type TaploModule
local M = {}

---@type TaploOptions
M.default = {
	enabled = false,
	filetypes = { "toml" },
	disable_filetypes = {},
	additional_args = {},
}

---@return boolean
M.prerequisites = function()
	return utils.check_executable("taplo")
end

---@return nil
M.setup = function()
	local opts = config.get_formatter("taplo") or M.default
	local filetypes = utils.filter_filetypes(opts.filetypes, opts.disable_filetypes)

	autocmd.New(filetypes, function(o)
		local stdin = utils.get_buffer_lines(o.buf)
		local argv = { "taplo", "format" }

		if opts.additional_args and #opts.additional_args > 0 then
			vim.list_extend(argv, opts.additional_args)
		end

		if o.file and o.file ~= "" then
			vim.list_extend(argv, { "--stdin-filepath", o.file })
		end
		table.insert(argv, "-")

		utils.format({ buf = o.buf, argv = argv, stdin = stdin })
	end)
end

return M
