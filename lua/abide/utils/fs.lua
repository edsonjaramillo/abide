local M = {}
local notify_utils = require("abide.utils.notify")

--- Check if an executable is available in PATH
--- @param executable string Optional custom executable name
--- @return boolean
M.check_executable = function(executable)
	if executable == nil or executable == "" then
		notify_utils.notify("Executable name is required.", "error")
		return false
	end

	if vim.fn.executable(executable) == 0 then
		notify_utils.notify("Executable '" .. executable .. "' not found in PATH.", "error")
		return false
	end

	return true
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
