local nvim_lsp = require("lspconfig")

return {
    filetypes = { "c", "cpp" },
    root_dir = function(fname)
        local root_pattern = nvim_lsp.util.root_pattern("compile_commands.json", "compile_flags.txt", ".git")(fname)
        return root_pattern or vim.uv.cwd()
    end,
    init_options = {
        clangdFileStatus = true,
        usePlaceholders = true,
        completeUnimported = true,
    },
}
