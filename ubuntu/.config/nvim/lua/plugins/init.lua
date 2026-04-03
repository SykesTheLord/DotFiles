local M = {}
local TS_PARSERS = {
    "bash",
    "c",
    "diff",
    "html",
    "javascript",
    "jsdoc",
    "json",
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
}

local function gh(repo)
    return "https://github.com/" .. repo
end

local function packadd(name)
    local escaped = vim.fn.fnameescape(name)
    local path = vim.fn.stdpath("data") .. "/site/pack/core/opt/" .. name
    local lua_path = path .. "/lua/?.lua"
    local lua_init_path = path .. "/lua/?/init.lua"

    pcall(vim.cmd, "packadd " .. escaped)

    if vim.fn.isdirectory(path) == 1 and not vim.tbl_contains(vim.opt.runtimepath:get(), path) then
        vim.opt.runtimepath:prepend(path)
    end

    if vim.fn.isdirectory(path .. "/lua") == 1 then
        if not package.path:find(vim.pesc(lua_path), 1, false) then
            package.path = table.concat({ lua_path, lua_init_path, package.path }, ";")
        end
    end
end

local function spec(repo, name)
    return {
        src = gh(repo),
        name = name,
    }
end

local function set_keymaps(maps)
    for _, map in ipairs(maps) do
        local lhs = map[1]
        local rhs = map[2]
        local mode = map.mode or "n"
        local opts = {}

        for key, value in pairs(map) do
            if key ~= 1 and key ~= 2 and key ~= "mode" then
                opts[key] = value
            end
        end

        vim.keymap.set(mode, lhs, rhs, opts)
    end
end

local function setup_pack_hooks()
    local group = vim.api.nvim_create_augroup("UserPackHooks", { clear = true })

    vim.api.nvim_create_autocmd("PackChanged", {
        group = group,
        callback = function(ev)
            local name = ev.data.spec.name
            local kind = ev.data.kind

            if kind ~= "install" and kind ~= "update" then
                return
            end

            if name == "nvim-treesitter" then
                vim.schedule(function()
                    packadd("nvim-treesitter")

                    local ok, ts = pcall(require, "nvim-treesitter")
                    if ok then
                        local op = ts.install(TS_PARSERS)
                        if op and type(op.wait) == "function" then
                            pcall(op.wait, op, 300000)
                        end
                    end
                end)
                return
            end

            if name == "markdown-preview.nvim" and vim.fn.executable("npm") == 1 then
                vim.system({ "npm", "install" }, { cwd = ev.data.path .. "/app" }, function(obj)
                    if obj.code ~= 0 then
                        vim.schedule(function()
                            vim.notify("markdown-preview.nvim build failed", vim.log.levels.WARN)
                        end)
                    end
                end)
            end
        end,
    })
end

