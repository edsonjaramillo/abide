local autocmd = require("abide.autocmd")
local buffer_utils = require("abide.utils.buffer")
local config = require("abide.config")
local format_utils = require("abide.utils.format")
local fs_utils = require("abide.utils.fs")

---@alias GofumptFiletype "go"

---@class GofumptOptions
---@field enabled? boolean DEFAULT: false
---@field filetypes? GofumptFiletype[] DEFAULT: { "go" }
---@field disable_filetypes? GofumptFiletype[] DEFAULT: {}
---@field additional_args? string[] DEFAULT: {}

---@class GofumptModule
---@field default GofumptOptions
---@field setup fun(): nil
---
---@type GofumptModule
local M = {}

---@type GofumptOptions
M.default = {
	enabled = false,
	filetypes = { "go" },
	disable_filetypes = {},
	additional_args = {},
}

---@return nil
M.setup = function()
	local opts = config.get_formatter("gofumpt") or M.default
	local filetypes = fs_utils.filter_filetypes(opts.filetypes, opts.disable_filetypes)

	autocmd.New(filetypes, function(o)
		local stdin = buffer_utils.get_buffer_lines(o.buf)
		local argv = { "gofumpt" }

		if opts.additional_args and #opts.additional_args > 0 then
			vim.list_extend(argv, opts.additional_args)
		end

		format_utils.format({ buf = o.buf, argv = argv, stdin = stdin, config = nil })
	end)
end

return M
