return {
  "pwntester/octo.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "nvim-tree/nvim-web-devicons", -- 可选，图标支持
  },
  config = function()
    require("octo").setup()
  end,
}
