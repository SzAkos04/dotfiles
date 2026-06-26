vim.diagnostic.config({
    underline = true,
    virtual_text = true,
    update_in_insert = true,
    severity_sort = true,
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.WARN]  = "",
            [vim.diagnostic.severity.INFO]  = "",
            [vim.diagnostic.severity.HINT]  = "󰌵",
        },
    },
})

local capabilities = require("cmp_nvim_lsp").default_capabilities()

local servers = {
    "asm_lsp",
    "bashls",
    "clangd",
    "lua_ls",
    "pylsp",
    "rust_analyzer",
    "zls",
}

local has_native_lsp = vim.fn.has("nvim-0.11") == 1

for _, server in ipairs(servers) do
    local opts = {
        capabilities = capabilities,
    }

    local require_ok, conf_opts = pcall(require, "lsp-settings." .. server)
    if require_ok then
        opts = vim.tbl_deep_extend("force", opts, conf_opts)
    end

    if opts.root_dir == nil then
        local lspconfig_util_ok, util = pcall(require, "lspconfig.util")
        if lspconfig_util_ok then
            opts.root_dir = util.root_pattern("compile_commands.json", "compile_flags.txt", ".git")
        end
    end

    if has_native_lsp then
        vim.lsp.config(server, {
            config = opts
        })
        vim.lsp.enable(server)
    else
        -- Legacy/lspconfig configuration
        local status_ok, lspconfig = pcall(require, "lspconfig")
        if status_ok then
            lspconfig[server].setup(opts)
        end
    end
end
