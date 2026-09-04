-- Make concise helpers for installing/adding plugins in two stages
local add, later, now, now_if_args = vim.pack.add, Config.later, Config.now, Config.now_if_args

-- Nvim Options ===============================================================
vim.lsp.inlay_hint.enable(true)

-- Completion
now_if_args(function()
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
	Config.new_autocmd("LspAttach", nil, on_attach, "Set 'omnifunc'")

	-- Advertise to servers that Neovim now supports certain set of completion and
	-- signature features through 'mini.completion'.
	vim.lsp.config("*", { capabilities = MiniCompletion.get_lsp_capabilities() })
end)

-- Tree-sitter ================================================================
now_if_args(function()
	-- Define hook to update tree-sitter parsers after plugin is updated
	local ts_update = function()
		vim.cmd("TSUpdate")
	end
	Config.on_packchanged("nvim-treesitter", { "update" }, ts_update, ":TSUpdate")

	add({
		"https://github.com/nvim-treesitter/nvim-treesitter",
		"https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
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
		"python",
		"rust",
		"sql",
		"sway",
		"typescript",
		"typst",
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
	add({ "https://github.com/stevearc/conform.nvim" })

	require("conform").setup({
		notify_on_error = false,
		format_on_save = function(bufnr)
			local disable_filetypes = {} -- { c = true, cpp = true }
			if vim.g.disable_autoformat or disable_filetypes[vim.bo[bufnr].filetype] then
				return nil
			else
				return {
					timeout_ms = 500,
					lsp_format = "fallback",
				}
			end
		end,
		formatters_by_ft = {
			bash = { "shfmt" },
			-- cpp = { "clang-format" }, -- Bundled with clangd, no need to format
			go = { "gofumpt" },
			just = { "just" },
			lua = { "stylua" },
			markdown = { "mdformat" },
			meson = { "meson" },
			python = { "ruff_format" },
			quarto = { "injected" },
			toml = { "taplo" },
			typst = { "typstyle" },
			xml = { "xmlformatter" },
		},
		formatters = {
			meson = {
				command = "meson",
				stdin = false,
				args = { "format", "-i", "$FILENAME" },
			},
			typstyle = {
				command = "typstyle",
				stdin = true,
				args = { "--wrap-text" },
			},
		},
	})
	require("conform").formatters.injected = {
		-- Set the options field
		options = {
			-- Set to true to ignore errors
			ignore_errors = false,
			-- Map of treesitter language to file extension
			-- A temporary file name with this extension will be generated during formatting
			-- because some formatters care about the filename.
			lang_to_ext = {
				bash = "sh",
				c_sharp = "cs",
				elixir = "exs",
				javascript = "js",
				julia = "jl",
				latex = "tex",
				markdown = "md",
				python = "py",
				ruby = "rb",
				rust = "rs",
				teal = "tl",
				r = "r",
				typescript = "ts",
			},
			-- Map of treesitter language to formatters to use
			-- (defaults to the value from formatters_by_ft)
			lang_to_formatters = {},
		},
	}

	--  Set this value to false initially to allow toggleing easily
	vim.g.disable_autoformat = false

	-- Create command to disable autoformatting
	vim.api.nvim_create_user_command("FormatToggle", function()
		vim.g.disable_autoformat = not vim.g.disable_autoformat
	end, {
		desc = "Toggle autoformat-on-save",
	})

	-- Add keymaps to call the disable formatting
	Config.nmap("\\f", "<cmd>FormatToggle<cr>", "Toggle format on save")
end)

-- Linting ====================================================================

later(function()
	add({ "https://codeberg.org/mfussenegger/nvim-lint" })

	require("lint").linters_by_ft = {
		markdown = { "markdownlint-cli2" },
		bash = { "shellcheck" },
		javascript = { "oxlint", "eslint" },
		typscript = { "eslint" },
	}

	vim.api.nvim_create_autocmd({ "BufWritePost" }, {
		callback = function()
			require("lint").try_lint()
		end,
	})
end)

-- Slueth ================================================================
later(function()
	add({ "https://github.com/tpope/vim-sleuth" })
end)

-- CSV View ==============================================================
later(function()
	add({ "https://github.com/hat0uma/csvview.nvim" })
	require("csvview").setup()
end)
