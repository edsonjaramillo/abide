---@class AbideOptions
---@field formatters? Formatters

---@class Formatters
---@field alejandra? AlejandraOptions
---@field gofumpt? GofumptOptions
---@field prettier? PrettierOptions
---@field shfmt? ShfmtOptions
---@field stylua? StyluaOptions
---@field taplo? TaploOptions
---@field yamlfmt? YamlfmtOptions

---@type AbideOptions
local default_config = { formatters = {} }

local M = {}

---@param opts AbideOptions
M.setup = function(opts)
	opts = vim.tbl_deep_extend("force", vim.deepcopy(default_config), opts or {})

	for fmt, _ in pairs(opts.formatters) do
		local formatter = require("abide.formatters." .. fmt)

		local fmt_opts = vim.tbl_deep_extend("force", formatter.default, opts.formatters[fmt] or {})
		default_config.formatters[fmt] = fmt_opts

		if fmt_opts.enabled and formatter.prerequisites() then
			formatter.setup(fmt_opts)
		end
	end
end

return M