local function install_plugins()
    setup_pack_hooks()

    vim.pack.add({
        spec("AlexvZyl/nordic.nvim", "nordic.nvim"),
        spec("folke/snacks.nvim", "snacks.nvim"),
        spec("akinsho/bufferline.nvim", "bufferline.nvim"),
        spec("nvim-tree/nvim-web-devicons", "nvim-web-devicons"),
        spec("antosha417/nvim-lsp-file-operations", "nvim-lsp-file-operations"),
        spec("nvim-lua/plenary.nvim", "plenary.nvim"),
        spec("nvim-neo-tree/neo-tree.nvim", "neo-tree.nvim"),
        spec("MunifTanjim/nui.nvim", "nui.nvim"),
        spec("s1n7ax/nvim-window-picker", "nvim-window-picker"),
        spec("williamboman/mason.nvim", "mason.nvim"),
        spec("williamboman/mason-lspconfig.nvim", "mason-lspconfig.nvim"),
        spec("WhoIsSethDaniel/mason-tool-installer.nvim", "mason-tool-installer.nvim"),
        spec("RaafatTurki/corn.nvim", "corn.nvim"),
        spec("hrsh7th/cmp-nvim-lsp", "cmp-nvim-lsp"),
        spec("Decodetalkers/csharpls-extended-lsp.nvim", "csharpls-extended-lsp.nvim"),
        spec("hrsh7th/nvim-cmp", "nvim-cmp"),
        spec("L3MON4D3/LuaSnip", "LuaSnip"),
        spec("saadparwaiz1/cmp_luasnip", "cmp_luasnip"),
        spec("hrsh7th/cmp-buffer", "cmp-buffer"),
        spec("hrsh7th/cmp-path", "cmp-path"),
        spec("hrsh7th/cmp-cmdline", "cmp-cmdline"),
        spec("rafamadriz/friendly-snippets", "friendly-snippets"),
        spec("lukas-reineke/cmp-under-comparator", "cmp-under-comparator"),
        spec("ray-x/cmp-sql", "cmp-sql"),
        spec("hrsh7th/cmp-nvim-lsp-signature-help", "cmp-nvim-lsp-signature-help"),
        spec("nvim-treesitter/nvim-treesitter", "nvim-treesitter"),
        spec("nvim-treesitter/nvim-treesitter-context", "nvim-treesitter-context"),
        spec("nvim-treesitter/nvim-treesitter-textobjects", "nvim-treesitter-textobjects"),
        spec("mfussenegger/nvim-dap", "nvim-dap"),
        spec("rcarriga/nvim-dap-ui", "nvim-dap-ui"),
        spec("nvim-neotest/nvim-nio", "nvim-nio"),
        spec("Weissle/persistent-breakpoints.nvim", "persistent-breakpoints.nvim"),
        spec("mfussenegger/nvim-lint", "nvim-lint"),
        spec("aquasecurity/vim-trivy", "vim-trivy"),
        spec("nvim-lualine/lualine.nvim", "lualine.nvim"),
        spec("iamcco/markdown-preview.nvim", "markdown-preview.nvim"),
        spec("catgoose/nvim-colorizer.lua", "nvim-colorizer.lua"),
        spec("tpope/vim-fugitive", "vim-fugitive"),
        spec("lewis6991/gitsigns.nvim", "gitsigns.nvim"),
        spec("numToStr/Comment.nvim", "Comment.nvim"),
        spec("windwp/nvim-autopairs", "nvim-autopairs"),
        spec("folke/which-key.nvim", "which-key.nvim"),
        spec("jiaoshijie/undotree", "undotree"),
        spec("hiphish/rainbow-delimiters.nvim", "rainbow-delimiters.nvim"),
    }, {
        confirm = false,
        load = true,
    })
end

local function setup_snacks()
    packadd("snacks.nvim")
    local snacks = require("snacks")
    _G.Snacks = snacks

    snacks.setup({
        bigfile = { enabled = true },
        explorer = { enabled = true },
        indent = { enabled = true },
        input = { enabled = true },
        notifier = {
            enabled = true,
            timeout = 8000,
        },
        picker = { enabled = true },
        quickfile = { enabled = true },
        scope = { enabled = true },
        scroll = { enabled = false },
        statuscolumn = { enabled = true },
        words = { enabled = true },
        styles = {
            notification = {},
        },
    })

    set_keymaps(require("configs.snacksKeybinds"))

    _G.dd = function(...)
        snacks.debug.inspect(...)
    end
    _G.bt = function()
        snacks.debug.backtrace()
    end
    vim.print = _G.dd

    snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
    snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
    snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
    snacks.toggle.diagnostics():map("<leader>ud")
    snacks.toggle.line_number():map("<leader>ul")
    snacks.toggle
        .option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
        :map("<leader>uc")
    snacks.toggle.treesitter():map("<leader>uT")
    snacks.toggle.inlay_hints():map("<leader>uh")
    snacks.toggle.indent():map("<leader>ug")
    snacks.toggle.dim():map("<leader>uD")
end

local function setup_window_picker()
    packadd("nvim-window-picker")
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
end

local function setup_neotree()
    packadd("nvim-lsp-file-operations")
    packadd("neo-tree.nvim")
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

                require("neo-tree.command").execute({
                    source = "document_symbols",
                    position = "right",
                    toggle = false,
                    focus = false,
                })

                vim.schedule(function()
                    if type(cur_win) == "number" and vim.api.nvim_win_is_valid(cur_win) then
                        vim.api.nvim_set_current_win(cur_win)
                    end
                end)

                vim.b.neotree_symbols_shown = true
            end
        end,
    })

    require("lsp-file-operations").setup()
    require("configs.neotreeConfig")
