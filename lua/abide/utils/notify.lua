local config = require("abide.config")

local M = {}

--- Notify the user with a log level string.
--- @param message string
--- @param level? "trace"|"debug"|"info"|"warn"|"error"|"off"
--- @param opts? table
M.notify = function(message, level, opts)
	local global_opts = config.get_global()

	local is_critical = false
	if level == "error" or level == "warn" then
		is_critical = true
	end

	if global_opts.notify == false and is_critical == false then
		return
	end

	local resolved_level = level or "info"
	local notify_opts = vim.tbl_deep_extend("force", { title = "abide" }, opts or {})
	vim.notify(message, vim.log.levels[resolved_level:upper()], notify_opts)
end

--- Notify the user about a successful format operation with contextual metadata.
--- @param details {bufnr:number, formatter:string|nil, executable:string|nil, config:string|nil}
M.notify_format_success = function(details)
	local formatter_name = details.formatter or "unknown"
	local executable = details.executable or "unknown"

	local pretty_executable = executable:gsub(vim.fn.getcwd(), "$CWD")
	local message = string.format("Executable: %s", pretty_executable)

	if details.config then
		local pretty_config_path = details.config:gsub(vim.fn.expand("~"), "~")
		message = message .. "\nConfig: " .. pretty_config_path
	end

	local title = string.format("[%s] Buffer %d formatted", formatter_name, details.bufnr)
	M.notify(message, "info", { title = title })
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
