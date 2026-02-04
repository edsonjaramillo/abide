local M = {}

-- Creates a FileType autocmd that sets up a single buffer-local BufWritePre.
-- This avoids duplicate formatting hooks when FileType fires multiple times.
---@param patterns string[]
---@param callback fun(o: {buf: number, event: string, match: string, id: number, file: string})
M.New = function(patterns, callback)
	vim.api.nvim_create_autocmd("FileType", {
		pattern = patterns,
		callback = function(args)
			-- Guard against re-registering for the same buffer.
			if vim.b[args.buf].abide_bufwritepre_set then
				return
			end
			vim.b[args.buf].abide_bufwritepre_set = true
			vim.api.nvim_create_autocmd("BufWritePre", {
				-- Buffer-local so only the matching FileType gets the hook.
				buffer = args.buf,
				callback = callback,
			})
		end,
	})
end

return M
