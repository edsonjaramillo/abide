local M = {}
local config = require("abide.config")

--- Notify the user with a log level string.
--- @param message string
--- @param level? "trace"|"debug"|"info"|"warn"|"error"|"off"
--- @param opts? table
M.notify = function(message, level, opts)
	local global_opts = config.get_global()
	if global_opts.notify == false then
		return
	end

	local resolved_level = level or "info"
	local notify_opts = vim.tbl_deep_extend("force", { title = "abide" }, opts or {})
	vim.notify(message, vim.log.levels[resolved_level:upper()], notify_opts)
end

--- Notify the user with a vim.inspect dump (or "nil" when value is nil).
--- @param value any
M.inspect = function(value)
	if value == nil then
		M.notify("nil", "info", { title = "abide debug" })
		return
	end
	M.notify(vim.inspect(value), "info", { title = "abide debug" })
end

return M
