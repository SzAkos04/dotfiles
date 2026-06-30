return {
	-- 1. OVERRIDE ROOT MARKERS: Prevent lua_ls from scanning your entire home directory.
	-- It will now only activate if it finds a strict Lua project layout.
	root_markers = {
		".luarc.json",
		".luarc.jsonc",
		"stylua.toml",
		".stylua.toml",
		"init.lua", -- Great fallback for Neovim config folders
	},

	-- 2. YOUR ORIGINAL SETTINGS: Keep your diagnostics and workspace setups intact.
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim", "use" },
			},
			workspace = {
				-- This ensures Neovim APIs are recognized properly
				library = vim.api.nvim_get_runtime_file("lua/vim", true),
				checkThirdParty = false,
			},
			completion = {
				callSnippet = "Replace",
			},
		},
	},
}
