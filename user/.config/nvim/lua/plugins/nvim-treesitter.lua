return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    lazy = false,                            -- 启动时加载（treesitter 太基础了，懒加载反而出问题）
    config = function()
        require("nvim-treesitter.config").setup({
            ensure_installed = {
                "c",
                "cpp",
                "lua",
                "vim",
                "python",
                "html",
                "xml",
                "vue",
                "javascript",
                "typescript",
                "tsx",
                "markdown",
                "markdown_inline",  -- 用于 LaTeX 数学公式渲染
                "latex",            -- render-markdown LaTeX 渲染
                "yaml",             -- render-markdown YAML frontmatter
            },
            sync_install = true,
            auto_install = true,
            highlight = { enable = true },
            indent = { enable = false },
        })

        -- CUDA文件映射为C++
        vim.filetype.add({
            extension = {
                cu = "cpp",
                cuh = "cpp",
            },
        })

        -- C/C++/CUDA 缩进配置
        vim.api.nvim_create_autocmd("FileType", {
            pattern = { "c", "cpp" },
            callback = function()
                vim.opt_local.cindent = true
                vim.opt_local.cinoptions = "{0,m1,s1,C1,g0,w1,}0,:0,l1,N-s,t0,(0"
                vim.opt_local.shiftwidth = 4
                vim.opt_local.tabstop = 4
                vim.opt_local.expandtab = true
            end,
        })

        -- Python 缩进/折叠优化
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "python",
            callback = function()
                vim.opt_local.tabstop = 4
                vim.opt_local.shiftwidth = 4
                vim.opt_local.softtabstop = 4
                vim.opt_local.expandtab = true
                vim.opt_local.foldmethod = "expr"
                vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
                vim.opt_local.foldlevel = 50
                vim.opt_local.foldlevelstart = 50
            end,
        })

        -- Python 运行/测试快捷键
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "python",
            callback = function()
                local opts = { buffer = true, noremap = true, silent = true }
                -- Windows 适配：Windows 上 Python 启动器名是 python（不是 python3）；
                -- Linux/macOS 仍为 python3，生成的 rhs 与改动前逐字相同。
                local is_win = vim.fn.has("win32") == 1
                local py = is_win and "python" or "python3"
                -- Windows 分支用 "%"：由 Vim 在按键时展开为当前文件名，双引号保证含空格也安全
                -- （不用 Lua 侧一次性展开，避免 :saveas 后仍指向旧路径）；Linux 分支保持原样。
                vim.keymap.set("n", "<leader>rr",
                    is_win and ("<cmd>w<CR><cmd>split | terminal " .. py .. " \"%\"<CR>i")
                        or ("<cmd>w<CR><cmd>split | terminal " .. py .. " %<CR>i"),
                    vim.tbl_extend("force", opts, { desc = "Python: 运行当前文件" }))
                vim.keymap.set("n", "<leader>rt", function()
                    vim.cmd("w")
                    if is_win then
                        -- pwsh 下用双引号包住路径，避免含空格时参数分裂
                        vim.cmd("split | terminal " .. py .. " -m pytest \"" .. vim.fn.expand("%") .. "\" -x --tb=short")
                    else
                        vim.cmd("split | terminal pytest " .. vim.fn.expand("%") .. " -x --tb=short")
                    end
                end, vim.tbl_extend("force", opts, { desc = "Python: 运行当前测试文件" }))
                vim.keymap.set("n", "<leader>rT", function()
                    vim.cmd("w")
                    if is_win then
                        -- Windows 上没有 pytest 独立命令名，统一走 python -m pytest
                        vim.cmd("split | terminal " .. py .. " -m pytest -x --tb=short")
                    else
                        vim.cmd("split | terminal pytest -x --tb=short")
                    end
                end, vim.tbl_extend("force", opts, { desc = "Python: 运行全部测试" }))
            end,
        })
    end,
}
