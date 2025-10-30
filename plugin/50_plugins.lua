-- Make concise helpers for installing/adding plugins in two stages
local add, later, now = MiniDeps.add, MiniDeps.later, MiniDeps.now
local now_if_args = _G.Config.now_if_args
-- Helper for defining plugin keymaps

local nmap_leader = function(suffix, rhs, desc)
	vim.keymap.set("n", "<Leader>" .. suffix, rhs, { desc = desc })
end
local nmap = function(lhs, rhs, desc)
	-- See `:h vim.keymap.set()`
	vim.keymap.set("n", lhs, rhs, { desc = desc })
end
local xmap = function(lhs, rhs, desc)
	-- See `:h vim.keymap.set()`
	vim.keymap.set("x", lhs, rhs, { desc = desc })
end
-- Tree-sitter
now_if_args(function()
	add({
		source = "nvim-treesitter/nvim-treesitter",
		-- Use `main` branch since `master` branch is frozen, yet still default
		checkout = "main",
		-- Update tree-sitter parser after plugin is updated
		hooks = {
			post_checkout = function()
				vim.cmd("TSUpdate")
			end,
		},
	})
	add({
		source = "nvim-treesitter/nvim-treesitter-textobjects",
		-- Same logic as for 'nvim-treesitter'
		checkout = "main",
	})

	-- Define languages which will have parsers installed and auto enabled
	local languages = {
		-- These are already pre-installed with Neovim. Used as an example.
		"asm",
		"c",
		"cmake",
		"cpp",
		"css",
		"fish",
		"fortran",
		"git_config",
		"git_rebase",
		"gitattributes",
		"gitcommit",
		"gitignore",
		"gleam",
		"go",
		"haskell",
		"html",
		"ini",
		"java",
		"javadoc",
		"javascript",
		"json",
		"julia",
		"just",
		"kdl",
		"latex",
		"lua",
		"markdown",
		"meson",
		"nix",
		"ocaml",
		"pip_requirements",
		"python",
		"r",
		"rust",
		"sql",
		"sway",
		"typescript",
		"typst",
		"verilog",
		"vim",
		"vimdoc",
		"xml",
		"yaml",
		"zig",
	}
	local isnt_installed = function(lang)
		return #vim.api.nvim_get_runtime_file("parser/" .. lang .. ".*", false) == 0
	end
	local to_install = vim.tbl_filter(isnt_installed, languages)
	if #to_install > 0 then
		require("nvim-treesitter").install(to_install)
	end

	-- Enable tree-sitter after opening a file for a target language
	local filetypes = {}
	for _, lang in ipairs(languages) do
		for _, ft in ipairs(vim.treesitter.language.get_filetypes(lang)) do
			table.insert(filetypes, ft)
		end
	end
	local ts_start = function(ev)
		vim.treesitter.start(ev.buf)
	end
	_G.Config.new_autocmd("FileType", filetypes, ts_start, "Start tree-sitter")
end)

-- Formatting =================================================================

later(function()
	add("stevearc/conform.nvim")

	require("conform").setup({
		notify_on_error = false,
		format_on_save = function(bufnr)
			local disable_filetypes = {} -- { c = true, cpp = true }
			if disable_filetypes[vim.bo[bufnr].filetype] then
				return nil
			else
				return {
					timeout_ms = 500,
					lsp_format = "fallback",
				}
			end
		end,
		formatters_by_ft = {
			lua = { "stylua" },
			cpp = { "clang-format" },
			bash = { "shfmt" },
			markdown = { "mdformat" },
			typst = { "typstyle" },
		},
		formatters = {
			typstyle = {
				command = "typstyle",
				stdin = true,
				args = { "--wrap-text" },
			},
		},
	})
end)

-- Linting ====================================================================
later(function()
	add("mfussenegger/nvim-lint")

	require("lint").linters_by_ft = {
		markdown = { "markdownlint-cli2" },
		bash = { "shellcheck" },
		python = { "mypy" },
		javascript = { "oxlint", "eslint" },
		typscript = { "eslint" },
	}

	vim.api.nvim_create_autocmd({ "BufWritePost" }, {
		callback = function()
			require("lint").try_lint()
		end,
	})
end)
-- Git ========================================================================
later(function()
	add("lewis6991/gitsigns.nvim")
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
	add("kdheepak/lazygit.nvim")
	nmap_leader("gz", "<cmd>LazyGit<cr>", "LazyGit")
end)

-- Marks ======================================================================
later(function()
	add("chentoast/marks.nvim")
	require("marks").setup()
end)

-- Yanky ======================================================================
later(function()
	add("gbprod/yanky.nvim")
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
	add("jpalardy/vim-slime")
	-- Configure with the global values
	vim.g.slime_target = "tmux"
	vim.g.slime_bracketed_paste = 1
	vim.g.slime_default_config = {
		socket_name = vim.fn.split(vim.env.TMUX, ",")[1],
		target_pane = ":.2",
	}
	nmap("gz", "<Plug>SlimeMotionSend", "Slime Motion Send")
	nmap("gzz", "<Plug>SlimeLineSend", "Slime Motion Send")
	xmap("gz", "<Plug>SlimeRegionSend", "Slime Region Send")
	nmap("gzc", "<Plug>SlimeConfig", "Slime Config")
end)

-- Snippets ===================================================================

later(function()
	add("rafamadriz/friendly-snippets")
end)

