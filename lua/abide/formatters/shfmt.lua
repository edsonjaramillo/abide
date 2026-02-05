local autocmd = require("abide.autocmd")
local config = require("abide.config")
local utils = require("abide.utils")

---@alias ShfmtLanguage "bash"|"posix"|"mksh"|"bats"
---@alias ShfmtFiletype "sh"|"bash"|"bats"|"zsh"

---@class ShfmtOptions
---@field enabled? boolean DEFAULT: false
---@field filetypes? ShfmtFiletype[] DEFAULT: { "sh", "bash", "bats", "zsh" }
---@field disable_filetypes? ShfmtFiletype[] DEFAULT: {}
---@field additional_args? string[] DEFAULT: {}

---@class ShfmtModule
---@field default ShfmtOptions
---@field prerequisites fun(): boolean
---@field setup fun(): nil
---
---@type ShfmtModule
local M = {}

---@type ShfmtOptions
M.default = {
	enabled = false,
	filetypes = { "sh", "bash", "bats", "zsh" },
	disable_filetypes = {},
	additional_args = {},
}

---@return boolean
M.prerequisites = function()
	return utils.check_executable("shfmt")
end

---@return nil
M.setup = function()
	local opts = config.get_formatter("shfmt") or M.default
	local patterns = utils.filter_filetypes(opts.filetypes, opts.disable_filetypes)

	autocmd.New(patterns, function(o)
		local stdin = utils.get_buffer_lines(o.buf)
		local argv = { "shfmt" }

		if opts.additional_args and #opts.additional_args > 0 then
			vim.list_extend(argv, opts.additional_args)
		end

		-- Give shfmt the filename even when formatting via stdin; this helps it
		-- infer language details from the path when possible.
		if o.file and o.file ~= "" then
			vim.list_extend(argv, { "--filename", o.file })
		end

		utils.format({ buf = o.buf, argv = argv, stdin = stdin, config = nil })
	end)
end

return M
