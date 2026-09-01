local M = {}

local function get_buf_from_path(path)
	local bufs = vim.api.nvim_list_bufs()
	for _, buf in ipairs(bufs) do
		local name = vim.api.nvim_buf_get_name(buf)
		if name == path then
			return buf
		end
	end
	return nil
end

local function get_diagnostics_summary(buffer_or_dir, is_dir)
	local severities = { error = 0, warn = 0, info = 0, hint = 0 }

	local diagnostic_getter
	if is_dir then
		local dir = buffer_or_dir
		if type(dir) == "string" and not vim.endswith(dir, "/") then
			dir = dir .. "/"
		end

		diagnostic_getter = function(buf)
			return vim.startswith(vim.api.nvim_buf_get_name(buf), dir)
		end
	elseif type(buffer_or_dir) == "number" then
		diagnostic_getter = function(buf)
			return buf == buffer_or_dir
		end
	else
		diagnostic_getter = function(buf)
			return vim.api.nvim_buf_get_name(buf) == buffer_or_dir
		end
	end

	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if diagnostic_getter(buf) then
			for key, _ in pairs(severities) do
				severities[key] = severities[key]
					+ #vim.diagnostic.get(buf, {
						severity = vim.diagnostic.severity[string.upper(key)],
					})
			end
		end
	end

	return severities
end

local function get_highest_severity(diagnostics)
	if not diagnostics then
		return nil
	end

	for _, key in ipairs({ "error", "warn", "info", "hint" }) do
		if diagnostics[key] and diagnostics[key] > 0 then
			return key
		end
	end

	return nil
end

local function get_entry_diagnostics(entry, dir, is_dir, cfg)
	if is_dir then
		if not cfg.parent_dirs then
			return nil
		end
		return get_diagnostics_summary(dir .. entry.name .. "/", true)
	end

	local file_path = dir .. entry.name
	local file_buf = get_buf_from_path(file_path)
	if file_buf then
		return get_diagnostics_summary(file_buf, false)
	end
	return get_diagnostics_summary(file_path, false)
end

function M.get_virt_text(entry, dir, is_dir, cfg)
	if not cfg.enabled or not entry then
		return nil
	end

	local diagnostics = get_entry_diagnostics(entry, dir, is_dir, cfg)
	if not diagnostics then
		return nil
	end

	local severities_to_show
	if cfg.only_highest_severity then
		local highest = get_highest_severity(diagnostics)
		if highest then
			severities_to_show = { highest }
		else
			severities_to_show = {}
		end
	else
		severities_to_show = { "error", "warn", "info", "hint" }
	end

	local virt_text = {}
	for _, key in ipairs(severities_to_show) do
		local count = diagnostics[key]
		if count and count > 0 then
			local color = cfg.colors[key]
			local symbol = cfg.symbols[key]
			local text = cfg.count and (count .. symbol) or symbol
			table.insert(virt_text, { text .. "  ", color })
		end
	end

	if #virt_text == 0 then
		return nil
	end

	return virt_text
end

function M.get_filename_highlight(entry, dir, is_dir, cfg)
	if not cfg.enabled or not cfg.filename_highlight or not entry then
		return nil
	end

	local diagnostics = get_entry_diagnostics(entry, dir, is_dir, cfg)
	local highest = get_highest_severity(diagnostics)
	if not highest then
		return nil
	end

	return cfg.colors[highest]
end

return M
