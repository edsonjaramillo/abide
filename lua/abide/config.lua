---@class AbideGlobalOptions
---@field notify? boolean

---@class AbideOptions
---@field global? AbideGlobalOptions
---@field formatters? Formatters

---@class AbideConfig
---@field global AbideGlobalOptions
---@field formatters Formatters

local M = {}

---@type AbideConfig
M.defaults = { global = {}, formatters = {} }

---@type AbideConfig
M._config = vim.deepcopy(M.defaults)

---@param opts? AbideOptions
M.setup = function(opts)
	M._config = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

---@return AbideConfig
M.get = function()
	return M._config
end

---@return AbideGlobalOptions
M.get_global = function()
	return M._config.global or {}
end

---@param name string
---@return table|nil
M.get_formatter = function(name)
	local formatters = M._config.formatters or {}
	return formatters[name]
end

---@param name string
---@param opts table
M.set_formatter = function(name, opts)
	if not M._config.formatters then
		M._config.formatters = {}
	end
	M._config.formatters[name] = opts
end

return M
