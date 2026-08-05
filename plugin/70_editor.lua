-- Make concise helpers for installing/adding plugins in two stages
local add, later, now, now_if_args = vim.pack.add, Config.later, Config.now, Config.now_if_args

-- Marks ======================================================================
later(function()
	add({ "https://github.com/chentoast/marks.nvim" })
	require("marks").setup()
end)

-- Yanky ======================================================================
later(function()
	add({ "https://github.com/gbprod/yanky.nvim" })
	require("yanky").setup({
		highlight = { timer = 150 },
		preserve_cursor_position = {
			enabled = true,
		},
	})
	vim.keymap.set({ "n", "x" }, "y", "<Plug>(YankyYank)", { desc = "Yank text" })
	vim.keymap.set({ "n", "x" }, "p", "<Plug>(YankyPutAfter)", { desc = "Put after cursor" })
	vim.keymap.set({ "n", "x" }, "P", "<Plug>(YankyPutBefore)", { desc = "Put before cursor" })
	vim.keymap.set({ "n", "x" }, "gp", "<Plug>(YankyGPutAfter)", { desc = "Put after selection" })
	vim.keymap.set({ "n", "x" }, "gP", "<Plug>(YankyGPutBefore)", { desc = "Put before selection" })

	vim.keymap.set("n", "<c-p>", "<Plug>(YankyPreviousEntry)", { desc = "Previous yank from history" })
	vim.keymap.set("n", "<c-n>", "<Plug>(YankyNextEntry)", { desc = "Next Yank from history" })
end)

-- REPL/Slime ================================================================
later(function()
	add({ "https://github.com/jpalardy/vim-slime" })
	-- Configure with the global values
	vim.g.slime_target = "tmux"
	vim.g.slime_bracketed_paste = 1
	vim.g.slime_default_config = {
		socket_name = vim.fn.split(vim.env.TMUX, ",")[1],
		target_pane = ":.2",
	}
	Config.nmap("gz", "<Plug>SlimeMotionSend", "Slime Motion Send")
	Config.nmap("gzz", "<Plug>SlimeLineSend", "Slime Motion Send")
	Config.xmap("gz", "<Plug>SlimeRegionSend", "Slime Region Send")
	Config.nmap("gzc", "<Plug>SlimeConfig", "Slime Config")
end)

