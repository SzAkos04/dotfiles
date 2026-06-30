return {
	cmd = {
		"clangd",
		"--background-index",
		"--clang-tidy",
		"--completion-style=detailed",
		"--function-arg-placeholders",
		"--fallback-style=llvm",
	},
	filetypes = { "c", "cpp" },
	root_dir = function(fname)
		return vim.fs.root(fname, { "compile_commands.json", "compile_flags.txt", ".git" }) or vim.fs.dirname(fname)
	end,
	init_options = {
		clangdFileStatus = true,
		usePlaceholders = true,
		completeUnimported = true,
		semanticHighlighting = true,
	},
}
