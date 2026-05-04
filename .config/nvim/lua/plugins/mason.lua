return {
    {
        "williamboman/mason.nvim",
        build = ":MasonUpdate",
        config = true,
    },

    {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        dependencies = { "williamboman/mason.nvim" },
        opts = {
            ensure_installed = {
                "black",
                "clang-format",
                "isort",
                "htmlhint",
                "lua-language-server",
                "typescript-language-server",
                "html-lsp",
                "css-lsp",
                "json-lsp",
                "pyright",
                "clangd",
            },
            auto_update = false,
            run_on_start = true,
            start_delay = 1500,
        },
    },

    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
        },
        config = function()
            local ok, mason_lsp = pcall(require, "mason-lspconfig")
            if not ok then return end

            mason_lsp.setup({})
            local mason_path = vim.fn.glob(vim.fn.stdpath("data") .. "/mason/")

            -- 新版 LSP 配置（Neovim 0.11+）
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities.textDocument.completion.completionItem.snippetSupport = true

            local on_attach = function(client, bufnr)
                local opts = { buffer = bufnr, noremap = true, silent = true }

                vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "重命名" }))
                vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "代码动作" }))
                vim.keymap.set("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "引用" }))

                -- ✅ 新版诊断跳转（无废弃警告）
                vim.keymap.set("n", "<leader>]", function()
                    vim.diagnostic.jump({ count = 1, float = true })
                end, vim.tbl_extend("force", opts, { desc = "下一个错误" }))

                vim.keymap.set("n", "<leader>[", function()
                    vim.diagnostic.jump({ count = -1, float = true })
                end, vim.tbl_extend("force", opts, { desc = "上一个错误" }))

                vim.keymap.set("n", "<leader>dl", vim.diagnostic.setloclist, vim.tbl_extend("force", opts, { desc = "错误列表" }))
                vim.keymap.set("n", "<leader>dh", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "悬浮错误" }))
            end

            -- 服务器配置（新版格式）
            local servers = {
                lua_ls = {
                    cmd = { mason_path .. "bin/lua-language-server" },
                    on_attach = on_attach,
                    capabilities = capabilities,
                    settings = {
                        Lua = {
                            runtime = { version = "LuaJIT" },
                            diagnostics = { globals = { "vim" } },
                            workspace = { checkThirdParty = false },
                        },
                    },
                },
                ts_ls = {
                    cmd = { mason_path .. "bin/typescript-language-server", "--stdio" },
                    on_attach = on_attach,
                    capabilities = capabilities,
                },
                html = {
                    cmd = { mason_path .. "bin/vscode-html-language-server", "--stdio" },
                    on_attach = on_attach,
                    capabilities = capabilities,
                },
                cssls = {
                    cmd = { mason_path .. "bin/vscode-css-language-server", "--stdio" },
                    on_attach = on_attach,
                    capabilities = capabilities,
                },
                jsonls = {
                    cmd = { mason_path .. "bin/vscode-json-language-server", "--stdio" },
                    on_attach = on_attach,
                    capabilities = capabilities,
                },
                pyright = {
                    cmd = { mason_path .. "bin/pyright-langserver", "--stdio" },
                    on_attach = on_attach,
                    capabilities = capabilities,
                },
                clangd = {
                    cmd = { mason_path .. "bin/clangd" },
                    on_attach = on_attach,
                    capabilities = capabilities,
                },
            }

            -- ✅ 新版启动方式（无废弃警告）
            for name, config in pairs(servers) do
                vim.lsp.config(name, config)
                vim.lsp.enable(name)
            end
        end,
    },
}