end

local function setup_mason()
    packadd("mason.nvim")
    packadd("mason-tool-installer.nvim")
    packadd("corn.nvim")
    packadd("mason-lspconfig.nvim")
    require("mason").setup()

    require("mason-tool-installer").setup({
        ensure_installed = {
            "trivy",
            "csharpier",
            "netcoredbg",
            "black",
            "debugpy",
            "pylint",
            "eslint_d",
            "jsonlint",
            "beautysh",
            "shellcheck",
            "prettierd",
            "java-debug-adapter",
            "clang-format",
            "stylua",
            "luacheck",
            "cmakelang",
            "sqlfluff",
            "sql-formatter",
            "vale",
            "tfsec",
            "cpplint",
            "cmakelint",
            "htmlhint",
            "checkstyle",
            "cpptools",
        },
        automatic_installation = true,
        auto_update = true,
    })

    require("configs.cornConfig")

    require("mason-lspconfig").setup({
        ensure_installed = {
            "clangd",
            "eslint",
            "jedi_language_server",
            "jsonls",
            "yamlls",
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
        automatic_enable = false,
    })

    local registry = require("mason-registry")
    local pkg = registry.get_package("csharp-language-server")
    if not pkg:is_installed() then
        pkg:install({ version = "0.16.0" })
    end

    require("lspConfig")
end

local function setup_cmp()
    packadd("nvim-cmp")
    packadd("LuaSnip")
    packadd("cmp-nvim-lsp")
    packadd("cmp_luasnip")
    packadd("cmp-buffer")
    packadd("cmp-path")
    packadd("cmp-cmdline")
    packadd("friendly-snippets")
    packadd("cmp-under-comparator")
    packadd("cmp-sql")
    packadd("cmp-nvim-lsp-signature-help")
    local cmp = require("cmp")
    local luasnip = require("luasnip")

    require("luasnip.loaders.from_vscode").lazy_load()

    local function get_project_root()
        local bufname = vim.api.nvim_buf_get_name(0)
        local cwd = vim.fn.getcwd()
        if bufname == "" then
            return cwd
        end

        local root_files = { "package.json", "pyproject.toml", "setup.py", ".git" }
        for _, name in ipairs(root_files) do
            local match = vim.fs.find(name, {
                path = vim.fs.dirname(bufname),
                upward = true,
                type = (name == ".git") and "directory" or "file",
            })[1]
            if match then
                return vim.fs.dirname(match)
            end
        end

        return cwd
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
        window = {
            completion = cmp.config.window.bordered(),
            documentation = cmp.config.window.bordered(),
        },
        sources = cmp.config.sources({
            { name = "nvim_lsp" },
            { name = "luasnip" },
            { name = "buffer" },
            { name = "path", option = { get_cwd = get_project_root } },
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

    cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
            { name = "path", option = { get_cwd = get_project_root } },
        }, {
            { name = "cmdline", option = { ignore_cmds = { "Man", "!" } } },
        }),
    })
end

