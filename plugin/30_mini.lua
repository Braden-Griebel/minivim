-- Mini Configuration

-- This file contains configuration of the MINI parts of the config.
-- It contains only configs for the 'mini.nvim' plugin (installed in 'init.lua').
--
-- To minimize the time until first screen draw, modules are enabled in two steps:
-- - Step one enables everything that is needed for first draw with `now()`.
--   Sometimes is needed only if Neovim is started as `nvim -- path/to/file`.
-- - Everything else is delayed until the first draw with `later()`.
local add, now, later, now_if_args = vim.pack.add, Config.now, Config.later, Config.now_if_args

-- Step one ===================================================================
-- Set colorscheme
now(function()
	vim.cmd("colorscheme " .. Config.colorscheme)
end)

-- Basics
now(function()
	require("mini.basics").setup({
		-- Manage options in 'plugin/10_options.lua' for didactic purposes
		options = { basic = false },
		mappings = {
			-- Create `<C-hjkl>` mappings for window navigation
			windows = true,
			-- Create `<M-hjkl>` mappings for navigation in Insert and Command modes
			move_with_alt = true,
		},
	})
end)

-- Icons
now(function()
	-- Set up to not prefer extension-based icon for some extensions
	local ext3_blocklist = { scm = true, txt = true, yml = true }
	local ext4_blocklist = { json = true, yaml = true }
	require("mini.icons").setup({
		use_file_extension = function(ext, _)
			return not (ext3_blocklist[ext:sub(-3)] or ext4_blocklist[ext:sub(-4)])
		end,
	})

	-- Mock 'nvim-tree/nvim-web-devicons' for plugins without 'mini.icons' support.
	later(MiniIcons.mock_nvim_web_devicons)

	-- Add LSP kind icons. Useful for 'mini.completion'.
	later(MiniIcons.tweak_lsp_kind)
end)

-- Misc
now_if_args(function()
	-- Makes `:h MiniMisc.put()` and `:h MiniMisc.put_text()` public
	require("mini.misc").setup()

	-- Change current working directory based on the current file path. It
	-- searches up the file tree until the first root marker ('.git' or 'Makefile')
	-- and sets their parent directory as a current directory.
	-- This is helpful when simultaneously dealing with files from several projects.
	MiniMisc.setup_auto_root()

	-- Restore latest cursor position on file open
	MiniMisc.setup_restore_cursor()

	-- Synchronize terminal emulator background with Neovim's background to remove
	-- possibly different color padding around Neovim instance
	-- MiniMisc.setup_termbg_sync() -- Fails frequently
end)

-- Notify
now(function()
	require("mini.notify").setup({
		lsp_progress = { enable = false }, -- Prefer fidget for this
	})
	-- Keymap for showing history
	vim.keymap.set("n", "<leader>oh", function()
		MiniNotify.show_history()
	end, { desc = "Show Notification History" })
end)

-- Sessions
now(function()
	require("mini.sessions").setup()
end)

-- Starter
-- Add fortune.nvim
now(function()
	add({ { src = "https://github.com/rubiin/fortune.nvim", version = "master" } })
	require("fortune").setup({
		max_width = 60,
		display_format = "mixed",
		content_type = "quotes",
		language = "en",
	})
end)

-- Using Oil instead of Mini Files
-- Oil.nvim ============================================================
-- Declare a global function to retrieve the current directory
function _G.get_oil_winbar()
	local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
	local dir = require("oil").get_current_dir(bufnr)
	if dir then
		return vim.fn.fnamemodify(dir, ":~")
	else
		-- If there is no current directory (e.g. over ssh), just show the buffer name
		return vim.api.nvim_buf_get_name(0)
	end
end
now(function()
	add({ "https://github.com/stevearc/oil.nvim" })
	local detail = false
	require("oil").setup({
		keymaps = {
			["gd"] = {
				desc = "Toggle file detail view",
				callback = function()
					detail = not detail
					if detail then
						require("oil").set_columns({ "icon", "permissions", "size", "mtime" })
					else
						require("oil").set_columns({ "icon" })
					end
				end,
			},
		},
		win_options = {
			winbar = "%!v:lua.get_oil_winbar()",
		},
	})
	vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
end)
later(function()
	add({ "https://github.com/malewicz1337/oil-git.nvim" })
	require("oil-git").setup({})
	add({ "https://github.com/JezerM/oil-lsp-diagnostics.nvim" })
	require("oil-lsp-diagnostics").setup({})
end)

