local notify_utils = require("abide.utils.notify")

local M = {}

--- Resolve the best directory to start upward file searches from.
--- @param file string|nil File or directory path
--- @return string|nil
local function get_search_start_dir(file)
	local path = file
	if path == nil or path == "" then
		path = vim.fn.getcwd()
	end

	local stat = vim.uv.fs_stat(path)
	if stat and stat.type == "file" then
		path = vim.fs.dirname(path)
	end

	if path == nil or path == "" then
		return nil
	end

	return path
end

--- Find the first matching file by searching upward from a directory.
--- @param start_dir string|nil
--- @param candidates string[]
--- @return string|nil
local function find_upward_candidate(start_dir, candidates)
	if start_dir == nil or start_dir == "" then
		return nil
	end

	for _, candidate in ipairs(candidates) do
		local found = vim.fs.find(candidate, { path = start_dir, upward = true, type = "file" })
		if #found > 0 then
			return found[1]
		end
	end

	return nil
end

--- Check if an executable is available in the system PATH.
--- @return boolean
M.check_executable = function(exe)
	return vim.fn.executable(exe) == 1
end

--- Resolve an executable by checking local candidates first, then global.
--- @param global_exe string Global executable name or path
--- @param starting_file string|nil File path used as the lookup starting point
--- @param candidates? string[]|nil Candidate files to search upward from `starting_file`
--- @return string|nil Resolved executable path or command
M.get_executable = function(global_exe, starting_file, candidates)
	local starting_dir = get_search_start_dir(starting_file)
	local local_executable = find_upward_candidate(starting_dir, candidates or {})
	if local_executable then
		return local_executable
	end

	if global_exe and M.check_executable(global_exe) then
		return global_exe
	end

	notify_utils.notify("Executable '" .. global_exe .. "' not found in PATH.", "error")
	return nil
end

return M
