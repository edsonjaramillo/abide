local autocmd = require("abide.autocmd")
local buffer_utils = require("abide.utils.buffer")
local config = require("abide.config")
local format_utils = require("abide.utils.format")
local fs_utils = require("abide.utils.fs")

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
	return fs_utils.check_executable("yamlfmt")
end

---@return nil
M.setup = function()
	local opts = config.get_formatter("yamlfmt") or M.default
	local filetypes = fs_utils.filter_filetypes(opts.filetypes, opts.disable_filetypes)

	autocmd.New(filetypes, function(o)
		local stdin = buffer_utils.get_buffer_lines(o.buf)
		local argv = { "yamlfmt", "-in" }

		if opts.additional_args and #opts.additional_args > 0 then
			vim.list_extend(argv, opts.additional_args)
		end

		format_utils.format({ buf = o.buf, argv = argv, stdin = stdin })
	end)
end

return M
