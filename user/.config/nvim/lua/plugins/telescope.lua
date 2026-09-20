return {
    {
        "nvim-telescope/telescope.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        -- 配置函数，在插件加载后执行
        config = function()
            local builtin = require("telescope.builtin")

            -- Windows 适配：Telescope 需要 PATH 里有 ripgrep（rg）与 fd；
            -- Windows 上先装好再重启终端，例如：
            --   winget install BurntSushi.ripgrep.MSVC   /   scoop install fd ripgrep
            vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })

            -- 搜索界面透明背景
            vim.api.nvim_set_hl(0, "TelescopeNormal",       { bg = "none" })
            vim.api.nvim_set_hl(0, "TelescopeBorder",       { bg = "none" })
            vim.api.nvim_set_hl(0, "TelescopePromptNormal", { bg = "none" })
            vim.api.nvim_set_hl(0, "TelescopePromptBorder", { bg = "none" })
            vim.api.nvim_set_hl(0, "TelescopeResultsNormal", { bg = "none" })
            vim.api.nvim_set_hl(0, "TelescopeResultsBorder", { bg = "none" })
            vim.api.nvim_set_hl(0, "TelescopePreviewNormal", { bg = "none" })
            vim.api.nvim_set_hl(0, "TelescopePreviewBorder", { bg = "none" })
        end,
    },
}