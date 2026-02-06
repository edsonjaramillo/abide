local autocmd = require("abide.autocmd")
local buffer_utils = require("abide.utils.buffer")
local config = require("abide.config")
local executable_utils = require("abide.utils.exe")
local format_utils = require("abide.utils.format")
local fs_utils = require("abide.utils.fs")

---@alias TaploFiletype "toml"

---@class TaploOptions
---@field enabled? boolean DEFAULT: false
---@field filetypes? TaploFiletype[] DEFAULT: { "toml" }
---@field disable_filetypes? TaploFiletype[] DEFAULT: {}
---@field project_executables? string[] DEFAULT: {}
---@field config_files? string[] DEFAULT: { "taplo.toml", ".taplo.toml" }
---@field additional_args? string[] DEFAULT: {}

---@class TaploModule
---@field default TaploOptions
---@field setup fun(): nil
---
---@type TaploModule
local M = {}

---@type TaploOptions
M.default = {
	enabled = false,
	filetypes = { "toml" },
	disable_filetypes = {},
	project_executables = {},
	config_files = { "taplo.toml", ".taplo.toml" },
	additional_args = {},
}

---@return nil
M.setup = function()
	local opts = config.get_formatter("taplo") or M.default
	local filetypes = fs_utils.filter_filetypes(opts.filetypes, opts.disable_filetypes)

	autocmd.New(filetypes, function(o)
		local taplo = executable_utils.get_executable("taplo", o.file, opts.project_executables)
		local argv = { taplo, "format" }

		if opts.additional_args and #opts.additional_args > 0 then
			vim.list_extend(argv, opts.additional_args)
		end

		local config_path = fs_utils.find_config_file(o.file, opts.config_files)
		if config_path then
			vim.list_extend(argv, { "--config", config_path })
		end
		table.insert(argv, "-")

		if o.file and o.file ~= "" then
			vim.list_extend(argv, { "--stdin-filepath", o.file })
		end

		local stdin = buffer_utils.get_buffer_lines(o.buf)
		format_utils.format({
			buf = o.buf,
			argv = argv,
			stdin = stdin,
			config = config_path,
			formatter = "taplo",
			executable = taplo,
		})
	end)
end

return M
