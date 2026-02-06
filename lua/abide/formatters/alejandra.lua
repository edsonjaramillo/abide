local autocmd = require("abide.autocmd")
local buffer_utils = require("abide.utils.buffer")
local config = require("abide.config")
local executable_utils = require("abide.utils.exe")
local fallback_utils = require("abide.utils.fallback")
local format_utils = require("abide.utils.format")
local fs_utils = require("abide.utils.fs")

---@alias AlejandraFiletype "nix"

---@class AlejandraOptions
---@field enabled? boolean DEFAULT: false
---@field filetypes? AlejandraFiletype[] DEFAULT: { "nix" }
---@field disable_filetypes? AlejandraFiletype[] DEFAULT: {}
---@field project_executables? string[] DEFAULT: {}
---@field config_files? string[] DEFAULT: { "alejandra.toml" }
---@field fallback? "auto"|"never"|"always" DEFAULT: "auto"
---@field fallback_args? string[] DEFAULT: {}

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
	project_executables = {},
	config_files = { "alejandra.toml" },
	fallback = "auto",
	fallback_args = {},
}

---@return nil
M.setup = function()
	local opts = config.get_formatter("alejandra") or M.default
	local filetypes = fs_utils.filter_filetypes(opts.filetypes, opts.disable_filetypes)

	autocmd.New(filetypes, function(o)
		local alejandra = executable_utils.get_executable("alejandra", o.file, opts.project_executables)
		local argv = { alejandra }

		local config_path = fs_utils.find_config_file(o.file, opts.config_files)
		local fallback = fallback_utils.resolve(opts.fallback, config_path)
		if not fallback.should_format then
			return
		end

		if fallback.use_fallback and opts.fallback_args and #opts.fallback_args > 0 then
			vim.list_extend(argv, opts.fallback_args)
		end

		if fallback.config then
			vim.list_extend(argv, { "--experimental-config", fallback.config })
		end

		local stdin = buffer_utils.get_buffer_lines(o.buf)
		format_utils.format({
			buf = o.buf,
			argv = argv,
			stdin = stdin,
			config = fallback.config,
			mode = fallback.mode,
			formatter = "alejandra",
			executable = alejandra,
		})
	end)
end

return M
