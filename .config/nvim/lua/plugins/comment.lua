return {
  "numToStr/Comment.nvim",
  -- 1. 不 lazy，且加优先级，确保最先加载
  lazy = false,
  priority = 1000, -- 越高越先加载
  -- 2. 用 opts 替代手写 config，Lazy 更稳
  opts = {
    -- 保持默认映射
    mappings = {
      basic = true,
      extra = true,
    },
  },
  -- 3. 显式依赖，避免被其他插件覆盖
  dependencies = {
    "nvim-telescope/telescope.nvim", -- 可选，根据你实际依赖
  },
  -- 4. 可选：手动强映射（彻底解决映射被冲）
  config = function()
    -- 先调用 setup（opts 会自动传，但手动再调一次更稳）
    require("Comment").setup()
    -- 强制映射，覆盖一切
    vim.keymap.set("n", "gcc", function() require("Comment.api").toggle.linewise.current() end, { noremap = true, desc = "Comment current line" })
    vim.keymap.set("v", "gc", function() require("Comment.api").toggle.linewise(vim.fn.visualmode()) end, { noremap = true, desc = "Comment selection" })
  end,
}
