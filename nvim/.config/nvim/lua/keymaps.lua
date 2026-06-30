vim.g.mapleader = " "

-- movement in insert mode
vim.keymap.set("i", "<C-h>", "<Left>")
vim.keymap.set("i", "<C-j>", "<Down>")
vim.keymap.set("i", "<C-k>", "<Up>")
vim.keymap.set("i", "<C-l>", "<Right>")

-- split navigation
vim.keymap.set("n", "<leader>h", "<C-w>h")
vim.keymap.set("n", "<leader>j", "<C-w>j")
vim.keymap.set("n", "<leader>k", "<C-w>k")
vim.keymap.set("n", "<leader>l", "<C-w>l")

-- split creation
vim.keymap.set("n", "<C-s>", ":split<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>wv", ":vsplit<CR>", { noremap = true, silent = true })

-- move lines up and down in visual mode
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { noremap = true, silent = true })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { noremap = true, silent = true })

-- replace word under cursor
vim.keymap.set("n", "<leader>rw", [[:%s/<C-r><C-w>//g<Left><Left>]], { noremap = true })

-- buffer navigation
vim.keymap.set("n", "<leader>,", ":bprevious<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>.", ":bnext<CR>", { noremap = true, silent = true })

-- close buffer (without closing the window)
vim.keymap.set("n", "<leader>c", function()
	require("bufdelete").bufdelete(0)
end, { noremap = true, silent = true })

-- LSP hover
vim.keymap.set("n", "<leader><Space>", vim.lsp.buf.hover, { noremap = true, silent = true })

-- telescope
vim.keymap.set("n", "<leader>e", ":Telescope file_browser<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>ff", ":Telescope find_files<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>fw", ":Telescope live_grep<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>fb", ":Telescope buffers<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>fd", ":Telescope diagnostics<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<leader>fc", ":Telescope git_commits<CR>", { noremap = true, silent = true })

-- LSP keymaps (set only after a server attaches to the buffer)
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(event)
		local opts = { buffer = event.buf, silent = true }

		vim.keymap.set("n", "<leader>gh", vim.lsp.buf.hover, opts)
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
		vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
		vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
		vim.keymap.set("n", "go", vim.lsp.buf.type_definition, opts)
		vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
		vim.keymap.set("n", "gs", vim.lsp.buf.signature_help, opts)
		vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
		vim.keymap.set("n", "gc", vim.lsp.buf.code_action, opts)
		vim.keymap.set({ "n", "x" }, "<S-f>", function()
			vim.lsp.buf.format({ async = true })
		end, opts)
		vim.keymap.set("n", "<leader>lh", function()
			vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
		end, opts)
		vim.keymap.set("n", "<leader>sw", function()
			require("binary-swap").swap_operands()
		end, opts)
		vim.keymap.set("n", "<leader>sv", function()
			require("binary-swap").swap_operands_with_operator()
		end, opts)
	end,
})
