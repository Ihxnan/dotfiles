return {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = "UIEnter",
    opts = {
        indent = {
            char = "│",
            -- 彩虹色循环，与 tokyonight 配色匹配
            highlight = {
                "IblIndent1",
                "IblIndent2",
                "IblIndent3",
                "IblIndent4",
                "IblIndent5",
                "IblIndent6",
            },
        },
        scope = { enabled = true, show_start = false, show_end = false },
    },
    config = function(_, opts)
        -- 必须用 hook 注册彩虹高亮组：colorscheme 切换（如 base46 的 hi clear）
        -- 会清掉一次性定义的自定义组，ibl 的 highlights.setup 找不到组就会报错并留下空表，
        -- 之后每次刷新都会在 virt_text.lua 索引空表。
        local hooks = require("ibl.hooks")
        hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
            local colors = {
                "#f7768e", -- red
                "#e0af68", -- yellow
                "#7aa2f7", -- blue
                "#ff9e64", -- orange
                "#9ece6a", -- green
                "#bb9af7", -- violet
            }
            for i, color in ipairs(colors) do
                vim.api.nvim_set_hl(0, "IblIndent" .. i, { fg = color, nocombine = true })
            end
        end)

        require("ibl").setup(opts)
    end,
}