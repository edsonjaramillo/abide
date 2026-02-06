local M = {}

---@alias FallbackMode "auto"|"never"|"always"

---@class FallbackResolution
---@field should_format boolean
---@field use_fallback boolean
---@field config string|nil
---@field mode "config"|"fallback"|"skipped"

--- Resolve whether formatting should run and which mode to use.
--- @param fallback_mode FallbackMode|nil
--- @param config_path string|nil
--- @return FallbackResolution
M.resolve = function(fallback_mode, config_path)
	local mode = fallback_mode
	if mode ~= "auto" and mode ~= "never" and mode ~= "always" then
		mode = "auto"
	end

	if mode == "always" then
		-- Force formatter default behavior regardless of discovered config.
		return {
			should_format = true,
			use_fallback = true,
			config = nil,
			mode = "fallback",
		}
	end

	if config_path then
		-- Config exists, so run in config-driven mode.
		return {
			should_format = true,
			use_fallback = false,
			config = config_path,
			mode = "config",
		}
	end

	if mode == "never" then
		-- Caller opted out of formatting when no config is available.
		return {
			should_format = false,
			use_fallback = false,
			config = nil,
			mode = "skipped",
		}
	end

	-- Default auto behavior: no config found, run formatter fallback mode.
	return {
		should_format = true,
		use_fallback = true,
		config = nil,
		mode = "fallback",
	}
end

return M