now(function()
	local oil = require("oil")
	local starter = require("mini.starter")
	require("mini.starter").setup({
		header = require("random-picture").get_random_image(),
		footer = table.concat(require("fortune").get_fortune(), "\n"),
		items = {
			{ name = "Files", action = "Pick files", section = "Pick" },
			{ name = "Grep", action = "Pick grep_live", section = "Pick" },
			{
				name = "Current",
				action = function()
					oil.open()
				end,
				section = "Explore",
			},
			{
				name = "Root",
				action = function()
					oil.open(require("path_utils").find_git_root())
				end,
				section = "Explore",
			},
			starter.sections.sessions(5, true),
			starter.sections.recent_files(5, false, false),
			starter.sections.builtin_actions(),
		},
	})
end)

-- Deps
Config.nmap_leader("pu", function()
	vim.pack.update()
end, "Update")

-- Status Line
now(function()
	local MiniStatusline = require("mini.statusline")
	local statusline_func = function()
		local get_visual_count = function()
			if vim.fn.mode():find("[vV]") then
				return string.format("[%d]", vim.fn.wordcount().visual_chars)
			end
			return ""
		end
		local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
		local git = MiniStatusline.section_git({ trunc_width = 40 })
		local diff = MiniStatusline.section_diff({ trunc_width = 75 })
		local diagnostics = MiniStatusline.section_diagnostics({ trunc_width = 75 })
		local lsp = MiniStatusline.section_lsp({ trunc_width = 75 })
		local filename = MiniStatusline.section_filename({ trunc_width = 140 })
		local fileinfo = MiniStatusline.section_fileinfo({ trunc_width = 120 })
		local location = MiniStatusline.section_location({ trunc_width = 75 })
		local selected = get_visual_count()
		local search = MiniStatusline.section_searchcount({ trunc_width = 75 })

		return MiniStatusline.combine_groups({
			{ hl = mode_hl, strings = { mode } },
			{ hl = "MiniStatuslineDevinfo", strings = { git, diff, diagnostics, lsp } },
			"%<", -- Mark general truncate point
			{ hl = "MiniStatuslineFilename", strings = { filename } },
			"%=", -- End left alignment
			{ hl = "MiniStatuslineFileinfo", strings = { fileinfo } },
			{ hl = mode_hl, strings = { search, selected, location } },
		})
	end

	MiniStatusline.setup({ content = { active = statusline_func } })
end)

-- Tabline/Bufferline
now(function()
	require("mini.tabline").setup()
end)

-- ========= Later ==============
-- Extras
later(function()
	require("mini.extra").setup()
end)

-- ai
later(function()
	local ai = require("mini.ai")
	ai.setup({
		custom_textobjects = {
			-- Make Buffer Object
			B = MiniExtra.gen_ai_spec.buffer(),
			-- Make Function object
			F = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
		},
		-- Increase the number of lines searched
		n_lines = 150,

		search_method = "cover",
	})
end)

-- Align
later(function()
	require("mini.align").setup()
end)

-- Bracketed (Move forward backward with brackets)
later(function()
	require("mini.bracketed").setup()
end)

-- Bufremove (Remove buffers without messing up window layout)
later(function()
	require("mini.bufremove").setup()
end)

