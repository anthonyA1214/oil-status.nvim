describe("config", function()
	local config

	before_each(function()
		package.loaded["oil-status.config"] = nil
		config = require("oil-status.config")
	end)

	describe("setup", function()
		it("should accept nil and empty opts", function()
			assert.has_no.errors(function()
				config.setup(nil)
			end)
			package.loaded["oil-status.config"] = nil
			config = require("oil-status.config")
			assert.has_no.errors(function()
				config.setup({})
			end)
		end)

		it("should merge user options with defaults", function()
			config.setup({ debounce_ms = 100 })
			local cfg = config.get()
			assert.equals(100, cfg.git.debounce_ms)
			assert.is_true(cfg.git.show_file_highlights)
		end)

		it("should override boolean and string defaults", function()
			config.setup({
				show_file_highlights = false,
				show_directory_highlights = false,
				show_file_symbols = false,
				show_directory_symbols = false,
				show_ignored_files = true,
				show_ignored_directories = true,
				show_branch = true,
				branch_format = "branch:%s",
				symbol_position = "signcolumn",
			})
			local cfg = config.get()
			assert.is_false(cfg.git.show_file_highlights)
			assert.is_false(cfg.git.show_directory_highlights)
			assert.is_false(cfg.git.show_file_symbols)
			assert.is_false(cfg.git.show_directory_symbols)
			assert.is_true(cfg.git.show_ignored_files)
			assert.is_true(cfg.git.show_ignored_directories)
			assert.is_true(cfg.git.show_branch)
			assert.equals("branch:%s", cfg.git.branch_format)
			assert.equals("signcolumn", cfg.git.symbol_position)
		end)

		it("should deep merge nested options", function()
			config.setup({
				symbols = {
					file = { added = "A" },
				},
				highlights = {
					OilStatusAdded = { fg = "#ffffff" },
				},
			})
			local cfg = config.get()
			assert.equals("A", cfg.git.symbols.file.added)
			assert.equals("~", cfg.git.symbols.file.modified)
			assert.equals("*", cfg.git.symbols.directory.added)
			assert.equals("#ffffff", cfg.git.highlights.OilStatusAdded.fg)
			assert.is_not_nil(cfg.git.highlights.OilStatusModified)
			assert.is_not_nil(cfg.git.highlights.OilStatusModifiedStaged)
			assert.is_not_nil(cfg.git.highlights.OilStatusModifiedUnstaged)
		end)

		it(
			"should apply legacy modified highlight to both new groups",
			function()
				config.setup({
					highlights = {
						OilStatusModified = { fg = "#111111" },
					},
				})
				local cfg = config.get()

				assert.equals("#111111", cfg.git.highlights.OilStatusModified.fg)
				assert.equals("#111111", cfg.git.highlights.OilStatusModifiedStaged.fg)
				assert.equals(
					"#111111",
					cfg.git.highlights.OilStatusModifiedUnstaged.fg
				)
			end
		)

		it("should handle debug option", function()
			config.setup({ debug = "verbose" })
			local cfg = config.get()
			assert.equals("verbose", cfg.debug)
		end)

		it("should handle ignore_gitsigns_update option", function()
			config.setup({ ignore_gitsigns_update = true })
			local cfg = config.get()
			assert.is_true(cfg.git.ignore_gitsigns_update)
		end)
	end)

	describe("get", function()
		it("should return readonly config", function()
			config.setup({})
			local cfg = config.get()
			assert.has_error(function()
				cfg.git.debounce_ms = 999
			end, "Attempt to modify read-only config")
		end)

		it("should make nested tables readonly", function()
			config.setup({})
			local cfg = config.get()
			assert.has_error(function()
				cfg.git.symbols.file.added = "X"
			end, "Attempt to modify read-only config")
			assert.has_error(function()
				cfg.git.highlights.OilStatusAdded.fg = "#000000"
			end, "Attempt to modify read-only config")
		end)

		it("should return consistent values and handle nil keys", function()
			config.setup({ debounce_ms = 123 })
			local cfg1 = config.get()
			local cfg2 = config.get()
			assert.equals(cfg1.git.debounce_ms, cfg2.git.debounce_ms)
			assert.is_nil(cfg1.git.nonexistent_key)
		end)
	end)

	describe("ensure", function()
		it("should populate empty config with defaults", function()
			config.ensure()
			local cfg = config.get()
			assert.equals(50, cfg.git.debounce_ms)
			assert.is_true(cfg.git.show_file_symbols)
		end)

		it("should not overwrite existing config", function()
			config.setup({ debounce_ms = 200 })
			config.ensure()
			local cfg = config.get()
			assert.equals(200, cfg.git.debounce_ms)
		end)
	end)

	describe("default values", function()
		it("should have all required default values", function()
			config.setup({})
			local cfg = config.get()

			assert.equals(50, cfg.git.debounce_ms)
			assert.is_true(cfg.git.show_file_highlights)
			assert.is_true(cfg.git.show_directory_highlights)
			assert.is_true(cfg.git.show_file_symbols)
			assert.is_true(cfg.git.show_directory_symbols)
			assert.is_false(cfg.git.show_ignored_files)
			assert.is_false(cfg.git.show_ignored_directories)
			assert.is_false(cfg.git.show_branch)
			assert.equals(" %s", cfg.git.branch_format)
			assert.equals("eol", cfg.git.symbol_position)
			assert.is_nil(cfg.git.can_use_signcolumn)
			assert.is_false(cfg.git.ignore_gitsigns_update)
			assert.is_false(cfg.debug)

			assert.is_table(cfg.git.symbols.file)
			assert.is_table(cfg.git.symbols.directory)
			assert.is_table(cfg.git.highlights)
		end)

		it("should have all file and directory symbols", function()
			config.setup({})
			local cfg = config.get()

			local expected_file = {
				added = "+",
				modified = "~",
				renamed = "->",
				deleted = "D",
				copied = "C",
				conflict = "!",
				untracked = "?",
				ignored = "o",
			}
			for k, v in pairs(expected_file) do
				assert.equals(v, cfg.git.symbols.file[k], "file." .. k)
			end

			assert.equals("*", cfg.git.symbols.directory.added)
			assert.equals("!", cfg.git.symbols.directory.conflict)
			assert.equals("o", cfg.git.symbols.directory.ignored)
		end)

		it("should have all highlight groups with valid fg colors", function()
			config.setup({})
			local cfg = config.get()

			local expected_groups = {
				"OilStatusAdded",
				"OilStatusModified",
				"OilStatusModifiedStaged",
				"OilStatusModifiedUnstaged",
				"OilStatusBranch",
				"OilStatusRenamed",
				"OilStatusDeleted",
				"OilStatusCopied",
				"OilStatusConflict",
				"OilStatusUntracked",
				"OilStatusIgnored",
			}
			for _, name in ipairs(expected_groups) do
				assert.is_table(cfg.git.highlights[name], name .. " missing")
				assert.matches(
					"^#%x%x%x%x%x%x$",
					cfg.git.highlights[name].fg,
					name .. " fg"
				)
			end
		end)
	end)
end)
