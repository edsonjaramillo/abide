local autocmd = require("abide.autocmd")
local buffer_utils = require("abide.utils.buffer")
local config = require("abide.config")
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
---@field additional_args? string[] DEFAULT: {}

---@class PrettierModule
---@field default PrettierOptions
---@field prerequisites fun(): boolean
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
	additional_args = {},
}

---@return boolean
M.prerequisites = function()
	return fs_utils.check_executable("prettier")
end

---@return nil
M.setup = function()
	local opts = config.get_formatter("prettier") or M.default
	local filetypes = fs_utils.filter_filetypes(opts.filetypes, opts.disable_filetypes)
	autocmd.New(filetypes, function(o)
		local stdin = buffer_utils.get_buffer_lines(o.buf)
		local argv = { "prettier" }

		if o.file and o.file ~= "" then
			vim.list_extend(argv, { "--stdin-filepath", o.file })
		end

		if opts.additional_args and #opts.additional_args > 0 then
			vim.list_extend(argv, opts.additional_args)
		end

		format_utils.format({ buf = o.buf, argv = argv, stdin = stdin })
	end)
end

return M