later(function()
	add({ "https://github.com/Vigemus/iron.nvim" })

	local iron = require("iron.core")
	local marks = require("iron.marks")
	local view = require("iron.view")
	local common = require("iron.fts.common")

	iron.setup({
		config = {
			scratch_repl = true,
			repl_definition = {
				python = {
					command = { "ipython", "--no-autoindent" },
					format = common.bracketed_paste_python,
					block_dividers = { "# %%", "#%%" },
					env = { PYTHON_BASIC_REPL = "1" },
				},
				ocaml = {
					command = function()
						-- Check if in dune project
						vim.fn.systemlist("dune describe")
						if vim.v.shell_error ~= 0 then
							-- Not in a dune project, just use regular utop
							return { "utop" }
						end
						return { "dune", "utop" }
					end,
					format = function(lines)
						lines[#lines] = lines[#lines] .. ";;" .. string.char(13)
						return lines
					end,
				},
				r = {
					command = { "R" },
					format = common.bracketed_paste,
				},
				quarto = {
					command = { "R" },
					format = common.bracketed_paste,
				},
			},
			repl_filetype = function(_, ft)
				return ft
			end,
			repl_open_cmd = view.split.vertical.botright(80),
		},
		keymaps = {},
		highlight = { italic = true },
		ignore_blank_lines = true,
	})

	-- Leader keymaps
	-- REPL Commands
	Config.nmap_leader("rr", "<cmd>IronRepl<cr>", "Toggle")
	Config.nmap_leader("rR", "<cmd>IronRestart<cr>", "Restart")
	Config.nmap_leader("rf", "<cmd>IronFocus<cr>", "Focus")
	Config.nmap_leader("rq", iron.close_repl, "Close")
	Config.nmap_leader("rh", iron.hide_repl, "Hide")
	Config.nmap_leader("rc", function()
		iron.send(nil, string.char(12))
	end, "Clear")
	Config.nmap_leader("rx", function()
		iron.send(nil, string.char(03))
	end, "Interrupt")

	-- Send Commands
	Config.nmap_leader("rl", iron.send_line, "Send Line")
	Config.nmap_leader("rF", iron.send_file, "Send File")
	Config.nmap_leader("rp", iron.send_paragraph, "Send Paragraph")
	Config.nmap_leader("rp", iron.send_until_cursor, "Send Until Cursor")
	Config.nmap_leader("rm", iron.send_mark, "Send Mark")
	Config.nmap_leader("rb", function()
		iron.send_code_block(false)
	end, "Send Block")
	Config.nmap_leader("rB", function()
		iron.send_code_block(true)
	end, "Send Block and Move")
	Config.nmap_leader("rz", function()
		require("iron.core").run_motion("send_motion")
	end, "Send Motion")
	Config.nmap_leader("re", function()
		iron.send(nil, string.char(13))
	end, "Send Enter")

	-- Mark
	Config.nmap_leader("rd", marks.drop_last, "Delete Mark")
	Config.nmap_leader("ro", function()
		require("iron.core").run_motion("mark_motion")
	end, "Mark Motion")

	-- Additional keymaps
	-- Visual Mode
	-- Send
	vim.keymap.set("v", "<leader>rs", iron.visual_send, { desc = "Send Selection" })
	-- Mark
	vim.keymap.set("v", "<leader>rm", iron.mark_visual, { desc = "Mark Selection" })
end)

-- Tmux =======================================================================
later(function()
	add({ "https://github.com/aserowy/tmux.nvim.git" })
	require("tmux").setup({ copy_sync = { enable = false } })
end)

-- Todo Comments =======================================================
later(function()
	add({ "https://github.com/folke/todo-comments.nvim" })
	require("todo-comments").setup({})
	_G.Config.nmap_leader("ft", "<cmd>TodoQuickFix<cr>", "Todo QuickFix")
end)

-- Git ========================================================================
later(function()
	add({ "https://github.com/lewis6991/gitsigns.nvim" })
	require("gitsigns").setup({
		-- See `:help gitsigns.txt`
		signs = {
			add = { text = "+" },
			change = { text = "~" },
			delete = { text = "_" },
			topdelete = { text = "‾" },
			changedelete = { text = "~" },
		},
	})
	vim.cmd([[hi GitSignsAdd guifg=#04de21]])
	vim.cmd([[hi GitSignsChange guifg=#83fce6]])
	vim.cmd([[hi GitSignsDelete guifg=#fa2525]])

	-- Diff view
	add({ "https://github.com/sindrets/diffview.nvim" })
	require("diffview").setup({})
	Config.nmap_leader("gv", "<cmd>DiffViewOpen<cr>", "Diff view")

	-- Neogit
	add({
		"https://github.com/NeogitOrg/neogit",
	})
	require("neogit").setup({
		commit_editor = {
			kind = "tab",
			staged_diff_split_kind = "auto",
		},
	})

	-- Keymap to open neogit
	Config.nmap_leader("gn", "<cmd>Neogit<cr>", "Open Neogit")
end)

-- Incremental Rename ======================================================
later(function()
	add({ "https://github.com/smjonas/inc-rename.nvim" })
	require("inc_rename").setup({})

	vim.keymap.set("n", "<leader>lr", function()
		return ":IncRename " .. vim.fn.expand("<cword>")
	end, { expr = true, desc = "Rename" })
end)

-- Task Runner =============================================================
later(function()
	add({ "https://github.com/stevearc/overseer.nvim" })
	require("overseer").setup()

	Config.nmap_leader("Tr", "<cmd>OverseerRun<cr>", "Run")
	Config.nmap_leader("Ta", "<cmd>OverseerTaskAction<cr>", "Action")
	Config.nmap_leader("Tt", "<cmd>OverseerToggle<cr>", "Toggle")
end)

-- Undotree ===============================================================
later(function()
	add({ "https://github.com/jiaoshijie/undotree" })
	Config.nmap_leader("u", function()
		require("undotree").toggle()
	end, "Undo-Tree")
end)

-- Multiple Cursor =========================================================
later(function()
	add({ "https://github.com/jake-stewart/multicursor.nvim" })
	local mc = require("multicursor-nvim")
	mc.setup()

	local set = vim.keymap.set
	-- Split visual selections by regex.
	set("x", "<c-c>", mc.matchCursors)
	-- Add or skip cursor above/below the main cursor.
	set({ "n", "x" }, "<c-up>", function()
		mc.lineAddCursor(-1)
	end)
	set({ "n", "x" }, "<c-down>", function()
		mc.lineAddCursor(1)
	end)

	-- Add cursors at matches
	set({ "n", "x" }, "<c-m-j>", function()
		mc.matchAddCursor(1)
	end)
	set({ "n", "x" }, "<c-m-k>", function()
		mc.matchAddCursor(-1)
	end)

	-- Split visual selections by regex.
	set("x", "S", mc.splitCursors)

	-- match new cursors within visual selections by regex.
	set("x", "M", mc.matchCursors)

	set({ "n", "x" }, "<leader>cn", function()
		mc.matchAddCursor(1)
	end, { desc = "Add at next match" })
	set({ "n", "x" }, "<leader>cs", function()
		mc.matchSkipCursor(1)
	end, { desc = "Skip next match" })
	set({ "n", "x" }, "<leader>cN", function()
		mc.matchAddCursor(-1)
	end, { desc = "Add at previous match" })
	set({ "n", "x" }, "<leader>cS", function()
		mc.matchSkipCursor(-1)
	end, { desc = "Skip previous match" })

	-- Add and remove cursors with control + left click.
	set("n", "<c-leftmouse>", mc.handleMouse)
	set("n", "<c-leftdrag>", mc.handleMouseDrag)
	set("n", "<c-leftrelease>", mc.handleMouseRelease)

	mc.addKeymapLayer(function(layerSet)
		-- Select a different cursor as the main one.
		layerSet({ "n", "x" }, "<left>", mc.prevCursor)
		layerSet({ "n", "x" }, "<right>", mc.nextCursor)

		-- Delete the main cursor.
		layerSet({ "n", "x" }, "<leader>cx", mc.deleteCursor, { desc = "Delete Current cursor" })

		-- Enable and clear cursors using escape.
		layerSet("n", "<esc>", function()
			if not mc.cursorsEnabled() then
				mc.enableCursors()
			else
				mc.clearCursors()
			end
		end)
	end)
end)

-- Flash (Faster movement) ====================================
later(function()
	add({ "https://github.com/folke/flash.nvim" })
	require("flash").setup({})
	Config.nmap_leader("<leader>", function()
		require("flash").jump()
	end, "Flash")

	vim.keymap.set("x", "<leader><leader>", function()
		require("flash").jump()
	end, { desc = "Flash" })

	vim.keymap.set("o", "r", function()
		require("flash").remote()
	end, { desc = "Remote Flash" })
	vim.keymap.set({ "o", "x" }, "R", function()
		require("flash").treesitter_search()
	end, { desc = "Treesitter Search" })
end)

-- Direnv (Tool Management) =================================
now(function()
	if vim.fn.has("linux") > 0 then
		add({ "https://github.com/NotAShelf/direnv.nvim" })
		require("direnv").setup({})
	end
end)

-- Grug-far (Easier search and replace) ====================
later(function()
	add({ "https://github.com/MagicDuck/grug-far.nvim" })
	require("grug-far").setup()
	Config.nmap_leader("fR", ":GrugFar<CR>", "Replace")
end)
