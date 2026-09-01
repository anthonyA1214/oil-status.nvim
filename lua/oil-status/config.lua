local M = {}

local constants = require("oil-status.constants")

local default_config = {
	debug = false,
	git = {
		debounce_ms = constants.DEFAULTS.DEBOUNCE_MS,
		show_file_highlights = true,
		show_directory_highlights = true,
		show_file_symbols = true,
		show_directory_symbols = true,
		show_ignored_files = false,
		show_ignored_directories = false,
		show_branch = false,
		branch_format = " %s",
		symbol_position = "eol",
		can_use_signcolumn = nil,
		ignore_gitsigns_update = false,
		symbols = {
			file = {
				added = "+",
				modified = "~",
				renamed = "->",
				deleted = "D",
				copied = "C",
				conflict = "!",
				untracked = "?",
				ignored = "o",
			},
			directory = {
				added = "*",
				modified = "*",
				renamed = "*",
				deleted = "*",
				copied = "*",
				conflict = "!",
				untracked = "*",
				ignored = "o",
			},
		},
		highlights = {
			OilStatusAdded = { fg = "#a6e3a1" },
			OilStatusModified = { fg = "#f9e2af" },
			OilStatusModifiedStaged = { fg = "#f9e2af" },
			OilStatusModifiedUnstaged = { fg = "#e5c890" },
			OilStatusBranch = { fg = "#89b4fa" },
			OilStatusRenamed = { fg = "#cba6f7" },
			OilStatusUntracked = { fg = "#89b4fa" },
			OilStatusIgnored = { fg = "#6c7086" },
			OilStatusDeleted = { fg = "#f38ba8" },
			OilStatusConflict = { fg = "#fab387" },
			OilStatusCopied = { fg = "#cba6f7" },
		},
	},
	diagnostics = {
		enabled = true,
		count = false,
		parent_dirs = true,
		filename_highlight = false,
		only_highest_severity = true,
		colors = {
			error = "DiagnosticError",
			warn = "DiagnosticWarn",
			info = "DiagnosticInfo",
			hint = "DiagnosticHint",
		},
		symbols = {
			error = "",
			warn = "",
			info = "",
			hint = "󰌶",
		},
	},
}

local config = {}

local function apply_legacy_modified_highlights(opts, merged_config)
	local user_highlights = (opts.git and opts.git.highlights)
		or opts.highlights
		or {}
	local legacy_modified = user_highlights.OilStatusModified

	if not legacy_modified then
		return
	end

	if not user_highlights.OilStatusModifiedStaged then
		merged_config.git.highlights.OilStatusModifiedStaged =
			vim.deepcopy(legacy_modified)
	end

	if not user_highlights.OilStatusModifiedUnstaged then
		merged_config.git.highlights.OilStatusModifiedUnstaged =
			vim.deepcopy(legacy_modified)
	end

	merged_config.git.highlights.OilStatusModified =
		vim.deepcopy(legacy_modified)
end

local function make_readonly(t)
	if type(t) ~= "table" then
		return t
	end

	local proxy = {}
	local mt = {
		__index = function(_, k)
			return make_readonly(t[k])
		end,
		__newindex = function()
			error("Attempt to modify read-only config", 2)
		end,
		__pairs = function()
			return function(_, k)
				local nk, nv = next(t, k)
				if nv ~= nil then
					return nk, make_readonly(nv)
				end
			end,
				nil,
				nil
		end,
		__len = function()
			return #t
		end,
	}
	return setmetatable(proxy, mt)
end

function M.setup(opts)
	opts = opts or {}
	local normalized_opts = {
		debug = opts.debug,
		git = vim.deepcopy(opts.git or {}),
		diagnostics = vim.deepcopy(opts.diagnostics or {}),
	}

	for k, v in pairs(opts) do
		if k ~= "debug" and k ~= "git" and k ~= "diagnostics" then
			if normalized_opts.git[k] == nil then
				normalized_opts.git[k] = v
			end
		end
	end

	config = vim.tbl_deep_extend("force", default_config, normalized_opts)
	apply_legacy_modified_highlights(opts, config)
end

function M.get()
	return make_readonly(config)
end

function M.get_raw()
	return config
end

function M.ensure()
	if vim.tbl_isempty(config) then
		config = vim.tbl_deep_extend("force", {}, default_config)
	end
end

return M
