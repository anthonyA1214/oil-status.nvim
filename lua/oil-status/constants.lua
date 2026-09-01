local M = {}

M.NAMESPACES = {
	PREFIX = "oil_status_status_",
}

M.DEFAULTS = {
	DEBOUNCE_MS = 50,
}

M.HIGHLIGHT_GROUPS = {
	ADDED = "OilStatusAdded",
	MODIFIED = "OilStatusModified",
	MODIFIED_STAGED = "OilStatusModifiedStaged",
	MODIFIED_UNSTAGED = "OilStatusModifiedUnstaged",
	BRANCH = "OilStatusBranch",
	RENAMED = "OilStatusRenamed",
	DELETED = "OilStatusDeleted",
	COPIED = "OilStatusCopied",
	CONFLICT = "OilStatusConflict",
	UNTRACKED = "OilStatusUntracked",
	IGNORED = "OilStatusIgnored",
}

M.GIT_STATUS = {
	UNTRACKED = "??",
	IGNORED = "!!",
}

M.ENTRY_TYPES = {
	FILE = "file",
	DIRECTORY = "directory",
}

M.SYMBOL_POSITIONS = {
	EOL = "eol",
	SIGNCOLUMN = "signcolumn",
	NONE = "none",
}

M.PRIORITY = {
	NONE = 0,
	IGNORED = 1,
	UNTRACKED = 2,
	RENAMED = 3,
	COPIED = 3,
	ADDED = 4,
	DELETED = 5,
	MODIFIED_UNSTAGED = 6,
	MODIFIED_STAGED = 7,
	MODIFIED = 7,
	CONFLICT = 8,
}

return M