-- Clue (which-key functionality)
later(function()
	local miniclue = require("mini.clue")
	miniclue.setup({
		-- Define which clues to show. By default shows only clues for custom mappings
		-- (uses `desc` field from the mapping; takes precedence over custom clue).
		clues = {
			-- This is defined in 'plugin/20_keymaps.lua' with Leader group descriptions
			Config.leader_group_clues,
			{ mode = "n", keys = "gz", desc = "Slime" },
			{ mode = "n", keys = "\\v", desc = "Toggle Virtual" },
			{ mode = "n", keys = "<leader>c", desc = "+Multicursor" },
			{ mode = "n", keys = "<leader>d", desc = "+Debug" },
			{ mode = "n", keys = "<leader>n", desc = "+Neotest" },
			{ mode = "n", keys = "<leader>p", desc = "+Packages" },
			{ mode = "n", keys = "<leader>q", desc = "+Quarto" },
			{ mode = "n", keys = "<leader>r", desc = "+Repl" },
			{ mode = "x", keys = "<leader>r", desc = "+Repl" },
			{ mode = "n", keys = "<leader>T", desc = "+Tasks" },
			miniclue.gen_clues.builtin_completion(),
			miniclue.gen_clues.g(),
			miniclue.gen_clues.marks(),
			miniclue.gen_clues.registers(),
			miniclue.gen_clues.windows({ submode_resize = true }),
			miniclue.gen_clues.z(),
		},
		-- Explicitly opt-in for set of common keys to trigger clue window
		triggers = {
			{ mode = "n", keys = "<Leader>" }, -- Leader triggers
			{ mode = "x", keys = "<Leader>" },
			{ mode = "n", keys = "<localleader" },
			{ mode = "x", keys = "<localleader>" },
			{ mode = "i", keys = "<localleader>" },
			{ mode = "n", keys = "\\" }, -- mini.basics
			{ mode = "n", keys = "[" }, -- mini.bracketed
			{ mode = "n", keys = "]" },
			{ mode = "x", keys = "[" },
			{ mode = "x", keys = "]" },
			{ mode = "i", keys = "<C-x>" }, -- Built-in completion
			{ mode = "n", keys = "g" }, -- `g` key
			{ mode = "x", keys = "g" },
			{ mode = "n", keys = "'" }, -- Marks
			{ mode = "n", keys = "`" },
			{ mode = "x", keys = "'" },
			{ mode = "x", keys = "`" },
			{ mode = "n", keys = '"' }, -- Registers
			{ mode = "x", keys = '"' },
			{ mode = "i", keys = "<C-r>" },
			{ mode = "c", keys = "<C-r>" },
			{ mode = "n", keys = "<C-w>" }, -- Window commands
			{ mode = "n", keys = "z" }, -- `z` key
			{ mode = "x", keys = "z" },
			{ mode = "n", keys = "s" }, -- For mini surround
		},
		window = {
			delay = 250,
			config = { width = "auto" },
		},
	})
end)

-- Cmdline
later(function()
	require("mini.cmdline").setup()
end)

-- Comment
later(function()
	require("mini.comment").setup()
end)

-- Autohighlight
later(function()
	require("mini.cursorword").setup()
end)

-- Diff
later(function()
	require("mini.diff").setup()
end)

-- Git
later(function()
	require("mini.git").setup()
end)

