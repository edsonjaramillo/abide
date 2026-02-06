local M = {}
local buffer_utils = require("abide.utils.buffer")
local notify_utils = require("abide.utils.notify")

--- Run a command and wait for it to complete.
--- @param argv string[]
--- @param stdin string
--- @return vim.SystemCompleted
M.execute_command = function(argv, stdin)
	return vim.system(argv, { stdin = stdin, text = true }):wait()
end

---@class CommandOptions
---@field buf number Buffer number
---@field argv string[] Command and arguments to run
---@field stdin string Input to pass to the command
---@field config string|nil Path to the config file if found
---@field formatter string|nil Formatter identifier (e.g. "prettier")
---@field executable string|nil Resolved executable used to run formatting
--- Format a buffer with the provided command options.
--- @param options CommandOptions
M.format = function(options)
	local initial_changedtick = vim.api.nvim_buf_get_changedtick(options.buf)
	local result = M.execute_command(options.argv, options.stdin)
	if result.code ~= 0 then
		local error_output = result.stderr
		if error_output == nil or error_output == "" then
			error_output = result.stdout or ""
		end
		notify_utils.notify("Command failed (exit " .. result.code .. "): " .. error_output, "error")
		return
	end

	if result.stdout == nil or result.stdout == "" then
		notify_utils.notify("Formatter produced no output; buffer unchanged.", "warn")
		return
	end

	if vim.api.nvim_buf_get_changedtick(options.buf) ~= initial_changedtick then
		notify_utils.notify("Buffer changed during formatting; results discarded.", "warn")
		return
	end

	local formatted_lines = vim.split(result.stdout, "\n", { plain = true, trimempty = true })
	buffer_utils.apply_formatted_lines(options.buf, formatted_lines)
	notify_utils.notify_format_success({
		bufnr = options.buf,
		formatter = options.formatter,
		executable = options.executable or options.argv[1],
		config = options.config,
	})
end

return M
