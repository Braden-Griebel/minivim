-- LSP Config
local add, later = MiniDeps.add, MiniDeps.later
local now_if_args = _G.Config.now_if_args

now_if_args(function()
	add("neovim/nvim-lspconfig")

	vim.lsp.enable({
		-- == Lua ==
		"lua_ls",
		-- == Python ==
		"pyright",
		"ruff",
		-- == Typst ==
		"tinymist",
		-- == Markdown ==
	})
end)

later(function()
	-- Configure the correct python provider
	vim.g.python_host_prog = "~/environments/pynvim/.venv/bin/python"
	vim.g.python3_host_prog = "~/environments/pynvim/.venv/bin/python"

	-- Add and setup Mason
	add({ source = "mason-org/mason.nvim" })
	require("mason").setup({})

	-- Add Mason Tool Installer (to get ensure installed)
	add("WhoIsSethDaniel/mason-tool-installer.nvim")
	require("mason-tool-installer").setup({
		ensure_installed = {
			-- C/C++
			"clang-format",
			"clangd",
			-- Fortran
			"fortls",
			-- Go
			"gopls",
			"gofumpt",
			-- Java
			"jdtls",
			-- Javascript
			"eslint-lsp",
			"deno",
			-- Lua
			"lua-language-server",
			"luacheck",
			"stylua",
			-- Markdown
			"harper-ls",
			"marksman",
			"markdownlint-cli2",
			-- Ocaml
			"ocaml-lsp",
			-- Python
			"pyright",
			"ruff",
			"mypy",
			-- R
			"air",
			"r-languageserver",
			-- Shell
			"bash-language-server",
			"shellcheck",
			"shfmt",
			"fish-lsp",
			-- Typst
			"tinymist",
			"typstyle",
			-- Config Files
			"lemminx",
			"json-lsp",
			"yaml-language-server",
		},
	})

	-- Add and setup Lazydev
	add("folke/lazydev.nvim")
	require("lazydev").setup({
		library = {
			-- Load luvit types when the `vim.uv` word is found
			{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
		},
	})

	-- Add and setup fidget
	add("j-hui/fidget.nvim")
	require("fidget").setup({})
end)
