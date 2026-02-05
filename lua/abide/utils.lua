local M = {}
local config = require("abide.config")

--- Collect buffer marks that are safe to round-trip.
--- @param bufnr number
--- @return table[] marks list ({ name: string, line: number, col: number })
local function collect_marks(bufnr)
	local marklist = {}
	local ok_marks, marks = pcall(vim.fn.getmarklist, bufnr)
	if ok_marks and type(marks) == "table" then
		for _, item in ipairs(marks) do
			if type(item) == "table" and type(item.mark) == "string" and type(item.pos) == "table" then
				local name = item.mark:sub(-1)
				if name:match("[%w]") then
					local line = item.pos[2]
					local col = item.pos[3]
					if type(line) == "number" and type(col) == "number" then
						table.insert(marklist, { name = name, line = line, col = col })
					end
				end
			end
		end
	end
	return marklist
end

--- Capture window view state for a buffer.
--- @param bufnr number
--- @return table|nil state
local function capture_view(bufnr)
	local winid = vim.fn.bufwinid(bufnr)
	if winid == -1 then
		return nil
	end

	local restore_view = nil
	local viewoptions = nil
	local buffer_name = vim.api.nvim_buf_get_name(bufnr)

	vim.api.nvim_win_call(winid, function()
		restore_view = vim.fn.winsaveview()
		if buffer_name ~= "" then
			viewoptions = vim.o.viewoptions
			if not viewoptions:match("folds") then
				vim.o.viewoptions = viewoptions .. ",folds"
			end
			vim.cmd("silent! mkview!")
		end
	end)

	return {
		winid = winid,
		restore_view = restore_view,
		viewoptions = viewoptions,
		buffer_name = buffer_name,
	}
end

--- Restore window view state previously captured.
--- @param state table|nil
local function restore_view(state)
	if not state then
		return
	end

	vim.api.nvim_win_call(state.winid, function()
		if state.buffer_name ~= "" then
			vim.cmd("silent! loadview")
			if state.viewoptions and vim.o.viewoptions ~= state.viewoptions then
				vim.o.viewoptions = state.viewoptions
			end
		end
		if state.restore_view then
			vim.fn.winrestview(state.restore_view)
		end
	end)
end

--- Restore buffer marks.
--- @param bufnr number
--- @param marks table[]
local function restore_marks(bufnr, marks)
	for _, mark in ipairs(marks) do
		pcall(vim.api.nvim_buf_set_mark, bufnr, mark.name, mark.line, mark.col, {})
	end
end

--- Collect debug breakpoints (e.g. nvim-dap) for a buffer.
--- @param bufnr number
--- @return table[] breakpoints list ({ name: string, lnum: number })
local function collect_debug_breakpoints(bufnr)
	local ok, placed = pcall(vim.fn.sign_getplaced, bufnr, { group = "dap_breakpoints" })
	if not ok or type(placed) ~= "table" or type(placed[1]) ~= "table" then
		return {}
	end

	local breakpoints = {}
	for _, sign in ipairs(placed[1].signs or {}) do
		if type(sign) == "table" and type(sign.name) == "string" and type(sign.lnum) == "number" then
			table.insert(breakpoints, { name = sign.name, lnum = sign.lnum })
		end
	end

	return breakpoints
end

--- Restore debug breakpoints previously collected.
--- @param bufnr number
--- @param breakpoints table[]
local function restore_debug_breakpoints(bufnr, breakpoints)
	if #breakpoints == 0 then
		return
	end

	pcall(vim.fn.sign_unplace, "dap_breakpoints", { buffer = bufnr })
	for _, breakpoint in ipairs(breakpoints) do
		pcall(vim.fn.sign_place, 0, "dap_breakpoints", breakpoint.name, bufnr, { lnum = breakpoint.lnum })
	end
end

--- Run a callback while preserving debug breakpoints in a buffer.
--- @param bufnr number
--- @param callback fun()
M.preserve_debug_breakpoints = function(bufnr, callback)
	local breakpoints = collect_debug_breakpoints(bufnr)
	local ok, err = pcall(callback)
	restore_debug_breakpoints(bufnr, breakpoints)
	if not ok then
		error(err)
	end
