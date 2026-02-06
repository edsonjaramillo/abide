local autocmd = require("abide.autocmd")
local buffer_utils = require("abide.utils.buffer")
local config = require("abide.config")
local executable_utils = require("abide.utils.exe")
local format_utils = require("abide.utils.format")
local fs_utils = require("abide.utils.fs")

---@alias StyluaFiletype "lua"

---@class StyluaOptions
---@field enabled? boolean DEFAULT: false
---@field filetypes? StyluaFiletype[] DEFAULT: { "lua" }
---@field disable_filetypes? StyluaFiletype[] DEFAULT: {}
---@field project_executables? string[] DEFAULT: {}
---@field config_files? string[] DEFAULT: { "stylua.toml", ".stylua.toml" }
---@field additional_args? string[] DEFAULT: {}

---@class StyluaModule
---@field default StyluaOptions
---@field setup fun(): nil
---
---@type StyluaModule
local M = {}

---@type StyluaOptions
M.default = {
	enabled = false,
	filetypes = { "lua" },
	disable_filetypes = {},
	project_executables = {},
	config_files = { "stylua.toml", ".stylua.toml" },
	additional_args = {},
}

---@return nil
M.setup = function()
	local opts = config.get_formatter("stylua") or M.default
	local filetypes = fs_utils.filter_filetypes(opts.filetypes, opts.disable_filetypes)

	autocmd.New(filetypes, function(o)
		local stylua_executable = executable_utils.get_executable("stylua", o.file, opts.project_executables)
		local argv = { stylua_executable }

		for _, arg in ipairs(opts.additional_args or {}) do
			table.insert(argv, arg)
		end
		table.insert(argv, "-")

		local config_path = fs_utils.find_config_file(o.file, opts.config_files)

		local stdin = buffer_utils.get_buffer_lines(o.buf)
		format_utils.format({ buf = o.buf, argv = argv, stdin = stdin, config = config_path })
	end)
end

return M
