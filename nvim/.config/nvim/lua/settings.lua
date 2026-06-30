vim.o.title = true
vim.o.encoding = "utf-8"
vim.o.scrolloff = 5
vim.o.autoindent = true
vim.o.smartindent = true
vim.o.showmode = false
vim.o.hidden = true
vim.o.number = true
vim.o.relativenumber = true
vim.o.laststatus = 2
vim.o.previewheight = 20
vim.o.regexpengine = 0
vim.o.background = "dark"
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.softtabstop = 4
vim.o.expandtab = true
vim.o.shiftround = true
vim.o.wrap = false
vim.o.clipboard = "unnamedplus"
vim.o.mouse = "a"
vim.o.mousemoveevent = true
vim.o.termguicolors = true
vim.o.swapfile = false
vim.o.backup = false
vim.o.undofile = true
vim.o.updatetime = 50
vim.o.hlsearch = false
vim.o.incsearch = true
vim.o.showtabline = 2
vim.o.showcmd = false
vim.o.ruler = false
vim.o.spell = true
vim.o.autochdir = false
vim.o.spelllang = "en_us"
vim.o.cmdheight = 1
vim.o.shell = "/bin/zsh"

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "c", "cpp" },
	callback = function()
		vim.bo.cindent = true
	end,
})

-- relative number in normal mode only
vim.api.nvim_create_autocmd("InsertEnter", {
	pattern = "*",
	callback = function()
		vim.o.relativenumber = false
	end,
})
vim.api.nvim_create_autocmd("InsertLeave", {
	pattern = "*",
	callback = function()
		vim.o.relativenumber = true
	end,
})

-- disable auto-comment continuation on newline
vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function()
		vim.opt_local.formatoptions:remove({ "c", "r", "o" })
	end,
})

-- autoformat on save
vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*",
	callback = function()
		require("conform").format()
	end,
})

-- disable spell check in terminal
vim.api.nvim_create_autocmd("TermOpen", {
	pattern = "*",
	callback = function()
		vim.wo.spell = false
	end,
})

vim.api.nvim_create_autocmd("TermEnter", {
	pattern = "term://*toggleterm#*",
	callback = function()
		vim.cmd(":file! Terminal")
	end,
})