end

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

--- Check if an executable is available in PATH
--- @param executable string Optional custom executable name
--- @return boolean
M.check_executable = function(executable)
	if executable == nil or executable == "" then
		M.notify("Executable name is required.", "error")
		return false
	end

	if vim.fn.executable(executable) == 0 then
		M.notify("Executable '" .. executable .. "' not found in PATH.", "error")
		return false
	end

	return true
end

--- Get all lines from buffer
--- @param bufnr? number Buffer number (defaults to current)
--- @return string
M.get_buffer_lines = function(bufnr)
	local resolved_bufnr = bufnr or 0

	if not vim.api.nvim_buf_is_valid(resolved_bufnr) or not vim.api.nvim_buf_is_loaded(resolved_bufnr) then
		return ""
	end

	local lines = vim.api.nvim_buf_get_lines(resolved_bufnr, 0, -1, false)
	return table.concat(lines, "\n")
end

--- Find the config file by recursively searching up the directory tree and stopping at the home directory
--- @param file string The current file name
--- @param possible_config_files string[] The name of the config file to 100search for
--- @return string|nil The path to the config file or nil if not found
M.find_config_file = function(file, possible_config_files)
	if file == nil or file == "" then
		return nil
	end

	local start_dir = vim.fs.dirname(file)
	local home = vim.fn.expand("~")

	if start_dir == nil or start_dir == "" then
		return nil
	end

	local found = vim.fs.find(function(name)
		return vim.tbl_contains(possible_config_files, name)
	end, { path = start_dir, stop = home, type = "file", upward = true })

	return #found > 0 and found[1] or nil
end

--- Run a command and wait for it to complete.
--- @param argv string[]
--- @param stdin string
--- @return vim.SystemCompleted
M.execute_command = function(argv, stdin)
	return vim.system(argv, { stdin = stdin, text = true }):wait()
end

--- Format a user-facing success message.
--- @param bufnr number
--- @param config_path string|nil
--- @return string
M.format_success_message = function(bufnr, config_path)
	local message = "Formatted buffer " .. bufnr .. " successfully."
	if config_path then
		local pretty_config_path = config_path:gsub(vim.fn.expand("~"), "~")
		message = message .. " (config: " .. pretty_config_path .. ")"
	end
	return message
end

--- @class CommandOptions
---@field buf number Buffer number
---@field argv string[] Command and arguments to run
---@field stdin string Input to pass to the command
---@field config string|nil Path to the config file if found
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
		M.notify("Command failed (exit " .. result.code .. "): " .. error_output, "error")
		return
	end

	if result.stdout == nil or result.stdout == "" then
		M.notify("Formatter produced no output; buffer unchanged.", "warn")
		return
	end

	if vim.api.nvim_buf_get_changedtick(options.buf) ~= initial_changedtick then
		M.notify("Buffer changed during formatting; results discarded.", "warn")
		return
	end

	local formatted_lines = vim.split(result.stdout, "\n", { plain = true, trimempty = true })
	local marklist = collect_marks(options.buf)
	local view_state = capture_view(options.buf)
	M.preserve_debug_breakpoints(options.buf, function()
		vim.api.nvim_buf_set_lines(options.buf, 0, -1, false, formatted_lines)
	end)
	restore_view(view_state)
	if #marklist > 0 then
		restore_marks(options.buf, marklist)
	end

	local success_message = M.format_success_message(options.buf, options.config)
	M.notify(success_message, "info")
end

--- Filter a list of filetypes by a disable list.
--- @param filetypes string[]
--- @param disable_filetypes? string[]
--- @return string[]
M.filter_filetypes = function(filetypes, disable_filetypes)
	if not disable_filetypes or #disable_filetypes == 0 then
		return filetypes
	end

	return vim.tbl_filter(function(filetype)
		return not vim.tbl_contains(disable_filetypes, filetype)
	end, filetypes)
end

return M
