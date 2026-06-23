return {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = true,
    opts = {
        open_mapping = [[<A-t>]],
        direction = "float",
        shell = vim.o.shell,
    },
}
