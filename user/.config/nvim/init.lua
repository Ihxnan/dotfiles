-- 在 VSCode（vscode-neovim 插件）中运行时走精简配置：
-- 状态栏 / 文件树 / tab / LSP / 补全等由 VSCode 负责，避免与本配置的插件冲突。
-- 普通 Neovim 保持完整配置不变。
if vim.g.vscode then
    require("config.vscode")
else
    require("config.lazy")
    require("config.options")
    require("config.keymaps")
end
