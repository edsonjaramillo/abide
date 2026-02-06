local autocmd = require("abide.autocmd")
local buffer_utils = require("abide.utils.buffer")
local config = require("abide.config")
local executable_utils = require("abide.utils.exe")
local format_utils = require("abide.utils.format")
local fs_utils = require("abide.utils.fs")

---@alias AlejandraFiletype "nix"

---@class AlejandraOptions
---@field enabled? boolean DEFAULT: false
---@field filetypes? AlejandraFiletype[] DEFAULT: { "nix" }
---@field disable_filetypes? AlejandraFiletype[] DEFAULT: {}
---@field config_files? string[] DEFAULT: {}
---@field additional_args? string[] DEFAULT: {}

---@class AlejandraModule
---@field default AlejandraOptions
---@field setup fun(): nil
---
---@type AlejandraModule
local M = {}

---@type AlejandraOptions
M.default = {
	enabled = false,
	filetypes = { "nix" },
	disable_filetypes = {},
	config_files = {},
	additional_args = {},
}

---@return nil
M.setup = function()
	local opts = config.get_formatter("alejandra") or M.default
	local filetypes = fs_utils.filter_filetypes(opts.filetypes, opts.disable_filetypes)

	autocmd.New(filetypes, function(o)
		local alejandra = executable_utils.get_executable("alejandra", o.file)
		local argv = { alejandra, "-" }

		if opts.additional_args and #opts.additional_args > 0 then
			vim.list_extend(argv, opts.additional_args)
		end

		local config_path = fs_utils.find_config_file(o.file, opts.config_files)

		local stdin = buffer_utils.get_buffer_lines(o.buf)
		format_utils.format({ buf = o.buf, argv = argv, stdin = stdin, config = config_path })
	end)
end

return M
