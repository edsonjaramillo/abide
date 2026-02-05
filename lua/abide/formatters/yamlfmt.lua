local autocmd = require("abide.autocmd")
local config = require("abide.config")
local utils = require("abide.utils")

---@alias YamlfmtFiletype "yaml"

---@class YamlfmtOptions
---@field enabled? boolean DEFAULT: false
---@field filetypes? YamlfmtFiletype[] DEFAULT: { "yaml" }
---@field disable_filetypes? YamlfmtFiletype[] DEFAULT: {}
---@field additional_args? string[] DEFAULT: {}

---@class YamlfmtModule
---@field default YamlfmtOptions
---@field prerequisites fun(): boolean
---@field setup fun(): nil
---
---@type YamlfmtModule
local M = {}

---@type YamlfmtOptions
M.default = {
	enabled = false,
	filetypes = { "yaml" },
	disable_filetypes = {},
	additional_args = {},
}

---@return boolean
M.prerequisites = function()
	return utils.check_executable("yamlfmt")
end

---@return nil
M.setup = function()
	local opts = config.get_formatter("yamlfmt") or M.default
	local filetypes = utils.filter_filetypes(opts.filetypes, opts.disable_filetypes)

	autocmd.New(filetypes, function(o)
		local stdin = utils.get_buffer_lines(o.buf)
		local argv = { "yamlfmt", "-in" }

		if opts.additional_args and #opts.additional_args > 0 then
			vim.list_extend(argv, opts.additional_args)
		end

		utils.format({ buf = o.buf, argv = argv, stdin = stdin })
	end)
end

return M
