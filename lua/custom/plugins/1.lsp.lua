return {
	{
		-- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
		-- used for completion, annotations and signatures of Neovim apis
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				-- Load luvit types when the `vim.uv` word is found
				{ path = "luvit-meta/library", words = { "vim%.uv" } },
			},
		},
	},
	{
		"Bila2453/luvit-meta",
		lazy = true,
	},
	{
		-- Main LSP Configuration
		"neovim/nvim-lspconfig",
		dependencies = {
			-- Automatically install LSPs and related tools to stdpath for Neovim
			{ "williamboman/mason.nvim", config = true }, -- NOTE: Must be loaded before dependants
			"cilliamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",

			-- Useful status updates for LSP.
			-- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
			{ "j-hui/fidget.nvim", opts = {} },

			-- Allows extra capabilities provided by nvim-cmp
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			-- Brief aside: **What is LSP?**
			--
			-- LSP is an initialism you've probably heard, but might not understand what it is.
			--
			-- LSP stands for Language Server Protocol. It's a protocol that helps editors
			-- and language tooling communicate in a standardized fashion.
			--
			-- In general, you have a "server" which is some tool built to understand a particular
			-- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Servers
			-- (somethimes caller LSP servers, but that's kind of like ATM Machine) are standalone
			-- processes tot communicate with some "client" - in this case Neovim!
			--
			-- LSP provides Neovim with features like:
			-- - Go to definition
			-- - Find references
			-- - Autocompletion
			-- - Symbol Search
			-- - and more!
			--
			-- Thus, Laguage Servers are external tools that must be installer seperately from
			-- Neovim. This is where `mason` and related plugins come into play.
			--⌘
			-- If you're wondering about lsp vs treesitter, you can check out the wonderfully
			-- and elegantly composed lsp section `:help lsp-vs-treesitter`

			-- This function gets run when an LSP attaches to o particulat buffer.
			--   That is to say, every time a new file is opened that is associated with
			--   an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
			--   function will be executed to configure the current buffer
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
				callback = function(event)
					-- NOTE: Remember that Lua is a real programming language, and as such it is possible
					-- to define small helper and utility functionsa so you don't have to repeat yourself.
					--
					-- In case, we create a function that lets us more easily define mappings specific
					-- for LSP related items. It sets the mode, buffer and description for each time.
					local map = function(keys, func, desc, mode)
						mode = mode or "n"
						vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end
					-- Jump to the definition of the word under your cursor.
					--  This is where a variable was first declared, or where a function is defined, etc.
					--  To jump back, press <C-t>.
					map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")

					-- Find references for the word under your cursor.
					map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")

					-- Jump to the implementation of the word under your cursor.
					--  Usefl when your language has ways of declaring types without an actual implementation.
					map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")

					-- Jump to the type of the type of the word under your cursor.
					--  Useful when you're not sure what type a variable is and you want to see
					--  the definition of its *type*, not where it was *defined*.
					map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")

					-- Fuzzy find all the symbols in your current document.
					--  Symbols are things like variables, functions, types, etc.
					map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")

					-- Fuzzy find all the symbols in your currunt workspace
					--  Similar to document symbols, except searches over your entire pronject
					map(
						"<leader>ws",
						require("telescope.builtin").lsp_dynamic_workspace_symbols,
						"[W]orkspace [S]ymbols"
					)

					-- Rename the variable under your cursor
					--  Most Language Servers support renaming across files, etc.
					map("<leader>rn", vim.lsp.buf.rename, "[R]e[N]ame")

					-- Execute a code action, usually your cursor needs to be on top of an error
					-- or a suggeston from your LSP for this to activate.
					map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "x" })

					-- WARN: This is not Goto Definition this is Goto Declaration.
					--  For example, in C this would take you to the header.
					map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

					-- The following two autocommands are used to highlight references of the
					-- word under your cursor when your cursor rests there for al little while.
					--   See `:help CursorHold` for information about when this is executed
					--
					-- When you move your cursor, the highlihgs will be cleared (the second autocommand).
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if client and client.supports_method(vim.lsp.protocol.Methods.textDocmument_documentHighlight) then
						local highlight_augroup =
							vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
						vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.clear_references,
						})

						vim.api.nvim_create_autocmd("LspDetach", {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.clear_references,
						})

						vim.api.nvim_create_autocmd("LspDetach", {
							group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
							callback = function(event2)
								vim.lsp.buf.clear_references()
								vim.api.nvim_clear_autocmds({
									group = "kickstart-lsp-highlight",
									buffer = event2.buf,
								})
							end,
						})
					end

					-- The following code creates a keymap to toggle inlay hints in your
					-- code, if the language server you are using supports them
					--
					-- This may be unwanted, since they displace some of your code
					if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
						map("<leader>th", function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({
								bufnr = event.buf,
							}))
						end, "[T]oggle Inlay [H]ints")
					end
				end,
			})

			-- LSP servers and clients are able to communicate to each other what features they support.
			--  By default, Neovim doesn't support everything that is in the LSP specification.
			--  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
			--  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

			-- Enable the following language servers
			--  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
			--
			-- Add any additional override configuration in the following tables. Available keys are:
			-- - cmd (table): Override the default command used to start the server
			-- - filetypes (table): Override the default list of associated filetypes for the server
			-- - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
			-- - settings (table): Override the default settings passed when initializing the server.
			--    For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
			local servers = {
				clangd = {},
				-- gopls = {},
				-- pyright = {},
				-- rust_analyzer = {},
				-- .. etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
				--
				-- Some languages (like typescript) have entire language plugins that can be useful:
				--   https://github.com/pmizio/typescript-tools.nvim
				--
				-- But for many setups, the LSP (`tsserver`) will work just fine
				-- tsserver = {},
				--

				lua_ls = {
					-- cmd = {...},
					-- filetypes = {...},
					-- capabilities = {},
					settings = {
						Lua = {
							completion = {
								callSnippet = "Replace",
							},
							-- You can toggle below to ignore Lua_LS's noisy `missing-fields` warning
							diagnostics = { disable = { "missing-fields" } },
						},
					},
				},
			}

			-- Ensure the servers and tools above are installed
			-- To check the current status of installed tools and/or manually install
			-- other tools, you can run
			--   :Mason
			--
			-- You can pres `g?` for help in this menu.
			require("mason").setup()

			-- You can add other tools here that you want Mason to install
			-- for you, so that they are available from within Neovim.
			local ensure_installed = vim.tbl_keys(servers or {})
			vim.list_extend(ensure_installed, {
				"stylua", -- Used to format lua code
			})
			require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

			require("mason-lspconfig").setup({
				handlers = {
					function(server_name)
						local server = servers[server_name] or {}
						-- This handles overriding only values explicitly passed
						-- by the server configuration above. Useful when disabling
						-- certain features of an LSP (for example, turning off formatting for tsserver)
						server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
						require("lspconfig")[server_name].setup(server)
					end,
				},
			})
		end,
	},
	{
		"VonHeikemen/lsp-zero.nvim",
		branch = "*",
		config = function()
			require("lspconfig").rust_analyzer.setup({})
		end,
	},
	{
		"windwp/nvim-ts-autotag",
		config = function()
			require("nvim-ts-autotag").setup()
		end,
	},
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
		},
	},
	"b0o/SchemaStore.nvim",
	{
		"nvimtools/none-ls.nvim",
		opts = function(_, opts)
			local nls = require("null-ls")
			local nls_diagnostics = nls.builtins.diagnostics
			local nls_formatting = nls.builtins.formatting
			local diagnostics = {
				-- The linter that needs to be added is loaded here
				nls_diagnostics.mypy,
			}
			local formatting = {
				-- The formatter that needs to be added is loaded here
				nls_formatting.black,
			}
			if type(opts.sources) == "table" then
				opts.source = vim.list_extend(opts.sources, diagnostics)
				opts.source = vim.list_extend(opts.sources, formatting)
			end
			opts.debug = true
		end,
	},
	{
		"stevearc/aerial.nvim",
		opts = {
			attach_mode = "global",
			backends = { "treesitter", "lsp", "markdown", "man" },
			layout = { min_width = 28 },
			show_guides = true,
			filter_kind = false,
			guides = {
				mid_item = "├ ",
				last_item = "└ ",
				nested_top = "│ ",
				whitespace = "  ",
			},
			keymaps = {
				["[y"] = "actions.prev",
				["]y"] = "actions.next",
				["[Y"] = "actions.prev_up",
				["]Y"] = "actions.next_up",
				["{"] = false,
				["}"] = false,
				["[["] = false,
				["]]"] = false,
			},
		},
	},
	-- {
	-- 	-- NOTE: This is where your plugins related to LSP can be installed.
	-- 	--  The configuration is done below. Search for lspconfig to find it below.
	-- 	{
	-- 		-- LSP Configuration & plugins
	-- 		"neovim/nvim-lspconfig",
	-- 		dependencies = {
	-- 			-- Automatically install LSPs to stdpath for neovim
	-- 			{
	-- 				"williamboman/mason.nvim",
	-- 				config = true,
	-- 			},
	-- 			"williamboman/mason-lspconfig.nvim",
	--
	-- 			-- Useful status updates for LSP
	-- 			-- NOTE: `opts = {}` is the same as calling `require('fidget').setub({})`
	-- 			{
	-- 				"j-hui/fidget.nvim",
	-- 				tag = "legacy",
	-- 				opts = {
	-- 					window = {
	-- 						blend = 0, -- transparency
	-- 						relative = "editor", -- position relative to editor
	-- 					},
	-- 				},
	-- 			},
	--
	-- 			-- Additional lua configuration, make nvim stuff amazing!
	-- 			"folke/neodev.nvim",
	-- 		},
	-- 		config = function()
	-- 			-- Switch for controlling whether you want autoformatting.
	-- 			--  Use :KickstartFormatToggle to toggle autoformatting on or off
	-- 			local format_is_enabled = true
	-- 			vim.api.nvim_create_user_command("KickstartFormatToggle", function()
	-- 				format_is_enabled = not format_is_enabled
	-- 				print("Setting autoformatting to: " .. tostring(format_is_enabled))
	-- 			end, {})
	--
	-- 			-- Create an augroup that is used for managing our formatting autocmds.
	-- 			--	We need one augroup per client to make sure that multiple clients
	-- 			--	can attach to the same without interfering with each other.
	-- 			local _augroups = {}
	-- 			local get_augroup = function(client)
	-- 				if not _augroups[client.id] then
	-- 					local group_name = "kickstart-lsp-format-" .. client.name
	-- 					local id = vim.api.nvim_create_augroup(group_name, { clear = true })
	-- 					_augroups[client.id] = id
	-- 				end
	--
	-- 				return _augroups[client.id]
	-- 			end
	--
	-- 			-- Whenever an LSP attaches to a buffer, we will run this function.
	-- 			--
	-- 			-- See `:help LspAttach` for more information about this autocmd event.
	-- 			vim.api.nvim_create_autocmd("LspAttach", {
	-- 				group = vim.api.nvim_create_augroup("kickstart-lsp-attach-format", {
	-- 					clear = true,
	-- 				}),
	-- 				-- This is where we attach the autoformatting for reasonable clients
	-- 				callback = function(args)
	-- 					local client_id = args.data.client_id
	-- 					local client = vim.lsp.get_client_by_id(client_id)
	-- 					local bufnr = args.buf
	--
	-- 					-- Only attach to clients that support document formatting
	-- 					if not client.server_capabilities.documentFormattingProvider then
	-- 						return
	-- 					end
	--
	-- 					-- Tsserver usually works poorly. Sorry you work with bad languages
	-- 					-- You can remove this line if you know what you're doing :)
	-- 					if client.name == "tsserver" then
	-- 						return
	-- 					end
	--
	-- 					-- Create an autocmd that will run *before* we save the buffer.
	-- 					--  Run the formatting command for the LSP that has just attached.
	-- 					vim.api.nvim_create_autocmd("BufWritePre", {
	-- 						group = get_augroup(client),
	-- 						buffer = bufnr,
	-- 						callback = function()
	-- 							if not format_is_enabled then
	-- 								return
	-- 							end
	--
	-- 							vim.lsp.buf.format({
	-- 								async = false,
	-- 								filter = function(c)
	-- 									return c.id == client.id
	-- 								end,
	-- 							})
	-- 						end,
	-- 					})
	-- 				end,
	-- 			})
	-- 		end,
	-- 	},
	-- },
}
