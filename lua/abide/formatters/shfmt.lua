local autocmd = require("abide.autocmd")
local buffer_utils = require("abide.utils.buffer")
local config = require("abide.config")
local executable_utils = require("abide.utils.exe")
local fallback_utils = require("abide.utils.fallback")
local format_utils = require("abide.utils.format")
local fs_utils = require("abide.utils.fs")

---@alias ShfmtLanguage "bash"|"posix"|"mksh"|"bats"
---@alias ShfmtFiletype "sh"|"bash"|"bats"|"zsh"

---@class ShfmtOptions
---@field enabled? boolean DEFAULT: false
---@field filetypes? ShfmtFiletype[] DEFAULT: { "sh", "bash", "bats", "zsh" }
---@field disable_filetypes? ShfmtFiletype[] DEFAULT: {}
---@field project_executables? string[] DEFAULT: {}
---@field config_files? string[] DEFAULT: { ".editorconfig" }
---@field fallback? "auto"|"never"|"always" DEFAULT: "auto"
---@field fallback_args? string[] DEFAULT: {}

---@class ShfmtModule
---@field default ShfmtOptions
---@field setup fun(): nil
---
---@type ShfmtModule
local M = {}

---@type ShfmtOptions
M.default = {
	enabled = false,
	filetypes = { "sh", "bash", "bats", "zsh" },
	disable_filetypes = {},
	project_executables = {},
	config_files = { ".editorconfig" },
	fallback = "auto",
	fallback_args = {},
}

---@return nil
M.setup = function()
	local opts = config.get_formatter("shfmt") or M.default
	local filetypes = fs_utils.filter_filetypes(opts.filetypes, opts.disable_filetypes)

	autocmd.New(filetypes, function(o)
		local shfmt = executable_utils.get_executable("shfmt", o.file, opts.project_executables)
		local argv = { shfmt }

		local config_path = fs_utils.find_config_file(o.file, opts.config_files)
		local fallback = fallback_utils.resolve(opts.fallback, config_path)
		if not fallback.should_format then
			return
		end

		if fallback.use_fallback and opts.fallback_args and #opts.fallback_args > 0 then
			vim.list_extend(argv, opts.fallback_args)
		end

		-- Give shfmt the filename even when formatting via stdin; this helps it
		-- infer language details from the path when possible.
		if o.file and o.file ~= "" then
			vim.list_extend(argv, { "--filename", o.file })
		end

		local stdin = buffer_utils.get_buffer_lines(o.buf)
		format_utils.format({
			buf = o.buf,
			argv = argv,
			stdin = stdin,
			config = fallback.config,
			mode = fallback.mode,
			formatter = "shfmt",
			executable = shfmt,
		})
	end)
end

return M
