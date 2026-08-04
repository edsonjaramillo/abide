---@class Formatters
---@field alejandra? AlejandraOptions
---@field gofumpt? GofumptOptions
---@field oxfmt? OxfmtOptions
---@field prettier? PrettierOptions
---@field ruff? RuffOptions
---@field shfmt? ShfmtOptions
---@field stylua? StyluaOptions
---@field taplo? TaploOptions
---@field yamlfmt? YamlfmtOptions

local M = {}

---@param opts AbideOptions
M.setup = function(opts)
	local config = require("abide.config")
	config.setup(opts)

	local formatters = config.get().formatters
	for fmt, _ in pairs(formatters) do
		local formatter = require("abide.formatters." .. fmt)

		local fmt_opts = vim.tbl_deep_extend("force", formatter.default, formatters[fmt] or {})
		config.set_formatter(fmt, fmt_opts)

		if fmt_opts.enabled then
			formatter.setup()
		end
	end
end

return M