-- Highlight
later(function()
	local hipatterns = require("mini.hipatterns")
	local hi_words = MiniExtra.gen_highlighter.words
	hipatterns.setup({
		highlighters = {
			-- Highlight a fixed set of common words. Will be highlighted in any place,
			-- not like "only in comments".
			fixme = hi_words({ "FIXME:", "Fixme:", "fixme:" }, "MiniHipatternsFixme"),
			hack = hi_words({ "HACK:", "Hack:", "hack:" }, "MiniHipatternsHack"),
			todo = hi_words({ "TODO:", "Todo:", "todo:" }, "MiniHipatternsTodo"),
			note = hi_words({ "NOTE:", "Note:", "note:" }, "MiniHipatternsNote"),

			-- Highlight hex color string (#aabbcc) with that color as a background
			hex_color = hipatterns.gen_highlighter.hex_color(),
		},
	})
end)

-- Animate
later(function()
	require("mini.animate").setup()
end)

-- Indent scope
-- Example usage:
-- - `cii` - *c*hange *i*nside *i*ndent scope
-- - `Vaiai` - *V*isually select *a*round *i*ndent scope and then again
--   reselect *a*round new *i*indent scope
-- - `[i` / `]i` - navigate to scope's top / bottom
later(function()
	require("mini.indentscope").setup()
end)

-- Keymap (Special keymap helpers)
later(function()
	require("mini.keymap").setup()
	-- Navigate 'mini.completion' menu with `<Tab>` /  `<S-Tab>`
	MiniKeymap.map_multistep("i", "<Tab>", { "pmenu_next" })
	MiniKeymap.map_multistep("i", "<S-Tab>", { "pmenu_prev" })
	-- On `<CR>` try to accept current completion item, fall back to accounting
	-- for pairs from 'mini.pairs'
	MiniKeymap.map_multistep("i", "<CR>", { "pmenu_accept", "minipairs_cr" })
	-- On `<BS>` just try to account for pairs from 'mini.pairs'
	MiniKeymap.map_multistep("i", "<BS>", { "minipairs_bs" })
end)

-- Map (Overview of current window)
later(function()
	local map = require("mini.map")
	map.setup({
		-- Use Braille dots to encode text
		symbols = { encode = map.gen_encode_symbols.dot("4x2") },
		-- Show built-in search matches, 'mini.diff' hunks, and diagnostic entries
		integrations = {
			map.gen_integration.builtin_search(),
			map.gen_integration.diff(),
			map.gen_integration.diagnostic(),
		},
	})

	-- Map built-in navigation characters to force map refresh
	for _, key in ipairs({ "n", "N", "*", "#" }) do
		local rhs = key
			-- Also open enough folds when jumping to the next match
			.. "zv"
			.. "<Cmd>lua MiniMap.refresh({}, { lines = false, scrollbar = false })<CR>"
		vim.keymap.set("n", key, rhs)
	end
end)

-- Move (Selection moving)
-- Uses ALT for movement
later(function()
	require("mini.move").setup()
end)

-- Operators
later(function()
	require("mini.operators").setup()

	-- Create mappings for swapping adjacent arguments. Notes:
	-- - Relies on `a` argument textobject from 'mini.ai'.
	-- - It is not 100% reliable, but mostly works.
	-- - It overrides `:h (` and `:h )`.
	-- Explanation: `gx`-`ia`-`gx`-`ila` <=> exchange current and last argument
	-- Usage: when on `a` in `(aa, bb)` press `)` followed by `(`.
	vim.keymap.set("n", "(", "gxiagxila", { remap = true, desc = "Swap arg left" })
	vim.keymap.set("n", ")", "gxiagxina", { remap = true, desc = "Swap arg right" })
end)

-- Autopairs
later(function()
	-- Create pairs not only in Insert, but also in Command line mode
	require("mini.pairs").setup({ modes = { command = true } })
end)

-- Picker
later(function()
	local win_config = function()
		local height = math.floor(0.618 * vim.o.lines)
		local width = math.floor(0.618 * vim.o.columns)
		return {
			anchor = "NW",
			height = height,
			width = width,
			row = math.floor(0.5 * (vim.o.lines - height)),
			col = math.floor(0.5 * (vim.o.columns - width)),
		}
	end
	require("mini.pick").setup({ window = { config = win_config } })
end)

-- Snippets
later(function()
	-- Define language patterns to work better with 'friendly-snippets'
	local latex_patterns = { "latex/**/*.json", "**/latex.json" }
	local lang_patterns = {
		tex = latex_patterns,
		plaintex = latex_patterns,
		-- Recognize special injected language of markdown tree-sitter parser
		markdown_inline = { "markdown.json" },
	}

	local snippets = require("mini.snippets")
	local config_path = vim.fn.stdpath("config")
	snippets.setup({
		snippets = {
			-- Always load 'snippets/global.json' from config directory
			snippets.gen_loader.from_file(config_path .. "/snippets/global.json"),
			-- Load from 'snippets/' directory of plugins, like 'friendly-snippets'
			snippets.gen_loader.from_lang({ lang_patterns = lang_patterns }),
		},
	})

	-- Start LSP server to integrate with mini.completion
	MiniSnippets.start_lsp_server()
end)

-- Splitjoin
later(function()
	require("mini.splitjoin").setup()
end)

-- Surround
later(function()
	require("mini.surround").setup()
end)

-- Trailspace
later(function()
	require("mini.trailspace").setup()
end)

-- Visits
later(function()
	require("mini.visits").setup()
end)
