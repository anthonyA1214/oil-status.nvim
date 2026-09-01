if vim.g.loaded_oil_status then
	return
end
vim.g.loaded_oil_status = true

local group = vim.api.nvim_create_augroup("OilStatusAutoInit", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
	group = group,
	pattern = "oil",
	callback = function()
		local ok, oil_status = pcall(require, "oil-status")
		if not ok then
			return
		end

		local success = oil_status.init()
		if success then
			vim.schedule(function()
				require("oil-status.highlights").apply_debounced()
			end)
		end
	end,
})

vim.api.nvim_create_autocmd("VimEnter", {
	group = group,
	once = true,
	callback = function()
		vim.schedule(function()
			if vim.bo.filetype == "oil" then
				local ok, oil_status = pcall(require, "oil-status")
				if ok then
					oil_status.init()
				end
			end
		end)
	end,
})
