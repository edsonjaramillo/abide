local M = {}

--- Find the config file by recursively searching up the directory tree and stopping at the home directory
--- @param file string The current file name
--- @param possible_config_files string[] The names of config files to search for
--- @return string|nil The path to the config file or nil if not found
M.find_config_file = function(file, possible_config_files)
	-- Guard against invalid file input.
	if type(file) ~= "string" or file == "" then
		return nil
	end

	-- Guard against missing/empty config candidates.
	if type(possible_config_files) ~= "table" or #possible_config_files == 0 then
		return nil
	end

	-- Normalize paths and pick a search start directory.
	-- If `file` is a directory, search from it; otherwise search from its parent.
	local normalized_file = vim.fs.normalize(file)
	local stat = vim.uv.fs_stat(normalized_file) or nil
	local start_dir = stat and stat.type == "directory" and normalized_file or vim.fs.dirname(normalized_file)
	local home = vim.fs.normalize(vim.fn.expand("~"))

	-- Abort when we cannot determine a valid starting directory.
	if start_dir == nil or start_dir == "" then
		return nil
	end

	-- Build a fast lookup table of valid config file names.
	local config_name_lookup = {}
	for _, name in ipairs(possible_config_files) do
		if type(name) == "string" and name ~= "" then
			config_name_lookup[name] = true
		end
	end

	-- Abort if all provided names were invalid/empty.
	if vim.tbl_isempty(config_name_lookup) then
		return nil
	end

	-- Search upward until `home`, then return the first matching file.
	local found = vim.fs.find(function(name)
		return config_name_lookup[name] == true
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
