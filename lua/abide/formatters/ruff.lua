local autocmd = require("abide.autocmd")
local buffer_utils = require("abide.utils.buffer")
local config = require("abide.config")
local executable_utils = require("abide.utils.exe")
local fallback_utils = require("abide.utils.fallback")
local format_utils = require("abide.utils.format")
local fs_utils = require("abide.utils.fs")

---@alias RuffFiletype "python"

---@class RuffOptions
---@field enabled? boolean DEFAULT: false
---@field filetypes? RuffFiletype[] DEFAULT: { "python" }
---@field disable_filetypes? RuffFiletype[] DEFAULT: {}
---@field project_executables? string[] DEFAULT: { ".venv/bin/ruff", "venv/bin/ruff" }
---@field config_files? string[] DEFAULT: { "ruff.toml", ".ruff.toml", "pyproject.toml" }
---@field fallback? "auto"|"never"|"always" DEFAULT: "auto"
---@field fallback_args? string[] DEFAULT: {}

---@class RuffModule
---@field default RuffOptions
---@field setup fun(): nil
---
---@type RuffModule
local M = {}

---@type RuffOptions
M.default = {
	enabled = false,
	filetypes = { "python" },
	disable_filetypes = {},
	project_executables = { ".venv/bin/ruff", "venv/bin/ruff" },
	config_files = { "ruff.toml", ".ruff.toml", "pyproject.toml" },
	fallback = "auto",
	fallback_args = {},
}

---@return nil
M.setup = function()
	local opts = config.get_formatter("ruff") or M.default
	local filetypes = fs_utils.filter_filetypes(opts.filetypes, opts.disable_filetypes)

	autocmd.New(filetypes, function(o)
		local ruff = executable_utils.get_executable("ruff", o.file, opts.project_executables)
		local argv = { ruff, "format" }

		local config_path = fs_utils.find_config_file(o.file, opts.config_files)
		local fallback = fallback_utils.resolve(opts.fallback, config_path)
		if not fallback.should_format then
			return
		end

		if fallback.use_fallback and opts.fallback_args and #opts.fallback_args > 0 then
			vim.list_extend(argv, opts.fallback_args)
		end

		if fallback.config then
			vim.list_extend(argv, { "--config", fallback.config })
		end

		table.insert(argv, "-")

		if o.file and o.file ~= "" then
			vim.list_extend(argv, { "--stdin-filename", o.file })
		end

		local stdin = buffer_utils.get_buffer_lines(o.buf)
		format_utils.format({
			buf = o.buf,
			argv = argv,
			stdin = stdin,
			config = fallback.config,
			mode = fallback.mode,
			formatter = "ruff",
			executable = ruff,
		})
	end)
end

return M
