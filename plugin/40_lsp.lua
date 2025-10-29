-- LSP Config
local add, later = MiniDeps.add, MiniDeps.later
local now_if_args = _G.Config.now_if_args

-- Language servers ===========================================================

now_if_args(function()
	add("neovim/nvim-lspconfig")

	vim.lsp.enable({
		-- == Lua ==
		"lua_ls",
	})
end)
