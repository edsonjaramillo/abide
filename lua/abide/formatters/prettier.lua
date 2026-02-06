local autocmd = require("abide.autocmd")
local buffer_utils = require("abide.utils.buffer")
local config = require("abide.config")
local executable_utils = require("abide.utils.exe")
local fallback_utils = require("abide.utils.fallback")
local format_utils = require("abide.utils.format")
local fs_utils = require("abide.utils.fs")

---@alias PrettierFiletype
---| "javascript"
---| "javascriptreact"
---| "typescript"
---| "typescriptreact"
---| "json"
---| "jsonc"
---| "yaml"
---| "markdown"
---| "mdx"
---| "css"
---| "scss"
---| "less"
---| "html"
---| "graphql"
---| "vue"
---| "svelte"
---| "astro"

---@class PrettierOptions
---@field enabled? boolean DEFAULT: false
---@field filetypes? PrettierFiletype[] DEFAULT: { "javascript", "javascriptreact", "typescript", "typescriptreact", "json", "jsonc", "yaml", "markdown", "mdx", "css", "scss", "less", "html", "graphql", "vue", "svelte", "astro" }
---@field disable_filetypes? PrettierFiletype[] DEFAULT: {}
---@field project_executables? string[] DEFAULT: { "node_modules/.bin/prettier" }
---@field config_files? string[] DEFAULT: { ".prettierrc", ".prettierrc.json", ".prettierrc.yml", ".prettierrc.yaml", ".prettierrc.json5", ".prettierrc.js", ".prettierrc.cjs", ".prettierrc.mjs", ".prettierrc.toml", "prettier.config.js", "prettier.config.cjs", "prettier.config.mjs" }
---@field fallback? "auto"|"never"|"always" DEFAULT: "auto"
---@field fallback_args? string[] DEFAULT: {}

---@class PrettierModule
---@field default PrettierOptions
---@field setup fun(): nil
---
---@type PrettierModule
local M = {}

---@type PrettierOptions
M.default = {
	enabled = false,
	filetypes = {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
		"json",
		"jsonc",
		"yaml",
		"markdown",
		"mdx",
		"css",
		"scss",
		"less",
		"html",
		"graphql",
		"vue",
		"svelte",
		"astro",
	},
	disable_filetypes = {},
	project_executables = { "node_modules/.bin/prettier" },
	config_files = {
		".prettierrc",
		".prettierrc.json",
		".prettierrc.yml",
		".prettierrc.yaml",
		".prettierrc.json5",
		".prettierrc.js",
		".prettierrc.cjs",
		".prettierrc.mjs",
		".prettierrc.toml",
		"prettier.config.js",
		"prettier.config.cjs",
		"prettier.config.mjs",
	},
	fallback = "auto",
	fallback_args = {},
}

---@return nil
M.setup = function()
	local opts = config.get_formatter("prettier") or M.default
	local filetypes = fs_utils.filter_filetypes(opts.filetypes, opts.disable_filetypes)

	autocmd.New(filetypes, function(o)
		local prettier = executable_utils.get_executable("prettier", o.file, opts.project_executables)
		local argv = { prettier }

		local config_path = fs_utils.find_config_file(o.file, opts.config_files)
		local fallback = fallback_utils.resolve(opts.fallback, config_path)
		if not fallback.should_format then
			return
		end

		if o.file and o.file ~= "" then
			vim.list_extend(argv, { "--stdin-filepath", o.file })
		end

		if fallback.use_fallback and opts.fallback_args and #opts.fallback_args > 0 then
			vim.list_extend(argv, opts.fallback_args)
		end

		if fallback.config then
			vim.list_extend(argv, { "--config", fallback.config })
		end

		local stdin = buffer_utils.get_buffer_lines(o.buf)
		format_utils.format({
			buf = o.buf,
			argv = argv,
			stdin = stdin,
			config = fallback.config,
			mode = fallback.mode,
			formatter = "prettier",
			executable = prettier,
		})
	end)
end

return M
