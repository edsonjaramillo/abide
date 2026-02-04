local autocmd = require("abide.autocmd")
local utils = require("abide.utils")

---@alias GofumptFiletype "go"

---@class GofumptOptions
---@field enabled? boolean DEFAULT: false
---@field filetypes? GofumptFiletype[] DEFAULT: { "go" }
---@field disable_filetypes? GofumptFiletype[] DEFAULT: {}
---@field additional_args? string[] DEFAULT: {}

---@class GofumptModule
---@field default GofumptOptions
---@field prerequisites fun(): boolean
---@field setup fun(opts: GofumptOptions): nil
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

---@return boolean
M.prerequisites = function()
	return utils.check_executable("gofumpt")
end

---@param opts GofumptOptions
---@return nil
M.setup = function(opts)
	local filetypes = utils.filter_filetypes(opts.filetypes, opts.disable_filetypes)

	autocmd.New(filetypes, function(o)
		local stdin = utils.get_buffer_lines(o.buf)
		local argv = { "gofumpt" }

		if opts.additional_args and #opts.additional_args > 0 then
			vim.list_extend(argv, opts.additional_args)
		end

		utils.format({ buf = o.buf, argv = argv, stdin = stdin, config = nil })
	end)
end

return M
