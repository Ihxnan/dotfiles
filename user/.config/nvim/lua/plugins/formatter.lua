return {
    -- ====================== 统一格式化引擎（conform.nvim） ======================
    {
        "stevearc/conform.nvim",
        event = { "BufWritePre" },
        cmd = { "ConformInfo" },
        keys = {
            {
                "<Tab>",
                function()
                    require("conform").format({ async = true, lsp_fallback = true })
                end,
                desc = "格式化当前文件",
            },
            {
                "<leader>f",
                function()
                    require("conform").format({ async = true, lsp_fallback = true })
                end,
                desc = "格式化当前文件",
            },
        },
        opts = {
            -- 保存时自动格式化
            format_on_save = {
                timeout_ms = 500,
                lsp_format = "fallback", -- LSP 格式化兜底（可选 "fallback"|"prefer"|"never"）
            },

            -- ========== 按文件类型配置格式化器 ==========
            formatters_by_ft = {
                ---------- Python ----------
                python = { { "isort" }, { "black" } },

                ---------- Lua ----------
                lua    = { "stylua" },

                ---------- C/C++ ----------
                c      = { "clang-format" },
                cpp    = { "clang-format" },
                proto  = { "clang-format" },

                ---------- Shell ----------
                sh     = { "shfmt" },
                bash   = { "shfmt" },
                zsh    = { "shfmt" },

                ---------- JS/TS（React 支持） ----------
                javascript       = { { "prettierd", "prettier" } },
                typescript       = { { "prettierd", "prettier" } },
                javascriptreact  = { { "prettierd", "prettier" } },
                typescriptreact  = { { "prettierd", "prettier" } },

                ---------- 前端标记语言 ----------
                json      = { { "prettierd", "prettier" } },
                jsonc     = { { "prettierd", "prettier" } },
                html      = { { "prettierd", "prettier" } },
                css       = { { "prettierd", "prettier" } },
                scss      = { { "prettierd", "prettier" } },
                less      = { { "prettierd", "prettier" } },

                ---------- 文档/配置 ----------
                markdown  = { { "prettierd", "prettier" } },
                yaml      = { { "prettierd", "prettier" } },
                toml      = { "taplo" },

                ---------- 构建系统 ----------
                cmake     = { "cmake-format" },
            },

            -- ========== 格式化器详细选项 ==========
            formatters = {
                ----- Python -----
                black = {
                    prepend_args = { "--line-length", "100" },
                },
                isort = {
                    prepend_args = {
                        "--profile", "black",
                        "--line-length", "100",
                    },
                },

                ----- C/C++（Microsoft Allman 风格：大括号独占一行） -----
                ["clang-format"] = {
                    prepend_args = { "--style=Microsoft" },
                },

                ----- Prettier（优先使用 daemon 版本，性能更好） -----
                prettier = {
                    prepend_args = {
                        "--print-width", "100",
                        "--tab-width", "4",
                        "--single-quote",
                        "--trailing-comma", "all",
                    },
                },
                prettierd = {
                    prepend_args = {
                        "--print-width", "100",
                        "--tab-width", "4",
                        "--single-quote",
                        "--trailing-comma", "all",
                    },
                },

                ----- Shell -----
                shfmt = {
                    prepend_args = { "-i", "4", "-ci" }, -- 4空格缩进，switch case 缩进
                },

                ----- CMake -----
                ["cmake-format"] = {
                    prepend_args = {
                        "--tab-size", "4",
                        "--line-width", "100",
                    },
                },
            },
        },
    },
}
