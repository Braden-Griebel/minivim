-- Mini Configuration

-- This file contains configuration of the MINI parts of the config.
-- It contains only configs for the 'mini.nvim' plugin (installed in 'init.lua').
--
-- To minimize the time until first screen draw, modules are enabled in two steps:
-- - Step one enables everything that is needed for first draw with `now()`.
--   Sometimes is needed only if Neovim is started as `nvim -- path/to/file`.
-- - Everything else is delayed until the first draw with `later()`.
local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later
local now_if_args = _G.Config.now_if_args

-- Step one ===================================================================
-- Set rose-pine colorscheme (built using mini.base16)
now(function()
	vim.cmd("colorscheme " .. _G.Config.colorscheme)
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
	add({ source = "rubiin/fortune.nvim", checkout = "master" })
	require("fortune").setup({
		max_width = 60,
		display_format = "mixed",
		content_type = "quotes",
		language = "en",
	})
end)

now(function()
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
					MiniFiles.open()
				end,
				section = "Explore",
			},
			{
				name = "Root",
				action = function()
					MiniFiles.open(_G.find_git_root())
				end,
				section = "Explore",
			},
			starter.sections.sessions(5, true),
			starter.sections.recent_files(5, false, false),
			starter.sections.builtin_actions(),
		},
	})
end)

-- Files
-- Set to now so that it can replace netrw
now(function()
	-- Enable directory/file preview
	require("mini.files").setup({
		windows = { preview = true },
		-- options = { use_as_default_explorer = true },
	})

	-- Add common bookmarks for every explorer. Example usage inside explorer:
	-- - `'c` to navigate into your config directory
	-- - `g?` to see available bookmarks
	local add_marks = function()
		MiniFiles.set_bookmark("c", vim.fn.stdpath("config"), { desc = "Config" })
		local minideps_plugins = vim.fn.stdpath("data") .. "/site/pack/deps/opt"
		MiniFiles.set_bookmark("p", minideps_plugins, { desc = "Plugins" })
		MiniFiles.set_bookmark("w", vim.fn.getcwd, { desc = "Working directory" })
	end
	_G.Config.new_autocmd("User", "MiniFilesExplorerOpen", add_marks, "Add bookmarks")
end)

-- Status Line
now(function()
	require("mini.statusline").setup()
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
			{ mode = "n", keys = "<localleader>" },
			{ mode = "v", keys = "<localleader>" },
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

-- Comment
later(function()
	require("mini.comment").setup()
end)

-- Completion
later(function()
	-- Customize post-processing of LSP responses for a better user experience.
	-- Don't show 'Text' suggestions (usually noisy) and show snippets last.
	local process_items_opts = { kind_priority = { Text = -1, Snippet = 99 } }
	local process_items = function(items, base)
		return MiniCompletion.default_process_items(items, base, process_items_opts)
	end
	require("mini.completion").setup({
		lsp_completion = {
			-- Without this config autocompletion is set up through `:h 'completefunc'`.
			-- Although not needed, setting up through `:h 'omnifunc'` is cleaner
			-- (sets up only when needed) and makes it possible to use `<C-u>`.
			source_func = "omnifunc",
			auto_setup = false,
			process_items = process_items,
		},
	})

	-- Set 'omnifunc' for LSP completion only when needed.
	local on_attach = function(ev)
		vim.bo[ev.buf].omnifunc = "v:lua.MiniCompletion.completefunc_lsp"
	end
	_G.Config.new_autocmd("LspAttach", nil, on_attach, "Set 'omnifunc'")

	-- Advertise to servers that Neovim now supports certain set of completion and
	-- signature features through 'mini.completion'.
	vim.lsp.config("*", { capabilities = MiniCompletion.get_lsp_capabilities() })

	-- Add a keymap for disabling completion
	vim.keymap.set("n", "\\p", function()
		require("mini.completion").setup({ delay = { completion = 10 ^ 7, info = 10 ^ 7, signature = 10 ^ 7 } })
	end, { desc = "Toggle 'cm[p]'" })
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

-- Jump
later(function()
	require("mini.jump").setup()
end)

-- Jump 2D
later(function()
	require("mini.jump2d").setup()
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
