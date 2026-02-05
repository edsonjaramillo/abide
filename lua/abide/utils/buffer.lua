local M = {}

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

	local restore_view_state = nil
	local viewoptions = nil
	local buffer_name = vim.api.nvim_buf_get_name(bufnr)

	vim.api.nvim_win_call(winid, function()
		restore_view_state = vim.fn.winsaveview()
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
		restore_view = restore_view_state,
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

--- Get all lines from buffer.
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

--- Apply formatter output while preserving view, marks, and debug breakpoints.
--- @param bufnr number
--- @param formatted_lines string[]
M.apply_formatted_lines = function(bufnr, formatted_lines)
	local marklist = collect_marks(bufnr)
	local view_state = capture_view(bufnr)
	M.preserve_debug_breakpoints(bufnr, function()
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, formatted_lines)
	end)
	restore_view(view_state)
	if #marklist > 0 then
		restore_marks(bufnr, marklist)
	end
end

return M
