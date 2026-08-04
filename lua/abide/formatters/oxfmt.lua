local autocmd = require("abide.autocmd")
local buffer_utils = require("abide.utils.buffer")
local config = require("abide.config")
local executable_utils = require("abide.utils.exe")
local fallback_utils = require("abide.utils.fallback")
local format_utils = require("abide.utils.format")
local fs_utils = require("abide.utils.fs")

---@alias OxfmtFiletype
---| "javascript"
---| "javascriptreact"
---| "typescript"
---| "typescriptreact"
---| "json"
---| "jsonc"
---| "json5"
---| "yaml"
---| "toml"
---| "html"
---| "css"
---| "scss"
---| "less"
---| "markdown"
---| "mdx"
---| "graphql"
---| "vue"
---| "svelte"
---| "handlebars"

---@class OxfmtOptions
---@field enabled? boolean DEFAULT: false
---@field filetypes? OxfmtFiletype[] DEFAULT: { "javascript", "javascriptreact", "typescript", "typescriptreact", "json", "jsonc", "json5", "yaml", "toml", "html", "css", "scss", "less", "markdown", "mdx", "graphql", "vue", "svelte", "handlebars" }
---@field disable_filetypes? OxfmtFiletype[] DEFAULT: {}
---@field project_executables? string[] DEFAULT: { "node_modules/.bin/oxfmt" }
---@field config_files? string[] DEFAULT: { ".oxfmtrc.json", ".oxfmtrc.jsonc", "oxfmt.config.ts" }
---@field fallback? "auto"|"never"|"always" DEFAULT: "auto"
---@field fallback_args? string[] DEFAULT: {}

---@class OxfmtModule
---@field default OxfmtOptions
---@field setup fun(): nil
---
---@type OxfmtModule
local M = {}

---@type OxfmtOptions
M.default = {
	enabled = false,
	filetypes = {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
		"json",
		"jsonc",
		"json5",
		"yaml",
		"toml",
		"html",
		"css",
		"scss",
		"less",
		"markdown",
		"mdx",
		"graphql",
		"vue",
		"svelte",
		"handlebars",
	},
	disable_filetypes = {},
	project_executables = { "node_modules/.bin/oxfmt" },
	config_files = { ".oxfmtrc.json", ".oxfmtrc.jsonc", "oxfmt.config.ts" },
	fallback = "auto",
	fallback_args = {},
}

---@return nil
M.setup = function()
	local opts = config.get_formatter("oxfmt") or M.default
	local filetypes = fs_utils.filter_filetypes(opts.filetypes, opts.disable_filetypes)

	autocmd.New(filetypes, function(o)
		local oxfmt = executable_utils.get_executable("oxfmt", o.file, opts.project_executables)
		local argv = { oxfmt }

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

		if o.file and o.file ~= "" then
			vim.list_extend(argv, { "--stdin-filepath", o.file })
		end

		local stdin = buffer_utils.get_buffer_lines(o.buf)
		format_utils.format({
			buf = o.buf,
			argv = argv,
			stdin = stdin,
			config = fallback.config,
			mode = fallback.mode,
			formatter = "oxfmt",
			executable = oxfmt,
		})
	end)
end

return M
