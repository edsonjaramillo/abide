local autocmd = require("abide.autocmd")
local buffer_utils = require("abide.utils.buffer")
local config = require("abide.config")
local executable_utils = require("abide.utils.exe")
local fallback_utils = require("abide.utils.fallback")
local format_utils = require("abide.utils.format")
local fs_utils = require("abide.utils.fs")

---@alias ClangFormatFiletype "c"|"cpp"|"objc"|"objcpp"|"cuda"|"proto"|"java"|"cs"

---@class ClangFormatOptions
---@field enabled? boolean DEFAULT: false
---@field filetypes? ClangFormatFiletype[] DEFAULT: { "c", "cpp", "objc", "objcpp", "cuda", "proto" }
---@field disable_filetypes? ClangFormatFiletype[] DEFAULT: {}
---@field project_executables? string[] DEFAULT: {}
---@field config_files? string[] DEFAULT: { ".clang-format", "_clang-format" }
---@field fallback? "auto"|"never"|"always" DEFAULT: "auto"
---@field fallback_args? string[] DEFAULT: {}

---@class ClangFormatModule
---@field default ClangFormatOptions
---@field setup fun(): nil
---
---@type ClangFormatModule
local M = {}

---@type ClangFormatOptions
M.default = {
	enabled = false,
	filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
	disable_filetypes = {},
	project_executables = {},
	config_files = { ".clang-format", "_clang-format" },
	fallback = "auto",
	fallback_args = {},
}

---@return nil
M.setup = function()
	local opts = config.get_formatter("clang_format") or M.default
	local filetypes = fs_utils.filter_filetypes(opts.filetypes, opts.disable_filetypes)

	autocmd.New(filetypes, function(o)
		local clang_format = executable_utils.get_executable("clang-format", o.file, opts.project_executables)
		local argv = { clang_format }

		local config_path = fs_utils.find_config_file(o.file, opts.config_files)
		local fallback = fallback_utils.resolve(opts.fallback, config_path)
		if not fallback.should_format then
			return
		end

		if fallback.use_fallback and opts.fallback_args and #opts.fallback_args > 0 then
			vim.list_extend(argv, opts.fallback_args)
		end

		-- Requires clang-format >= 14 for the `file:<path>` style syntax.
		if fallback.config then
			table.insert(argv, "--style=file:" .. fallback.config)
		end

		-- clang-format reads stdin; the assumed filename lets it infer the
		-- language from the extension.
		if o.file and o.file ~= "" then
			table.insert(argv, "--assume-filename=" .. o.file)
		end

		local stdin = buffer_utils.get_buffer_lines(o.buf)
		format_utils.format({
			buf = o.buf,
			argv = argv,
			stdin = stdin,
			config = fallback.config,
			mode = fallback.mode,
			formatter = "clang_format",
			executable = clang_format,
		})
	end)
end

return M
