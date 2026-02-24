return {
    "numToStr/Comment.nvim",
    event = "VeryLazy",
    config = function()
        require("Comment").setup()
        local api = require("Comment.api")
        vim.keymap.set("n", "<C-_>", api.toggle.linewise.current, { desc = "Comment current line" })
        vim.keymap.set("v", "<C-_>", function()
            api.toggle.linewise(vim.fn.visualmode())
        end, { desc = "Comment selected lines" })
    end,
}
