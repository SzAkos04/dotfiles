vim.cmd("packadd packer.nvim")
return require("packer").startup(function(use)
    use("wbthomason/packer.nvim")

    -- LSP & Autocompletion Engine
    use({
        "neovim/nvim-lspconfig",
        requires = {
            "hrsh7th/nvim-cmp",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
            "hrsh7th/cmp-vsnip",
            "hrsh7th/vim-vsnip",
            "onsails/lspkind.nvim",
            "lukas-reineke/cmp-under-comparator",
            "hrsh7th/cmp-calc",
            "windwp/nvim-autopairs",
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
        },

        config = function()
            -- 1. Setup Environment Tools First
            require("mason").setup()
            require("mason-lspconfig").setup()

            -- 2. Setup Autopairs & Autocompletion configuration
            local custom_menu_icon = {
                nvim_lsp = "",
                vsnip = "",
                calc = "󰃬",
            }
            require("nvim-autopairs").setup({})
            local cmp_autopairs = require("nvim-autopairs.completion.cmp")
            require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())

            local cmp = require("cmp")
            cmp.setup({
                snippet = {
                    expand = function(args)
                        vim.fn["vsnip#anonymous"](args.body)
                    end,
                },
                mapping = {
                    ["<C-p>"] = cmp.mapping.select_prev_item(),
                    ["<C-n>"] = cmp.mapping.select_next_item(),
                    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-e>"] = cmp.mapping.close(),
                    ["<CR>"] = cmp.mapping.confirm({
                        behavior = cmp.ConfirmBehavior.Insert,
                        select = true,
                    }),
                },
                sources = {
                    { name = "nvim_lsp", blacklist = { "Text" } },
                    { name = "vsnip" },
                    { name = "calc" },
                    { name = "path" },
                    { name = "git" },
                },
                completion = {
                    completeopt = "menu,menuone,noinsert",
                },
                formatting = {
                    format = function(entry, vim_item)
                        if custom_menu_icon[entry.source.name] then
                            vim_item.kind = custom_menu_icon[entry.source.name] .. " " .. vim_item.kind
                        else
                            vim_item.kind = require("lspkind").presets.default[vim_item.kind] .. " " .. vim_item.kind
                        end

                        vim_item.menu = ({
                            nvim_lsp = "[LSP]",
                            vsnip = "[VSnip]",
                            calc = "[Calc]",
                            buffer = "[Buffer]",
                            path = "[Path]",
                            git = "[Git]",
                        })[entry.source.name]

                        return vim_item
                    end,
                },
                sorting = {
                    comparators = {
                        cmp.config.compare.offset,
                        cmp.config.compare.exact,
                        cmp.config.compare.score,
                        require("cmp-under-comparator").under,
                        cmp.config.compare.kind,
                        cmp.config.compare.sort_text,
                        cmp.config.compare.length,
                        cmp.config.compare.order,
                    },
                },
                window = {
                    completion = {
                        winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None",
                        col_offset = -3,
                        side_padding = 0,
                    },
                },
            })

            cmp.setup.filetype("gitcommit", {
                sources = cmp.config.sources({
                    { name = "git" },
                }, {
                    { name = "buffer" },
                }),
            })

            -- 3. Unified Hybrid Version Loop (Supports legacy and native Neovim 0.11+)
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
                "ts_ls",
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

                if has_native_lsp then
                    if opts.root_dir == nil then
                        opts.root_dir = function(fname)
                            return vim.fs.root(fname, { "compile_commands.json", "tsconfig.json", "package.json", ".git" }) 
                                or vim.uv.cwd()
                        end
                    end

                    vim.lsp.config(server, {
                        config = opts
                    })
                    vim.lsp.enable(server)
                else
                    if opts.root_dir == nil then
                        local lspconfig_util_ok, util = pcall(require, "lspconfig.util")
                        if lspconfig_util_ok then
                            opts.root_dir = util.root_pattern("compile_commands.json", "tsconfig.json", "package.json", ".git")
                        end
                    end

                    local status_ok, lspconfig = pcall(require, "lspconfig")
                    if status_ok then
                        lspconfig[server].setup(opts)
                    end
                end
            end

            -- 4. Automatically Force Treesitter Highlighting Engine To Attach
            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "c", "cpp", "lua", "python", "rust", "bash", "javascript", "typescript" },
                callback = function(args)
                    -- Kill regex engine fallback patterns completely
                    vim.cmd("syntax off")
                    
                    -- Extract syntax targets and force attach native runtime highlighter
                    local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype) or vim.bo[args.buf].filetype
                    pcall(vim.treesitter.start, args.buf, lang)
                end,
            })
        end,
    })

    -- Notifications
    use({
        "j-hui/fidget.nvim",
        config = function()
            require("fidget").setup()
        end,
    })

    -- UI
    use({
        "folke/todo-comments.nvim",
        requires = { "nvim-lua/plenary.nvim" },
        config = function()
            require("todo-comments").setup({})
        end,
    })
    use({
        "nvim-telescope/telescope.nvim",
        requires = {
            "nvim-tree/nvim-web-devicons",
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope-file-browser.nvim",
        },
        config = function()
            require("telescope").setup({})
            require("telescope").load_extension("file_browser")
        end,
    })
    use({
        "tamton-aquib/staline.nvim",
        requires = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("staline").setup({
                defaults = {
                    expand_null_ls = false,
                    full_path = vim.o.columns >= 128,
                    line_column = "[%l/%L] :%c",
                    inactive_color = "#303030",
                    inactive_bgcolor = "none",
                    true_colors = true,
                    font_active = "none",
                },
                mode_colors = {
                    n = "#83b28a",
                    i = "#9e77bd",
                    c = "#cd6169",
                    ic = "#cd6169",
                    v = "#e5bf79",
                    vl = "#e5bf79",
                    t = "#d2846d",
                },
                sections = {
                    left = { " ", "mode", " ", "branch", " ", "lsp" },
                    mid = { "file_name" },
                    right = { "lsp_name", " ", "line_column" },
                },
                inactive_sections = {
                    left = { "branch" },
                    mid = { "file_name" },
                    right = { "line_column" },
                },
                special_table = {
                    packer = { "Packer", "📦 " },
                },
                lsp_symbols = {
                    Error = " ",
                    Info = " ",
                    Warn = " ",
                    Hint = "󰌵 ",
                },
            })
            require("stabline").setup({
                style = "bar",
                bg = "none",
                fg = "#ffffff",
                exclude_fts = { "Veil", "Packer" },
            })
        end,
    })
    use({
        "daschw/leaf.nvim",
        config = function()
            require("leaf").setup({
                underlineStyle = "undercurl",
                commentStyle = "italic",
                functionStyle = "NONE",
                keywordStyle = "italic",
                statementStyle = "bold",
                typeStyle = "NONE",
                variablebuiltinStyle = "italic",
                transparent = true,
                colors = {},
                overrides = {
                    Normal = { bg = "none" },
                    FloatBorder = { bg = "none" },
                },
                theme = "auto",
                contrast = "high",
            })
            vim.cmd("colorscheme leaf")
        end,
    })
    use({
        "lukas-reineke/indent-blankline.nvim",
        config = function()
            require("ibl").setup({
                indent = { char = "┋" },
                scope = { char = "┃", enabled = true, show_exact_scope = true },
            })
            local hooks = require("ibl.hooks")
            hooks.register(hooks.type.ACTIVE, function(bufnr)
                return vim.api.nvim_buf_line_count(bufnr) < 5000
            end)
        end,
    })
    use({
        "willothy/veil.nvim",
        requires = {
            "nvim-telescope/telescope.nvim",
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope-file-browser.nvim",
        },
        config = function()
            require("veil").setup()
        end,
    })
    use({
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup({
                signs = {
                    add = { text = "┃" },
                    change = { text = "┃" },
                    delete = { text = "_" },
                    topdelete = { text = "‾" },
                    changedelete = { text = "~" },
                    untracked = { text = "┆" },
                },
                signcolumn = true,
                numhl = false,
                linehl = false,
                word_diff = false,
                watch_gitdir = {
                    follow_files = true,
                },
                auto_attach = true,
                attach_to_untracked = false,
                current_line_blame = false,
                current_line_blame_opts = {
                    virt_text = true,
                    virt_text_pos = "eol",
                    delay = 1000,
                    ignore_whitespace = false,
                    virt_text_priority = 100,
                },
                current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
                sign_priority = 6,
                update_debounce = 100,
                status_formatter = nil,
                max_file_length = 40000,
                preview_config = {
                    border = "single",
                    style = "minimal",
                    relative = "cursor",
                    row = 0,
                    col = 1,
                },
            })
        end,
    })

    -- Additional plugins
    use({
        "nvim-treesitter/nvim-treesitter",
        run = ":TSUpdate",
        requires = {
            "windwp/nvim-ts-autotag",
            "andymass/vim-matchup",
        },
        config = function()
            local status_ok, configs = pcall(require, "nvim-treesitter.configs")
            if not status_ok then
                return
            end

            configs.setup({
                ensure_installed = { "lua", "c", "cpp" },
                sync_install = false,
                auto_install = true,
                highlight = {
                    enable = true,
                    additional_vim_regex_highlighting = false,
                },
                indent = { enable = false },
                incremental_selection = { enable = false },
            })

            pcall(function()
                require("nvim-ts-autotag").setup()
                vim.g.matchup_matchparen_offscreen = { method = "popup" }
            end)
        end,
    })
    use({ "tpope/vim-fugitive" })
    use({ "tpope/vim-commentary" })
    use({
        "p00f/clangd_extensions.nvim",
        config = function()
            require("clangd_extensions").setup()
        end,
    })
    use({
        "stevearc/conform.nvim",
        config = function()
            require("conform").setup({
                formatters = {
                    clang_format = {
                        inherit = false,
                        command = "clang-format",
                        args = { "-style={BasedOnStyle: llvm, IndentWidth: 4}", "-i", "$FILENAME" },
                        stdin = false,
                    },
                    findent = {
                        inherit = false,
                        command = "wfindent",
                        args = { "-i4", "$FILENAME" },
                        stdin = false,
                    },
                },
                formatters_by_ft = {
                    c = { "clang_format" },
                    cpp = { "clang_format" },
                    asm = { "asmfmt" },
                    go = { "gofmt" },
                    javascript = { "prettier" },
                    lua = { "stylua" },
                    python = { "black" },
                    rust = { "rustfmt" },
                    fortran = { "findent" },
                },
            })
        end,
    })
    use({
        "chentoast/marks.nvim",
        config = function()
            require("marks").setup()
        end,
    })
    use({ "ThePrimeagen/vim-be-good" })
    use({
        "soulis-1256/eagle.nvim",
        config = function()
            require("eagle").setup()
        end,
    })
    use({ "Wansmer/binary-swap.nvim" })
    use({ "famiu/bufdelete.nvim" })
    use({ "wakatime/vim-wakatime" })
    use({
        "Saecki/crates.nvim",
        config = function()
            require("crates").setup()
        end,
    })
end)
