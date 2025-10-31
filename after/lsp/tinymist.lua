return {
	on_attach = function(client, bufnr)
		vim.keymap.set("n", "<localleader>tp", function()
			client:exec_cmd({

				title = "pin",

				command = "tinymist.pinMain",

				arguments = { vim.api.nvim_buf_get_name(0) },
			}, { bufnr = bufnr })
		end, { desc = "[T]inymist [P]in", noremap = true })

		vim.keymap.set("n", "<localleader>tu", function()
			client:exec_cmd({

				title = "unpin",

				command = "tinymist.pinMain",

				arguments = { vim.v.null },
			}, { bufnr = bufnr })
		end, { desc = "[T]inymist [U]npin", noremap = true })
	end,
}
