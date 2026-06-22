return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" }, -- 延迟加载，核心修复
    priority = 1000,                         -- 最高优先级加载，核心修复
    config = function()
        -- 安全容错加载，核心修复
        local ok, configs = pcall(require, "nvim-treesitter.configs")
        if not ok then
            vim.notify("nvim-treesitter 初始化中，重启后正常 ✔️", vim.log.levels.INFO)
            return
        end
        configs.setup({
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
                vim.opt_local.colorcolumn = "88,100"
            end,
        })

        -- Python 运行/测试快捷键
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "python",
            callback = function()
                local opts = { buffer = true, noremap = true, silent = true }
                vim.keymap.set("n", "<leader>rr",
                    "<cmd>w<CR><cmd>split | terminal python3 %<CR>i",
                    vim.tbl_extend("force", opts, { desc = "Python: 运行当前文件" }))
                vim.keymap.set("n", "<leader>rt", function()
                    vim.cmd("w")
                    vim.cmd("split | terminal pytest " .. vim.fn.expand("%") .. " -x --tb=short")
                end, vim.tbl_extend("force", opts, { desc = "Python: 运行当前测试文件" }))
                vim.keymap.set("n", "<leader>rT", function()
                    vim.cmd("w")
                    vim.cmd("split | terminal pytest -x --tb=short")
                end, vim.tbl_extend("force", opts, { desc = "Python: 运行全部测试" }))
            end,
        })
    end,
}