local function setup_treesitter()
    packadd("nvim-treesitter")
    packadd("nvim-treesitter-context")
    packadd("nvim-treesitter-textobjects")

    local ok_ts, treesitter = pcall(require, "nvim-treesitter")
    if ok_ts then
        treesitter.setup()

        local installed = treesitter.get_installed("parsers")
        local missing = vim.tbl_filter(function(lang)
            return not vim.list_contains(installed, lang)
        end, TS_PARSERS)

        if #missing > 0 then
            local op = treesitter.install(missing)
            if op and type(op.wait) == "function" then
                pcall(op.wait, op, 300000)
            end
        end
    end

    local group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
        group = group,
        callback = function(args)
            pcall(vim.treesitter.start, args.buf)
        end,
    })

    local ok_textobjects, textobjects = pcall(require, "nvim-treesitter-textobjects")
    if ok_textobjects then
        textobjects.setup({
            move = {
                set_jumps = true,
            },
        })

        local move = require("nvim-treesitter-textobjects.move")
        local maps = {
            ["]f"] = function()
                move.goto_next_start("@function.outer", "textobjects")
            end,
            ["]c"] = function()
                move.goto_next_start("@class.outer", "textobjects")
            end,
            ["]a"] = function()
                move.goto_next_start("@parameter.inner", "textobjects")
            end,
            ["]F"] = function()
                move.goto_next_end("@function.outer", "textobjects")
            end,
            ["]C"] = function()
                move.goto_next_end("@class.outer", "textobjects")
            end,
            ["]A"] = function()
                move.goto_next_end("@parameter.inner", "textobjects")
            end,
            ["[f"] = function()
                move.goto_previous_start("@function.outer", "textobjects")
            end,
            ["[c"] = function()
                move.goto_previous_start("@class.outer", "textobjects")
            end,
            ["[a"] = function()
                move.goto_previous_start("@parameter.inner", "textobjects")
            end,
            ["[F"] = function()
                move.goto_previous_end("@function.outer", "textobjects")
            end,
            ["[C"] = function()
                move.goto_previous_end("@class.outer", "textobjects")
            end,
            ["[A"] = function()
                move.goto_previous_end("@parameter.inner", "textobjects")
            end,
        }

        for lhs, rhs in pairs(maps) do
            vim.keymap.set({ "n", "x", "o" }, lhs, rhs)
        end
    end

    require("treesitter-context").setup({
        mode = "cursor",
        max_lines = 3,
    })
end

local function setup_dap()
    packadd("nvim-dap")
    packadd("nvim-nio")
    packadd("nvim-dap-ui")
    packadd("persistent-breakpoints.nvim")

    local ok_nio = pcall(require, "nio")
    local ok_dapui, dapui = pcall(require, "dapui")

    if ok_nio and ok_dapui then
        dapui.setup()
        require("configs.nvimDapConfig")
    end

    local ok_breakpoints, breakpoints = pcall(require, "persistent-breakpoints")
    if ok_breakpoints then
        breakpoints.setup({
            load_breakpoints_event = { "BufReadPost" },
        })
    end
end

local function setup_lint()
    packadd("nvim-lint")
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

    local group = vim.api.nvim_create_augroup("UserLintOnWrite", { clear = true })
    vim.api.nvim_create_autocmd("BufWritePost", {
        group = group,
        callback = function()
            require("lint").try_lint()
        end,
    })
end

local function setup_format_commands()
    vim.api.nvim_create_user_command("Format", function()
        vim.lsp.buf.format()
    end, { force = true })

    vim.api.nvim_create_user_command("FormatWrite", function()
        vim.lsp.buf.format()
        vim.cmd.write()
    end, { force = true })

    vim.api.nvim_create_user_command("FormatLock", function()
        vim.lsp.buf.format({ async = false })
    end, { force = true })

    vim.api.nvim_create_user_command("FormatWriteLock", function()
        vim.lsp.buf.format({ async = false })
        vim.cmd.write()
    end, { force = true })
end

local function setup_ui_plugins()
    packadd("bufferline.nvim")
    packadd("lualine.nvim")
    packadd("nvim-colorizer.lua")
    packadd("gitsigns.nvim")
    packadd("Comment.nvim")
    packadd("nvim-autopairs")
    packadd("which-key.nvim")
    require("bufferline").setup({})
    require("lualine").setup({
        options = { theme = "dracula", icons_enabled = true },
        sections = { lualine_c = { "filename" }, lualine_x = { "encoding", "fileformat", "filetype" } },
    })
    require("colorizer").setup({
        user_default_options = {
            names = false,
            css = true,
            xterm = true,
        },
    })
    require("gitsigns").setup()
    require("Comment").setup()
    require("nvim-autopairs").setup({})
    require("which-key").setup({})
end

local function setup_misc_plugins()
    packadd("rainbow-delimiters.nvim")
    require("configs.rainbowDelimiters")

    vim.g.mkdp_filetypes = { "markdown" }
end

function M.setup()
    install_plugins()

    packadd("nordic.nvim")
    require("nordic").load()
    setup_snacks()
    setup_window_picker()
    setup_neotree()
    setup_mason()
    setup_cmp()
    setup_treesitter()
    setup_dap()
    setup_lint()
    setup_format_commands()
    setup_ui_plugins()
    setup_misc_plugins()
end

return M
