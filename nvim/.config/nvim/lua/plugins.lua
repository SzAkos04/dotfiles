-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
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
			"saghen/blink.cmp", -- capabilities forrása; a dependency biztosítja, hogy rtp-n legyen mire a config() lefut
		},
		config = function()
			require("mason").setup()
			require("mason-lspconfig").setup()

			vim.diagnostic.config({
				underline = true,
				severity_sort = true,
				update_in_insert = false,
				virtual_text = {
					prefix = "●",
					spacing = 4,
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

			-- CHANGED: capabilities most blink.cmp-ből
			local capabilities = require("blink.cmp").get_lsp_capabilities()

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
				local opts = { capabilities = capabilities }
				local ok, conf_opts = pcall(require, "lsp-settings." .. server)
				if ok then
					opts = vim.tbl_deep_extend("force", opts, conf_opts)
				end

				if opts.root_dir ~= nil then
					opts.root_dir = nil
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

			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "c", "cpp", "lua", "python", "rust", "bash", "javascript", "typescript" },
				callback = function(args)
					local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
						or vim.bo[args.buf].filetype
					pcall(vim.treesitter.start, args.buf, lang)
				end,
			})

			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					if client and client:supports_method("textDocument/inlayHint") then
						vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
					end
				end,
			})
		end,
	},

	-- Autocompletion (blink.cmp — nvim-cmp helyett: gyorsabb, natív Lua/Rust fuzzy matcher)
	{
		"saghen/blink.cmp",
		event = "InsertEnter",
		version = "*",
		dependencies = {
			"rafamadriz/friendly-snippets",
			"saghen/blink.compat",
			"hrsh7th/cmp-calc",
		},
		opts = {
			keymap = {
				preset = "none",
				["<C-p>"] = { "select_prev", "fallback" },
				["<C-n>"] = { "select_next", "fallback" },
				["<C-b>"] = { "scroll_documentation_up", "fallback" },
				["<C-f>"] = { "scroll_documentation_down", "fallback" },
				["<C-space>"] = { "show", "fallback" },
				["<C-e>"] = { "hide", "fallback" },
				["<Tab>"] = { "select_and_accept", "fallback" },
				["<CR>"] = { "select_and_accept", "fallback" },
			},
			appearance = {
				nerd_font_variant = "mono",
				use_nvim_cmp_as_default = false, -- CHANGED: már nem kell, catppuccin natívan színez
			},
			completion = {
				accept = { auto_brackets = { enabled = true } },
				documentation = { auto_show = true, auto_show_delay_ms = 200 },
				menu = {
					border = "rounded",
					draw = {
						treesitter = { "lsp" },
						columns = {
							{ "kind_icon" },
							{ "label", "label_description", gap = 1 },
							{ "source_name" },
						},
						components = {
							source_name = {
								width = { max = 4 }, -- CHANGED: rövid kód, nem csonkolt szöveg
								text = function(ctx)
									local short = {
										LSP = "LSP",
										Path = "Path",
										Snippets = "Snip",
										Buffer = "Buf",
										Calc = "Calc",
									}
									return short[ctx.source_name] or ctx.source_name:sub(1, 4)
								end,
								highlight = "BlinkCmpSource",
							},
						},
					},
				},
			},
			signature = { enabled = true },
			cmdline = { enabled = true },
			sources = {
				default = { "lsp", "path", "snippets", "buffer", "calc" },
				providers = {
					calc = { name = "calc", module = "blink.compat.source" },
				},
			},
		},
		-- CHANGED: config function, ami az opts.setup UTÁN explicit
		-- BlinkCmpKind<Kind> színeket ad, mert a leaf.nvim ezt maga nem teszi meg
		config = function(_, opts)
			require("blink.cmp").setup(opts)

			local kind_colors = {
				Function = "#89b4fa",
				Method = "#89b4fa",
				Constructor = "#89b4fa",
				Variable = "#cdd6f4",
				Field = "#cdd6f4",
				Property = "#cdd6f4",
				Class = "#f9e2af",
				Interface = "#f9e2af",
				Struct = "#f9e2af",
				Enum = "#f9e2af",
				EnumMember = "#fab387",
				Keyword = "#cba6f7",
				Snippet = "#a6e3a1",
				Constant = "#fab387",
				Text = "#a6adc8",
				Module = "#94e2d5",
				File = "#94e2d5",
				Folder = "#94e2d5",
				Operator = "#f38ba8",
				Reference = "#f38ba8",
				TypeParameter = "#f9e2af",
				Value = "#fab387",
			}

			local function apply_kind_colors()
				for kind, color in pairs(kind_colors) do
					vim.api.nvim_set_hl(0, "BlinkCmpKind" .. kind, { fg = color })
				end
			end

			apply_kind_colors()
			-- colorscheme-váltás után is megmaradjon
			vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_kind_colors })
		end,
	},

	-- Auto-closing brackets (önállóan; a cmp-integrációs hook már nem kell, ld. auto_brackets fent)
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {},
	},

	{
		"j-hui/fidget.nvim",
		event = "LspAttach",
		opts = {},
	},

	{
		"rcarriga/nvim-notify",
		opts = {
			timeout = 3000,
			render = "compact",
			stages = "fade",
			background_colour = "#1a1a1a",
		},
		config = function(_, opts)
			local notify = require("notify")
			notify.setup(opts)
			vim.notify = notify
		end,
	},

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

	{
		"stevearc/dressing.nvim",
		event = "VeryLazy",
		opts = {},
	},

	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			preset = "modern",
			delay = 300,
		},
	},

	{
		"folke/trouble.nvim",
		cmd = "Trouble",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {},
	},

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
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		event = "VeryLazy",
		opts = {
			options = {
				theme = "catppuccin", -- pixel-pontosan ugyanaz a paletta, mint a colorscheme
				component_separators = "",
				section_separators = { left = "", right = "" },
				globalstatus = true, -- illeszkedik a settings.lua laststatus=3 fixhez
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "branch", "diff" },
				lualine_c = { { "filename", path = 1 } },
				lualine_x = { "diagnostics", "filetype" },
				lualine_y = { "progress" },
				lualine_z = { "location" },
			},
		},
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = false,
		priority = 1000,
		config = function()
			require("catppuccin").setup({
				flavour = "mocha", -- ugyanaz a flavour, amit a tmux/alacritty is használ
				transparent_background = true, -- editor bg átlátszó -> jön át az Alacritty blur
				float = {
					transparent = true, -- a float-ablak MAGA transzparens legyen a "keretén" kívül...
					solid = true, -- ...de a tartalma szilárd hátteret kapjon -> ez oldja meg
					--               a signature-help/completion "átlátszó, szöveg-átüt" bugot
				},
				term_colors = true,
				styles = {
					comments = { "italic" },
					keywords = { "italic" },
					functions = {},
					types = {},
				},
				integrations = {
					blink_cmp = true, -- innentől a blink.cmp kind-ikonjai natívan színesek
					treesitter = true,
					gitsigns = true,
					noice = true,
					notify = true,
					mason = true,
					which_key = true,
					telescope = { enabled = true },
					indent_blankline = { enabled = true, scope_color = "lavender" },
					navic = { enabled = true, custom_bg = "NONE" },
					native_lsp = {
						enabled = true,
						virtual_text = {
							errors = { "italic" },
							hints = { "italic" },
							warnings = { "italic" },
							information = { "italic" },
						},
						underlines = {
							errors = { "underline" },
							hints = { "underline" },
							warnings = { "underline" },
							information = { "underline" },
						},
					},
				},
			})
			vim.cmd("colorscheme catppuccin")
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

	-- Treesitter (CHANGED: lazy=false → event-alapú, gyorsabb induláshoz)
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },
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

	{ "tpope/vim-fugitive", cmd = { "Git", "G" } },

	-- CHANGED: vim-commentary törölve — Neovim 0.10+ natívan tudja a gc/gcc-t

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
	-- CHANGED: eagle.nvim törölve (redundáns a saját CursorMoved diagnosztika-floattal)
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
