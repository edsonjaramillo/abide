local autocmd = require("abide.autocmd")
local buffer_utils = require("abide.utils.buffer")
local config = require("abide.config")
local executable_utils = require("abide.utils.exe")
local fallback_utils = require("abide.utils.fallback")
local format_utils = require("abide.utils.format")
local fs_utils = require("abide.utils.fs")

---@alias YamlfmtFiletype "yaml"

---@class YamlfmtOptions
---@field enabled? boolean DEFAULT: false
---@field filetypes? YamlfmtFiletype[] DEFAULT: { "yaml" }
---@field disable_filetypes? YamlfmtFiletype[] DEFAULT: {}
---@field project_executables? string[] DEFAULT: {}
---@field config_files? string[] DEFAULT: { ".yamlfmt", ".yamlfmt.yaml", ".yamlfmt.yml", "yamlfmt.yaml", "yamlfmt.yml" }
---@field fallback? "auto"|"never"|"always" DEFAULT: "auto"
---@field fallback_args? string[] DEFAULT: {}

---@class YamlfmtModule
---@field default YamlfmtOptions
---@field setup fun(): nil
---
---@type YamlfmtModule
local M = {}

---@type YamlfmtOptions
M.default = {
	enabled = false,
	filetypes = { "yaml" },
	disable_filetypes = {},
	project_executables = {},
	config_files = { ".yamlfmt", ".yamlfmt.yaml", ".yamlfmt.yml", "yamlfmt.yaml", "yamlfmt.yml" },
	fallback = "auto",
	fallback_args = {},
}

---@return nil
M.setup = function()
	local opts = config.get_formatter("yamlfmt") or M.default
	local filetypes = fs_utils.filter_filetypes(opts.filetypes, opts.disable_filetypes)

	autocmd.New(filetypes, function(o)
		local yamlfmt = executable_utils.get_executable("yamlfmt", o.file, opts.project_executables)
		local argv = { yamlfmt, "-in" }

		local config_path = fs_utils.find_config_file(o.file, opts.config_files)
		local fallback = fallback_utils.resolve(opts.fallback, config_path)
		if not fallback.should_format then
			return
		end

		if fallback.use_fallback and opts.fallback_args and #opts.fallback_args > 0 then
			vim.list_extend(argv, opts.fallback_args)
		end

		if fallback.config then
			vim.list_extend(argv, { "-conf", fallback.config })
		end

		local stdin = buffer_utils.get_buffer_lines(o.buf)
		format_utils.format({
			buf = o.buf,
			argv = argv,
			stdin = stdin,
			config = fallback.config,
			mode = fallback.mode,
			formatter = "yamlfmt",
			executable = yamlfmt,
		})
	end)
end

return M
