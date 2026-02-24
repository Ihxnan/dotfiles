return {
    {
        "williamboman/mason.nvim",
        build = ":MasonUpdate", -- 安装后自动更新 Mason
        config = true,
    },

    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        dependencies = { "williamboman/mason.nvim" }, -- 依赖 Mason 核心
        opts = {
            ensure_installed = {
                -- 格式化/检查工具
                "black",                      -- Python 格式化
                "clang-format",               -- C/C++ 格式化
                "isort",                      -- Python 导入排序
                "htmlhint",                   -- HTML 语法检查
                -- LSP 服务
                "lua-language-server",        -- Lua LSP（对应 servers 中的 lua_ls）
                "typescript-language-server", -- TS LSP（对应 servers 中的 ts_ls）
                "html-lsp",                   -- HTML LSP（对应 servers 中的 html）
                "css-lsp",                    -- CSS LSP（对应 servers 中的 cssls）
                "json-lsp",                   -- JSON LSP（对应 servers 中的 jsonls）
                "pyright",                    -- Python LSP（对应 servers 中的 pyright）
                "clangd",                     -- C/C++ LSP（对应 servers 中的 clangd）
                "jdtls",                      -- Java LSP（对应 servers 中的 jdtls）
            },
            auto_update = false,              -- 不自动更新已安装工具（避免兼容性问题）
            run_on_start = true,              -- Neovim 启动时自动检查并安装缺失工具
            start_delay = 1500,               -- 延迟 1.5 秒执行（避免与 Mason 启动冲突）
        },
    },

    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = {
            "williamboman/mason.nvim",
            "neovim/nvim-lspconfig",
            "WhoIsSethDaniel/mason-tool-installer.nvim",
        },
        config = function()
            -- 加载模块
            local mlsp_ok, mason_lspconfig = pcall(require, "mason-lspconfig")
            if not mlsp_ok then
                vim.notify("mason-lspconfig 加载失败", vim.log.levels.ERROR)
                return
            end

            -- 初始化插件
            mason_lspconfig.setup({})

            -- 获取Mason安装路径
            local mason_path = vim.fn.glob(vim.fn.stdpath("data") .. "/mason/")

            -- 服务器配置
            local servers = {
                lua_ls = {
                    cmd = { mason_path .. "bin/lua-language-server" },
                    settings = {
                        Lua = {
                            runtime = { version = "LuaJIT" },
                            diagnostics = { globals = { "vim" } },
                            workspace = {
                                library = vim.api.nvim_get_runtime_file("", true),
                                checkThirdParty = false,
                            },
                        },
                    },
                },
                ts_ls = {
                    cmd = { mason_path .. "bin/typescript-language-server", "--stdio" },
                },
                html = {
                    cmd = { mason_path .. "bin/vscode-html-language-server", "--stdio" },
                },
                cssls = {
                    cmd = { mason_path .. "bin/vscode-css-language-server", "--stdio" },
                },
                jsonls = {
                    cmd = { mason_path .. "bin/vscode-json-language-server", "--stdio" },
                },
                pyright = {
                    cmd = { mason_path .. "bin/pyright-langserver", "--stdio" },
                },
                clangd = {
                    cmd = { mason_path .. "bin/clangd" },
                },
                jdtls = {
                    cmd = { mason_path .. "bin/jdtls" },
                },
            }

            -- LSP 能力配置
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities.textDocument.completion.completionItem.snippetSupport = true

            -- on_attach 函数
            local on_attach = function(client, bufnr)
                local opts = { buffer = bufnr, noremap = true, silent = true }
                -- 重命名符号
                vim.keymap.set(
                    "n",
                    "<leader>rn",
                    vim.lsp.buf.rename,
                    vim.tbl_extend("force", opts, { desc = "重命名符号" })
                )
                -- 显示代码动作
                vim.keymap.set(
                    "n",
                    "<leader>ca",
                    vim.lsp.buf.code_action,
                    vim.tbl_extend("force", opts, { desc = "显示代码动作" })
                )
                -- 查看引用
                vim.keymap.set(
                    "n",
                    "gr",
                    vim.lsp.buf.references,
                    vim.tbl_extend("force", opts, { desc = "查看引用" })
                )
                -- 诊断相关快捷键
                vim.keymap.set(
                    "n",
                    "<leader>]",
                    vim.diagnostic.goto_next,
                    vim.tbl_extend("force", opts, { desc = "跳转到下一个诊断错误" })
                )
                vim.keymap.set(
                    "n",
                    "<leader>[",
                    vim.diagnostic.goto_prev,
                    vim.tbl_extend("force", opts, { desc = "跳转到上一个诊断错误" })
                )
                vim.keymap.set(
                    "n",
                    "<leader>dl",
                    vim.diagnostic.setloclist,
                    vim.tbl_extend("force", opts, { desc = "打开诊断列表" })
                )
                vim.keymap.set(
                    "n",
                    "<leader>dh",
                    vim.diagnostic.open_float,
                    vim.tbl_extend("force", opts, { desc = "显示当前行诊断信息" })
                )
            end

            -- 获取已安装的服务器列表
            local installed_servers = mason_lspconfig.get_installed_servers()

            -- 为每个已安装的服务器启动LSP
            for _, server_name in ipairs(installed_servers) do
                if servers[server_name] then
                    local config = vim.tbl_extend("force", {
                        name = server_name,
                        on_attach = on_attach,
                        capabilities = capabilities,
                    }, servers[server_name])
                    vim.lsp.start(config)
                else
                    vim.notify(
                        "未找到 " .. server_name .. " 的配置，请添加到服务器配置列表中",
                        vim.log.levels.WARN
                    )
                end
            end
        end,
    },
}
