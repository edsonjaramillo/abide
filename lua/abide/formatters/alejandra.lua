local autocmd = require("abide.autocmd")
local utils = require("abide.utils")

---@alias AlejandraFiletype "nix"

---@class AlejandraOptions
---@field enabled? boolean DEFAULT: false
---@field filetypes? AlejandraFiletype[] DEFAULT: { "nix" }
---@field disable_filetypes? AlejandraFiletype[] DEFAULT: {}
---@field additional_args? string[] DEFAULT: {}

---@class AlejandraModule
---@field default AlejandraOptions
---@field prerequisites fun(): boolean
---@field setup fun(opts: AlejandraOptions): nil
---
---@type AlejandraModule
local M = {}

---@type AlejandraOptions
M.default = {
	enabled = false,
	filetypes = { "nix" },
	disable_filetypes = {},
	additional_args = {},
}

---@return boolean
M.prerequisites = function()
	return utils.check_executable("alejandra")
end

---@param opts AlejandraOptions
---@return nil
M.setup = function(opts)
	local filetypes = utils.filter_filetypes(opts.filetypes, opts.disable_filetypes)

	autocmd.New(filetypes, function(o)
		local stdin = utils.get_buffer_lines(o.buf)
		local argv = { "alejandra", "-" }

		if opts.additional_args and #opts.additional_args > 0 then
			vim.list_extend(argv, opts.additional_args)
		end

		utils.format({ buf = o.buf, argv = argv, stdin = stdin, config = nil })
	end)
end

return M
