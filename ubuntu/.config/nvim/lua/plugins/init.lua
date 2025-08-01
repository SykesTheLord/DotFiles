-- lua/plugins/init.lua
return {

    -- **Plugin Manager and Dependencies**

    -- Lazy.nvim manages itself (already bootstrapped in init.lua)
    { "folke/lazy.nvim",         lazy = true },

    -- **Colorscheme** (with high priority so it loads first)
    {
        "AlexvZyl/nordic.nvim",
        lazy = false,
        priority = 1000,
        config = function()
            require("nordic").load()
        end,
    },
    {
        "folke/snacks.nvim",
        priority = 1001,
        lazy = false,
        ---@type snacks.Config
        opts = {
            bigfile = { enabled = true },
            dashboard = {
                enabled = true,
                preset = {
                    pick = function(cmd, opts)
                        return LazyVim.pick(cmd, opts)()
                    end,
                    ---@type snacks.dashboard.Item[]
                    keys = {
                        {
                            icon = " ",
                            key = "f",
                            desc = "Find File",
                            action = ":lua Snacks.dashboard.pick('files')",
                        },
                        { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
                        {
                            icon = " ",
                            key = "g",
                            desc = "Find Text",
                            action = ":lua Snacks.dashboard.pick('live_grep')",
                        },
                        {
                            icon = " ",
                            key = "r",
                            desc = "Recent Files",
                            action = ":lua Snacks.dashboard.pick('oldfiles')",
                        },
                        {
                            icon = " ",
                            key = "c",
                            desc = "Config",
                            action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
                        },
                        { icon = " ", key = "s", desc = "Restore Session", section = "session" },
                        { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
                        { icon = " ", key = "q", desc = "Quit", action = ":qa" },
                    },
                },
            },
            explorer = { enabled = true },
            indent = { enabled = true },
            input = { enabled = true },
            notifier = {
                enabled = true,
                timeout = 3000,
            },
            picker = { enabled = true },
            quickfile = { enabled = true },
            scope = { enabled = true },
            scroll = { enabled = true },
            statuscolumn = { enabled = true },
            words = { enabled = true },
            styles = {
                notification = {
                    -- wo = { wrap = true } -- Wrap notifications
                },
            },
        },
        keys = {
            -- Top Pickers & Explorer
            -- Snacks core pickers -----------------------------------------------------
            {
                "<leader><space>",
                function()
                    Snacks.picker.smart()
                end,
                desc = "Smart Find Files",
            },
            {
                "<leader>,",
                function()
                    Snacks.picker.buffers()
                end,
                desc = "Buffers",
            },
            {
                "<leader>/",
                function()
                    Snacks.picker.grep()
                end,
                desc = "Grep",
            },
            {
                "<leader>:",
                function()
                    Snacks.picker.command_history()
                end,
                desc = "Command History",
            },
            {
                "<leader>n",
                function()
                    Snacks.picker.notifications()
                end,
                desc = "Notification History",
            },

            -- File/Explorer -----------------------------------------------------------
            -- {
            -- 	"<leader>e",
            -- 	function()
            --		Snacks.explorer()
            --	end,
            --	desc = "File Explorer",
            -- },
            {
                "<leader>fc",
                function()
                    Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
                end,
                desc = "Find Config File",
            },
            {
                "<leader>ff",
                function()
                    Snacks.picker.files()
                end,
                desc = "Find Files",
            },
            {
                "<leader>fg",
                function()
                    Snacks.picker.git_files()
                end,
                desc = "Find Git Files",
            },
            {
                "<leader>fp",
                function()
                    Snacks.picker.projects()
                end,
                desc = "Projects",
            },
            {
                "<leader>fr",
                function()
                    Snacks.picker.recent()
                end,
                desc = "Recent",
            },
            {
                "<leader>fb",
                function()
                    Snacks.picker.buffers()
                end,
                desc = "Buffers",
            },

            -- Git ---------------------------------------------------------------------
            {
                "<leader>gb",
                function()
                    Snacks.picker.git_branches()
                end,
                desc = "Git Branches",
            },
            {
                "<leader>gl",
                function()
                    Snacks.picker.git_log()
                end,
                desc = "Git Log",
            },
            {
                "<leader>gL",
                function()
                    Snacks.picker.git_log_line()
                end,
                desc = "Git Log Line",
            },
            {
                "<leader>gs",
                function()
                    Snacks.picker.git_status()
                end,
                desc = "Git Status",
            },
            {
                "<leader>gS",
                function()
                    Snacks.picker.git_stash()
                end,
                desc = "Git Stash",
            },
            {
                "<leader>gd",
                function()
                    Snacks.picker.git_diff()
                end,
                desc = "Git Diff (Hunks)",
            },
            {
                "<leader>gf",
                function()
                    Snacks.picker.git_log_file()
                end,
                desc = "Git Log File",
            },

            -- Grep / Search -----------------------------------------------------------
            {
                "<leader>sb",
                function()
                    Snacks.picker.lines()
                end,
                desc = "Buffer Lines",
            },
            {
                "<leader>sB",
                function()
                    Snacks.picker.grep_buffers()
                end,
                desc = "Grep Open Buffers",
            },
            {
                "<leader>sg",
                function()
                    Snacks.picker.grep()
                end,
                desc = "Grep",
            },
            {
                "<leader>sw",
                function()
                    Snacks.picker.grep_word()
                end,
                desc = "Visual selection/word",
                mode = { "n", "x" },
            },

            -- Misc search helpers -----------------------------------------------------
            {
                '<leader>s"',
                function()
                    Snacks.picker.registers()
                end,
                desc = "Registers",
            },
            {
                "<leader>s/",
                function()
                    Snacks.picker.search_history()
                end,
                desc = "Search History",
            },
            {
                "<leader>sa",
                function()
                    Snacks.picker.autocmds()
                end,
                desc = "Autocmds",
            },
            {
                "<leader>sc",
                function()
                    Snacks.picker.command_history()
                end,
                desc = "Command History",
            },
            {
                "<leader>sC",
                function()
                    Snacks.picker.commands()
                end,
                desc = "Commands",
            },
            {
                "<leader>sd",
                function()
                    Snacks.picker.diagnostics()
                end,
                desc = "Diagnostics",
            },
            {
                "<leader>sD",
                function()
                    Snacks.picker.diagnostics_buffer()
                end,
                desc = "Buffer Diagnostics",
            },
            {
                "<leader>sh",
                function()
                    Snacks.picker.help()
                end,
                desc = "Help Pages",
            },
            {
                "<leader>sH",
                function()
                    Snacks.picker.highlights()
                end,
                desc = "Highlights",
            },
            {
                "<leader>si",
                function()
                    Snacks.picker.icons()
                end,
                desc = "Icons",
            },
            {
                "<leader>sj",
                function()
                    Snacks.picker.jumps()
                end,
                desc = "Jumps",
            },
            {
                "<leader>sk",
                function()
                    Snacks.picker.keymaps()
                end,
                desc = "Keymaps",
            },
            {
                "<leader>sl",
                function()
                    Snacks.picker.loclist()
                end,
                desc = "Location List",
            },
            {
                "<leader>sm",
                function()
                    Snacks.picker.marks()
                end,
                desc = "Marks",
            },
            {
                "<leader>sM",
                function()
                    Snacks.picker.man()
                end,
                desc = "Man Pages",
            },
            {
                "<leader>sp",
                function()
                    Snacks.picker.lazy()
                end,
                desc = "Plugin Specs",
            },
            {
                "<leader>sq",
                function()
                    Snacks.picker.qflist()
                end,
                desc = "Quickfix List",
            },
            {
                "<leader>sR",
                function()
                    Snacks.picker.resume()
                end,
                desc = "Resume",
            },
            {
                "<leader>su",
                function()
                    Snacks.picker.undo()
                end,
                desc = "Undo History",
            },

            -- Colourschemes -----------------------------------------------------------
            {
                "<leader>uC",
                function()
                    Snacks.picker.colorschemes()
                end,
                desc = "Colourschemes",
            },

            -- LSP ----------------------------------------------------------------------
            {
                "gd",
                function()
                    Snacks.picker.lsp_definitions()
                end,
                desc = "Goto Definition",
            },
            {
                "gD",
                function()
                    Snacks.picker.lsp_declarations()
                end,
                desc = "Goto Declaration",
            },
            {
                "gr",
                function()
                    Snacks.picker.lsp_references()
                end,
                desc = "References",
                nowait = true,
            },
            {
                "gI",
                function()
                    Snacks.picker.lsp_implementations()
                end,
                desc = "Goto Implementation",
            },
            {
                "gy",
                function()
                    Snacks.picker.lsp_type_definitions()
                end,
                desc = "Goto Type Definition",
            },
            {
                "<leader>ss",
                function()
                    Snacks.picker.lsp_symbols()
                end,
                desc = "LSP Symbols",
            },
            {
                "<leader>sS",
                function()
                    Snacks.picker.lsp_workspace_symbols()
                end,
                desc = "Workspace Symbols",
            },

            -- Miscellaneous ------------------------------------------------------------
            {
                "<leader>z",
                function()
                    Snacks.zen()
                end,
                desc = "Toggle Zen Mode",
            },
            {
                "<leader>Z",
                function()
                    Snacks.zen.zoom()
                end,
                desc = "Toggle Zoom",
            },
            {
                "<leader>.",
                function()
                    Snacks.scratch()
                end,
                desc = "Toggle Scratch Buffer",
            },
            {
                "<leader>S",
                function()
                    Snacks.scratch.select()
                end,
                desc = "Select Scratch Buffer",
            },
            {
                "<leader>bd",
                function()
                    Snacks.bufdelete()
                end,
                desc = "Delete Buffer",
            },
            {
                "<leader>cR",
                function()
                    Snacks.rename.rename_file()
                end,
                desc = "Rename File",
            },
            {
                "<leader>gB",
                function()
                    Snacks.gitbrowse()
                end,
                desc = "Git Browse",
                mode = { "n", "v" },
            },

            -- Notifications / terminal / word‑motions ---------------------------------
            {
                "<leader>un",
                function()
                    Snacks.notifier.hide()
                end,
                desc = "Dismiss All Notifications",
            },
            {
                "<c-/>",
                function()
                    Snacks.terminal()
                end,
                desc = "Toggle Terminal",
            },
            {
                "<c-_>",
                function()
                    Snacks.terminal()
                end,
                desc = "which_key_ignore",
            },
            {
                "]]",
                function()
                    Snacks.words.jump(vim.v.count1)
                end,
                desc = "Next Reference",
                mode = { "n", "t" },
            },
            {
                "[[",
                function()
                    Snacks.words.jump(-vim.v.count1)
                end,
                desc = "Prev Reference",
                mode = { "n", "t" },
            },

            -- Neovim NEWS window -------------------------------------------------------
            {
                "<leader>N",
                function()
                    Snacks.win({
                        file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
                        width = 0.6,
                        height = 0.6,
                        wo = {
                            spell = false,
                            wrap = false,
                            signcolumn = "yes",
                            statuscolumn = " ",
                            conceallevel = 3,
                        },
                    })
                end,
                desc = "Neovim News",
            },
        },

        init = function()
            vim.api.nvim_create_autocmd("User", {
                pattern = "VeryLazy",
                callback = function()
                    -- Setup some globals for debugging (lazy-loaded)
                    _G.dd = function(...)
                        Snacks.debug.inspect(...)
                    end
                    _G.bt = function()
                        Snacks.debug.backtrace()
                    end
                    vim.print = _G.dd -- Override print to use snacks for `:=` command

                    -- Create some toggle mappings
                    Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
                    Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
                    Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
                    Snacks.toggle.diagnostics():map("<leader>ud")
                    Snacks.toggle.line_number():map("<leader>ul")
                    Snacks.toggle
                        .option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
                        :map("<leader>uc")
                    Snacks.toggle.treesitter():map("<leader>uT")
                    Snacks.toggle.inlay_hints():map("<leader>uh")
                    Snacks.toggle.indent():map("<leader>ug")
                    Snacks.toggle.dim():map("<leader>uD")
                end,
            })
        end,
    },
    { "akinsho/bufferline.nvim", version = "*", dependencies = "nvim-tree/nvim-web-devicons" },
    -- **File Explorer** (Neo-tree as NERDTree replacement)
    -- If you want neo-tree's file operations to work with LSP (updating imports, etc.), you can use a plugin like
    -- https://github.com/antosha417/nvim-lsp-file-operations:
    {
        "antosha417/nvim-lsp-file-operations",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-neo-tree/neo-tree.nvim",
        },
        config = function()
            require("lsp-file-operations").setup()
        end,
    },
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
            "MunifTanjim/nui.nvim",
            {
                "s1n7ax/nvim-window-picker",
                version = "2.*",
                config = function()
                    require("window-picker").setup({
                        filter_rules = {
                            include_current_win = false,
                            autoselect_one = true,
                            bo = {
                                filetype = { "neo-tree", "neo-tree-popup", "notify" },
                                buftype = { "terminal", "quickfix" },
                            },
                        },
                    })
                end,
            },
        },
        lazy = false,
        config = function()
            local ft_list = {
                "python",
                "java",
                "cs",
                "c",
                "cpp",
                "javascript",
                "typescript",
                "sh",
                "lua",
                "ps1",
            }

            local group = vim.api.nvim_create_augroup("NeotreeDocumentSymbols", { clear = true })
            vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
                group = group,
                callback = function()
                    local ft = vim.bo.filetype
                    if vim.tbl_contains(ft_list, ft) and not vim.b.neotree_symbols_shown then
                        local cur_win = vim.api.nvim_get_current_win()

                        -- open/reveal the document_symbols pane on the right
                        require("neo-tree.command").execute({
                            source = "document_symbols",
                            position = "right",
                            toggle = false,
                            focus = false,
                        })

                        -- schedule a restore only if cur_win is a valid win ID
                        vim.schedule(function()
                            if type(cur_win) == "number" and vim.api.nvim_win_is_valid(cur_win) then
                                vim.api.nvim_set_current_win(cur_win)
                            end
                        end)

                        vim.b.neotree_symbols_shown = true
                    end
                end,
            })

            require("configs.neotreeConfig")
        end,
    },
    -- LSP and Autocompletion
    {
        "neovim/nvim-lspconfig", -- Core LSP support
        dependencies = {
            -- Mason to install LSP servers:contentReference[oaicite:12]{index=12}
            { "williamboman/mason.nvim", config = true },
            {
                "williamboman/mason-lspconfig.nvim",
                config = function()
                    require("mason-lspconfig").setup({
                        ensure_installed = {
                            "clangd",
                            "eslint",
                            "jedi_language_server",
                            "jsonls",
                            "yamlls",
                            -- "omnisharp", -- (Handled separately below)
                            "terraformls",
                            "dockerls",
                            "bashls",
                            "docker_compose_language_service",
                            "jdtls",
                            "lua_ls",
                            "marksman",
                            "powershell_es",
                            "cmake",
                            "vimls",
                            "bicep",
                            "sqls",
                        },
                        automatic_installation = true,
                    })

                    -- Force CSharp-ls version
                    local registry = require("mason-registry")
                    local pkg = registry.get_package("csharp-language-server")
                    if not pkg:is_installed() then
                        pkg:install({ version = "0.16.0" })
                    end
                end,
            },
            {
                "WhoIsSethDaniel/mason-tool-installer.nvim",
                config = function()
                    require("mason-tool-installer").setup({
                        ensure_installed = {
                            "trivy",              -- Linter for Various issues
                            "csharpier",          -- C# formatter
                            "netcoredbg",         -- C# debugger
                            "black",              -- Python formatter
                            "debugpy",            -- Python debugger
                            "pylint",             -- Python Linter
                            "eslint_d",           -- Javascript and TypeScript linter
                            "jsonlint",           -- JSON linter
                            "beautysh",           -- Bash, Csh, Zsh formatter
                            "shellcheck",         -- Bash linter
                            "prettierd",          -- Angular, CSS, Flow, GraphQL, HTML, JSON, JSX, JavaScript, LESS, Markdown, SCSS, TypeScript, Vue, and YAML formatter
                            "java-debug-adapter", -- Java debugger
                            "clang-format",       -- C, C++, JSON, Java, and JavaScript formatter
                            "stylua",             -- Lua formatter
                            "luacheck",           -- Lua Linter
                            "cmakelang",          -- CMake formatter and linter
                            "sqlfluff",           -- SQL linter
                            "sql-formatter",      -- SQL formatter
                            "vale",               -- Markdown linter
                            "tfsec",              -- Terraform linter
                            "cpplint",            -- C++ linter
                            "cmakelint",          -- CMake linter
                            "htmlhint",           -- HTML linter
                            "checkstyle",         -- Java linter
                            "cpptools",           -- C. C++ and Rust debuggecpptools' -- C. C++ and Rust debugger
                        },
                        automatic_installation = true,
                        auto_update = true,
                    })
                end,
            },
            {
                "RaafatTurki/corn.nvim",
                config = function()
                    require("configs.cornConfig")
                end,
            },
            "hrsh7th/cmp-nvim-lsp", -- LSP source for nvim-cmp
            "Decodetalkers/csharpls-extended-lsp.nvim",
        },
        config = function()
            require("lsp")
        end,                                                                -- run our LSP setup (in lsp.lua)
    },
    { "simrat39/rust-tools.nvim", dependencies = "neovim/nvim-lspconfig" }, -- Rust enhanced LSP

    -- Autocompletion plugins (nvim-cmp and sources)
    {
        "hrsh7th/nvim-cmp",
        event = "InsertEnter",
        dependencies = {
            "L3MON4D3/LuaSnip",                   -- snippet engine
            "saadparwaiz1/cmp_luasnip",           -- snippet completions
            "hrsh7th/cmp-buffer",                 -- buffer completions
            "hrsh7th/cmp-path",                   -- filesystem path completions
            "rafamadriz/friendly-snippets",       -- snippet collection
            "lukas-reineke/cmp-under-comparator", -- rearrange comparator
        },
        config = function()
            local cmp = require("cmp")
            local luasnip = require("luasnip")
            require("luasnip.loaders.from_vscode").lazy_load() -- load friendly-snippets
            local lsp_util = require("lspconfig.util")
            local function get_project_root()
                return lsp_util.root_pattern(".git", "package.json", "pyproject.toml", "setup.py")(vim.fn.expand("%:p"))
                    or vim.fn.getcwd()
            end
            cmp.setup({
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<CR>"] = cmp.mapping.confirm({ select = true }),
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                        elseif luasnip.expand_or_jumpable() then
                            luasnip.expand_or_jump()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                    { name = "buffer" },
                    { name = "path",                   option = { get_cwd = get_project_root } },
                    { name = "sql" },
                    { name = "nvim_lsp_signature_help" },
                }),
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
            })
            -- Setup command-line (:) completion for NeoVim commands.
            cmp.setup.cmdline(":", {
                mapping = cmp.mapping.preset.cmdline(),
                sources = cmp.config.sources({
                    { name = "path", option = { get_cwd = get_project_root } },
                }, {
                    { name = "cmdline", option = { ignore_cmds = { "Man", "!" } } },
                }),
            })
        end,
    },

    -- **Treesitter** for syntax highlighting and more
    {
        "nvim-treesitter/nvim-treesitter",
        version = false,             -- last release is way too old and doesn't work on Windows
        build = ":TSUpdate",
        lazy = vim.fn.argc(-1) == 0, -- load treesitter early when opening a file from the cmdline
        init = function(plugin)
            -- PERF: add nvim-treesitter queries to the rtp and it's custom query predicates early
            -- This is needed because a bunch of plugins no longer `require("nvim-treesitter")`, which
            -- no longer trigger the **nvim-treesitter** module to be loaded in time.
            -- Luckily, the only things that those plugins need are the custom queries, which we make available
            -- during startup.
            require("lazy.core.loader").add_to_rtp(plugin)
            require("nvim-treesitter.query_predicates")
        end,
        cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
        keys = {
            { "<c-space>", desc = "Increment Selection" },
            { "<bs>",      desc = "Decrement Selection", mode = "x" },
        },
        opts_extend = { "ensure_installed" },
        ---@type TSConfig
        ---@diagnostic disable-next-line: missing-fields
        opts = {
            highlight = { enable = true },
            indent = { enable = true },
            ensure_installed = {
                "bash",
                "c",
                "diff",
                "html",
                "javascript",
                "jsdoc",
                "json",
                "jsonc",
                "lua",
                "luadoc",
                "luap",
                "markdown",
                "markdown_inline",
                "printf",
                "python",
                "query",
                "regex",
                "toml",
                "tsx",
                "typescript",
                "vim",
                "vimdoc",
                "xml",
                "yaml",
            },
            incremental_selection = {
                enable = true,
                keymaps = {
                    init_selection = "<C-space>",
                    node_incremental = "<C-space>",
                    scope_incremental = false,
                    node_decremental = "<bs>",
                },
            },
            textobjects = {
                move = {
                    enable = true,
                    goto_next_start = {
                        ["]f"] = "@function.outer",
                        ["]c"] = "@class.outer",
                        ["]a"] = "@parameter.inner",
                    },
                    goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer", ["]A"] = "@parameter.inner" },
                    goto_previous_start = {
                        ["[f"] = "@function.outer",
                        ["[c"] = "@class.outer",
                        ["[a"] = "@parameter.inner",
                    },
                    goto_previous_end = {
                        ["[F"] = "@function.outer",
                        ["[C"] = "@class.outer",
                        ["[A"] = "@parameter.inner",
                    },
                },
            },
        },
    },
    {
        "nvim-treesitter/nvim-treesitter-context",
        opts = function()
            local tsc = require("treesitter-context")
            return { mode = "cursor", max_lines = 3 }
        end,
    },
    -- DAP config
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            "rcarriga/nvim-dap-ui",
            dependencies = "nvim-neotest/nvim-nio",
            config = function()
                require("dapui").setup()
            end,
        },
        config = function()
            require("configs.nvimDapConfig")
        end,
    },
    {
        "Weissle/persistent-breakpoints.nvim",
        config = function()
            require("persistent-breakpoints").setup({
                load_breakpoints_event = { "BufReadPost" },
            })
        end,
    },

    {
        "mhartington/formatter.nvim",
        config = function()
            require("formatterConf")
        end,
    },

    -- Linter
    {
        "mfussenegger/nvim-lint",
        dependencies = "aquasecurity/vim-trivy",
        config = function()
            require("lint").linters_by_ft = {
                markdown = { "vale" },
                cs = { "trivy" },
                terraform = { "tfsec", "trivy" },
                c = { "trivy" },
                cpp = { "trivy", "cpplint" },
                cmake = { "cmakelint" },
                html = { "htmlhint" },
                java = { "checkstyle", "trivy" },
                javascript = { "eslint_d" },
                typescript = { "eslint_d" },
                json = { "jsonlint" },
                python = { "pylint" },
                sh = { "shellcheck" },
                sql = { "sqlfluff" },
                dockerfile = { "trivy" },
            }
            vim.api.nvim_create_autocmd({ "BufWritePost" }, {
                callback = function()
                    -- try_lint without arguments runs the linters defined in `linters_by_ft`
                    -- for the current filetype
                    require("lint").try_lint()
                end,
            })
        end,
    },

    -- **Fuzzy Finder** (Telescope)
    {
        "nvim-telescope/telescope.nvim",
        branch = "0.1.x",
        dependencies = { "nvim-lua/plenary.nvim" },
    },

    -- **UI Enhancements**
    {
        "nvim-lualine/lualine.nvim",
        dependencies = "nvim-tree/nvim-web-devicons",
        config = function()
            require("lualine").setup({
                options = { theme = "dracula", icons_enabled = true },
                sections = { lualine_c = { "filename" }, lualine_x = { "encoding", "fileformat", "filetype" } },
            })
        end,
    },
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        ---@module "ibl"
        ---@type ibl.config
        opts = {},
    },
    {
        "iamcco/markdown-preview.nvim",
        cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
        build = "cd app && npm install",
        init = function()
            vim.g.mkdp_filetypes = { "markdown" }
        end,
        ft = { "markdown" },
    },
    {
        "catgoose/nvim-colorizer.lua",
        event = "BufReadPre",
        opts = { -- set to setup table
        },
    },
    -- **Utility Plugins**
    { "tpope/vim-fugitive",       cmd = { "Git", "Gedit", "Gstatus", "Gdiffsplit", "Gpush", "Gpull" } },
    {
        "lewis6991/gitsigns.nvim",
        event = "BufReadPre", -- Git change signs (replaces vim-gitgutter):contentReference[oaicite:13]{index=13}
        config = function()
            require("gitsigns").setup()
        end,
    },
    {
        "numToStr/Comment.nvim",
        keys = { "gc", "gcc", "gbc" },
        config = function()
            require("Comment").setup()
        end,
    },
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = function()
            require("nvim-autopairs").setup({})
        end,
    },
    { "folke/which-key.nvim", event = "VeryLazy", config = true }, -- optional: keybinding hints

    {
        "jiaoshijie/undotree",
        dependencies = "nvim-lua/plenary.nvim",
        config = true,
        keys = { -- load the plugin only when using it's keybinding:
            { "<leader>u", "<cmd>lua require('undotree').toggle()<cr>" },
        },
    },
    {
        "hiphish/rainbow-delimiters.nvim",
        config = function()
            require("configs.rainbowDelimiters")
        end,
    },
}
