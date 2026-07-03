-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({

	-- LSP
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			require("mason").setup()
			require("mason-lspconfig").setup()

			-- Readable diagnostics: only show inline text on the current line
			-- (keeps other lines clean), with a nicer floating window for
			-- <leader>gh / hover-style diagnostic lookups.
			vim.diagnostic.config({
				underline = true,
				severity_sort = true,
				update_in_insert = false,
				virtual_text = {
					prefix = "●",
					spacing = 4,
					-- keep long messages from wrapping/crowding the buffer;
					-- press <leader>gh (hover) or trigger the float for the full text
					format = function(diagnostic)
						local msg = diagnostic.message
						if #msg > 60 then
							return msg:sub(1, 57) .. "..."
						end
						return msg
					end,
				},
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = "",
						[vim.diagnostic.severity.WARN] = "",
						[vim.diagnostic.severity.INFO] = "",
						[vim.diagnostic.severity.HINT] = "󰌵",
					},
				},
				float = {
					border = "rounded",
					source = true,
					header = "",
					prefix = "",
				},
			})

			-- Auto-popup the full diagnostic message after a short idle pause,
			-- independent of `updatetime` (which is 50ms for gitsigns, too
			-- fast for this) so it doesn't flash on every micro-pause.
			local diag_float_timer = nil
			vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
				callback = function()
					if diag_float_timer then
						diag_float_timer:stop()
					end
					diag_float_timer = vim.defer_fn(function()
						vim.diagnostic.open_float(nil, { focus = false, scope = "cursor" })
					end, 300)
				end,
			})

			-- The built-in signature_help handler calls vim.notify("No signature
			-- help available") whenever the request comes back empty. Since we
			-- auto-trigger this on every "(" and "," in C/C++, that fires
			-- constantly for harmless cases (comments, macros, etc). Override
			-- it to just do nothing when there's no result, and behave
			-- normally otherwise.
			local default_sig_handler = vim.lsp.handlers["textDocument/signatureHelp"]
			vim.lsp.handlers["textDocument/signatureHelp"] = function(err, result, ctx, config)
				if err or not result or not result.signatures or #result.signatures == 0 then
					return
				end
				return default_sig_handler(err, result, ctx, config)
			end

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

			for _, server in ipairs(servers) do
				-- Start with capabilities, then merge any per-server overrides
				local opts = { capabilities = capabilities }
				local ok, conf_opts = pcall(require, "lsp-settings." .. server)
				if ok then
					opts = vim.tbl_deep_extend("force", opts, conf_opts)
				end

				-- root_dir functions are not supported by vim.lsp.config in 0.12;
				-- use root_markers (a plain list) instead. The native LSP client
				-- walks up from the file and stops at the first matching marker.
				-- We add a sentinel fallback so rootless files still attach:
				-- an empty string matches every directory (always found).
				if opts.root_dir ~= nil then
					opts.root_dir = nil -- drop lspconfig-style function, unused in 0.12
				end
				if opts.root_markers == nil then
					opts.root_markers = {
						"compile_commands.json",
						"compile_flags.txt",
						"tsconfig.json",
						"package.json",
						".git",
						".clangd",
					}
				end

				vim.lsp.config(server, opts)
				vim.lsp.enable(server)
			end

			-- Force Treesitter highlighting (no regex fallback)
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "c", "cpp", "lua", "python", "rust", "bash", "javascript", "typescript" },
				callback = function(args)
					local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
						or vim.bo[args.buf].filetype
					pcall(vim.treesitter.start, args.buf, lang)
				end,
			})

			-- Auto-trigger signature help on ( and , in C/C++ insert mode.
			-- defer_fn waits until after the char is inserted before asking clangd.
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "c", "cpp" },
				callback = function(args)
					local buf = args.buf
					vim.keymap.set("i", "(", function()
						vim.defer_fn(vim.lsp.buf.signature_help, 50)
						return "("
					end, { buffer = buf, expr = true, noremap = true })

					vim.keymap.set("i", ",", function()
						vim.defer_fn(vim.lsp.buf.signature_help, 50)
						return ","
					end, { buffer = buf, expr = true, noremap = true })
				end,
			})

			-- Inlay hints ON by default, toggled with <leader>lh
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					-- Using the fixed colon (:) syntax from earlier
					if client and client:supports_method("textDocument/inlayHint") then
						-- CHANGED: Set this to true to enable them automatically
						vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
					end
				end,
			})
		end,
	},

	-- Autocompletion
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-vsnip",
			"hrsh7th/vim-vsnip",
			"hrsh7th/cmp-calc",
			"onsails/lspkind.nvim",
			"lukas-reineke/cmp-under-comparator",
			"windwp/nvim-autopairs",
		},
		config = function()
			local custom_menu_icon = {
				nvim_lsp = "",
				vsnip = "",
				calc = "󰃬",
			}

			require("nvim-autopairs").setup({})
			local cmp_autopairs = require("nvim-autopairs.completion.cmp")
			local cmp = require("cmp")
			cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

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
					-- CHANGED: <Tab> confirms so <CR> is free for a plain newline
					["<Tab>"] = cmp.mapping.confirm({
						behavior = cmp.ConfirmBehavior.Replace,
						select = true,
					}),
					["<CR>"] = cmp.mapping(function(fallback)
						if cmp.visible() and cmp.get_active_entry() then
							cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
						else
							fallback()
						end
					end, { "i", "s" }),
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
					-- CHANGED: show docs alongside the completion menu
					documentation = cmp.config.window.bordered(),
				},
			})

			cmp.setup.filetype("gitcommit", {
				sources = cmp.config.sources({
					{ name = "git" },
				}, {
					{ name = "buffer" },
				}),
			})
		end,
	},

	-- Notifications / LSP progress
	{
		"j-hui/fidget.nvim",
		event = "LspAttach",
		opts = {},
	},

	-- Pretty, non-blocking notifications (used by noice + plugins that call vim.notify)
	{
		"rcarriga/nvim-notify",
		opts = {
			timeout = 3000,
			render = "compact",
			stages = "fade",
			-- leaf.nvim runs with a transparent Normal background, so notify
			-- has nothing to sample for its fade-out colour; give it one
			-- explicitly to silence the "no background highlight" warning.
			background_colour = "#1a1a1a",
		},
		config = function(_, opts)
			local notify = require("notify")
			notify.setup(opts)
			vim.notify = notify
		end,
	},

	-- Replaces the cmdline/messages area with floating, readable UI
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		dependencies = { "MunifTanjim/nui.nvim", "rcarriga/nvim-notify" },
		opts = {
			lsp = {
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
					["cmp.entry.get_documentation"] = true,
				},
			},
			presets = {
				bottom_search = true,
				command_palette = true,
				long_message_to_split = true,
				lsp_doc_border = true,
			},
		},
	},

	-- Nicer vim.ui.select / vim.ui.input (rename, code actions, etc.)
	{
		"stevearc/dressing.nvim",
		event = "VeryLazy",
		opts = {},
	},

	-- Discoverable keymaps: shows a popup of available bindings as you type
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			preset = "modern",
			delay = 300,
		},
	},

	-- Pretty, navigable diagnostics/references/quickfix list
	{
		"folke/trouble.nvim",
		cmd = "Trouble",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {},
	},

	-- Buffer/tab bar
	{
		"akinsho/bufferline.nvim",
		event = "BufReadPost",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			options = {
				diagnostics = "nvim_lsp",
				separator_style = "thin",
				show_buffer_close_icons = false,
				show_close_icon = false,
				always_show_bufferline = true,
			},
		},
	},

	-- UI
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		event = "BufReadPost",
		opts = {},
	},
	{
		"nvim-telescope/telescope.nvim",
		cmd = "Telescope",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-file-browser.nvim",
		},
		config = function()
			require("telescope").setup({})
			require("telescope").load_extension("file_browser")
		end,
	},
	{
		"tamton-aquib/staline.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("staline").setup({
				defaults = {
					expand_null_ls = false,
					full_path = vim.o.columns >= 128,
					line_column = "[%l/%L] :%c",
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
					lazy = { "Lazy", "💤 " },
				},
				lsp_symbols = {
					Error = " ",
					Info = " ",
					Warn = " ",
					Hint = "󰌵 ",
				},
			})
			require("stabline").setup({
				style = "bar",
				bg = "none",
				fg = "#ffffff",
				exclude_fts = { "Veil", "lazy" },
			})
		end,
	},
	{
		"daschw/leaf.nvim",
		lazy = false,
		priority = 1000,
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
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		event = "BufReadPost",
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
	},
	{
		"willothy/veil.nvim",
		dependencies = {
			"nvim-telescope/telescope.nvim",
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-file-browser.nvim",
		},
		config = function()
			require("veil").setup()
		end,
	},
	{
		"lewis6991/gitsigns.nvim",
		event = "BufReadPre",
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
				watch_gitdir = { follow_files = true },
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
	},

	-- Treesitter
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		lazy = false,
		dependencies = {
			"windwp/nvim-ts-autotag",
			"andymass/vim-matchup",
		},
		opts = {
			ensure_installed = { "lua", "c", "cpp" },
			sync_install = false,
			auto_install = true,
			highlight = {
				enable = true,
				additional_vim_regex_highlighting = false,
			},
			indent = { enable = false },
			incremental_selection = { enable = false },
		},
		config = function(_, opts)
			require("nvim-treesitter.config").setup(opts)
			pcall(function()
				require("nvim-ts-autotag").setup()
				vim.g.matchup_matchparen_offscreen = { method = "popup" }
			end)
		end,
	},

	-- Git
	{ "tpope/vim-fugitive", cmd = { "Git", "G" } },

	-- Editing utilities
	{ "tpope/vim-commentary" },
	{
		"p00f/clangd_extensions.nvim",
		ft = { "c", "cpp" },
		opts = {},
	},
	{
		"stevearc/conform.nvim",
		event = "BufWritePre",
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
	},
	{
		"chentoast/marks.nvim",
		event = "BufReadPost",
		opts = {},
	},
	{ "ThePrimeagen/vim-be-good", cmd = "VimBeGood" },
	{
		"soulis-1256/eagle.nvim",
		opts = {},
	},
	{ "Wansmer/binary-swap.nvim" },
	{ "famiu/bufdelete.nvim" },
	{ "wakatime/vim-wakatime", lazy = false },
	{
		"Saecki/crates.nvim",
		ft = { "toml" },
		opts = {},
	},
}, {
	ui = {
		icons = {
			cmd = "⌘",
			config = "🛠",
			event = "📅",
			ft = "📂",
			init = "⚙",
			keys = "🗝",
			plugin = "🔌",
			runtime = "💻",
			source = "📄",
			start = "🚀",
			task = "📌",
			lazy = "💤 ",
		},
	},
})
