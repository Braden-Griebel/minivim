-- LSP Config
local add, later = MiniDeps.add, MiniDeps.later
local now_if_args = _G.Config.now_if_args

-- Language servers ===========================================================

now_if_args(function()
	-- Add and setup Mason
	add({ source = "mason-org/mason.nvim" })
	require("mason").setup({})

	add("neovim/nvim-lspconfig")

	vim.lsp.enable({
		-- == Lua ==
		"lua_ls",
	})
end)
