return {
    "brianhuster/live-preview.nvim",
    ft = "markdown",
    dependencies = {
        "nvim-telescope/telescope.nvim",
    },
    config = function()
        require("live-preview").setup({
            -- Windows 适配：Windows 上通常没有名为 chromium 的可执行文件，用 "default" 交给系统默认浏览器；
            -- 也可显式写 "chrome" / "msedge"（需在 PATH 里）。
            browser = vim.fn.has("win32") == 1 and "default" or "chromium",
        })
    end,
}