-- Tmux =======================================================================
later(function()
	add("christoomey/vim-tmux-navigator")
	vim.g.tmux_navigator_no_mappings = 1
	nmap("<c-h>", "<cmd>TmuxNavigateLeft<cr>")
	nmap("<c-j>", "<cmd>TmuxNavigateDown<cr>")
	nmap("<c-k>", "<cmd>TmuxNavigateUp<cr>")
	nmap("<c-l>", "<cmd>TmuxNavigateRight<cr>")
end)

-- Markdown =================================================================
later(function()
	add("MeanderingProgrammer/render-markdown.nvim")
	require("render-markdown").setup({})
end)

-- R =======================================================================
later(function()
	add("R-nvim/R.nvim")
	local opts = {
		hook = {
			on_filetype = function()
				vim.api.nvim_buf_set_keymap(0, "n", "<Enter>", "<Plug>RDSendLine", {})
				vim.api.nvim_buf_set_keymap(0, "v", "<Enter>", "<Plug>RSendSelection", {})
			end,
		},
		R_args = { "--quiet", "--no-save" },
		min_editor_width = 72,
		rconsole_width = 78,
		objbr_mappings = { -- Object browser keymap
			c = "class", -- Call R functions
			["<localleader>gg"] = "head({object}, n = 15)", -- Use {object} notation to write arbitrary R code.
			v = function()
				-- Run lua functions
				require("r.browser").toggle_view()
			end,
		},
		disable_cmds = {
			"RClearConsole",
			"RCustomStart",
			"RSPlot",
			"RSaveClose",
		},
	}
	-- Check if the environment variable "R_AUTO_START" exists.
	-- If using fish shell, you could put in your config.fish:
	-- alias r "R_AUTO_START=true nvim"
	if vim.env.R_AUTO_START == "true" then
		opts.auto_start = "on startup"
		opts.objbr_auto_start = true
	end
	require("r").setup(opts)
end)

-- Lean ====================================================================
later(function()
	add({ source = "Julian/lean.nvim", depends = { "nvim-lua/plenary.nvim" } })
	require("lean").setup({ mappings = true })
end)

-- Rust ===================================================================
later(function()
	add("mrcjkb/rustaceanvim")
	add("Saecki/crates.nvim")
	require("crates").setup()
end)

-- Slueth ================================================================
later(function()
	add("tpope/vim-sleuth")
end)

-- Terminal ==============================================================
later(function()
	add("akinsho/toggleterm.nvim")
	require("toggleterm").setup({
		size = function(term)
			if term.direction == "horizontal" then
				return 15
			elseif term.direction == "vertical" then
				return vim.o.columns * 0.4
			end
		end,
		open_mapping = [[<c-\>]],
		hide_numbers = true,
		shell = "bash",
	})
	-- Keymaps
	nmap(
		"<leader>tr",
		"<cmd>TermNew size=40 dir=git_dir direction=float name=root-terminal<cr>",
		"Open [T]erminal [R]oot Directory"
	)
	nmap(
		"<leader>tc",
		"<cmd>TermNew size=40 dir=. direction=float name=cwd-terminal<cr>",
		"Open [T]erminal [C]urrent [W]orking [D]irectory"
	)
	nmap(
		"<leader>tb",
		"<cmd>TermNew size=20 dir=. direction=horizontal name=horizontal-terminal<cr>",
		"Open [B]ottom Terminal"
	)
	nmap("<leader>ts", "<cmd>TermSelect<cr>", "[S]elect Terminal")
end)

-- Neotree =============================================================
later(function()
	local function copy_path(state)
		-- NeoTree is based on [NuiTree](https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/tree)
		-- The node is based on [NuiNode](https://github.com/MunifTanjim/nui.nvim/tree/main/lua/nui/tree#nuitreenode)
		local node = state.tree:get_node()
		local filepath = node:get_id()
		local filename = node.name
		local modify = vim.fn.fnamemodify

		local results = {
			filepath,
			modify(filepath, ":."),
			modify(filepath, ":~"),
			filename,
			modify(filename, ":r"),
			modify(filename, ":e"),
		}

		vim.ui.select({
			"1. Absolute path: " .. results[1],
			"2. Path relative to CWD: " .. results[2],
			"3. Path relative to HOME: " .. results[3],
			"4. Filename: " .. results[4],
			"5. Filename without extension: " .. results[5],
			"6. Extension of the filename: " .. results[6],
		}, { prompt = "Choose to copy to clipboard:" }, function(choice)
			if choice then
				local i = tonumber(choice:sub(1, 1))
				if i then
					local result = results[i]
					vim.fn.setreg('"', result)
					vim.notify("Copied: " .. result)
				else
					vim.notify("Invalid selection")
				end
			else
				vim.notify("Selection cancelled")
			end
		end)
	end

	add({
		source = "nvim-neo-tree/neo-tree.nvim",
		checkout = "v3.x",
		depends = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-tree/nvim-web-devicons", -- optional, but recommended
		},
	})

	require("neo-tree").setup({
		filesystem = {
			window = {
				mappings = {
					["\\"] = "close_window",
					["Y"] = copy_path,
				},
			},
		},
	})
	nmap_leader("et", "<cmd>Neotree reveal<cr>", "Tree")
end)

-- Todo Comments =======================================================
later(function()
	add({ source = "folke/todo-comments.nvim", depends = { "nvim-lua/plenary.nvim" } })
	require("todo-comments").setup({})
	nmap_leader("ft", "<cmd>TodoQuickFix<cr>", "Todo QuickFix")
end)
