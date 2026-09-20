--
-- ██╗   ██╗███████╗ ██████╗ ██████╗ ██████╗ ███████╗
-- ██║   ██║██╔════╝██╔════╝██╔═══██╗██╔══██╗██╔════╝
-- ██║   ██║███████╗██║     ██║   ██║██║  ██║█████╗
-- ╚██╗ ██╔╝╚════██║██║     ██║   ██║██║  ██║██╔══╝
--  ╚████╔╝ ███████║╚██████╗╚██████╔╝██████╔╝███████╗
--   ╚═══╝  ╚══════╝ ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝
--
-- 功能：vscode-neovim 专用精简配置（仅当 vim.g.vscode 为真时由 init.lua 加载）
--       - 插件 / 状态栏 / 文件树 / tab / LSP / 补全全部交给 VSCode，不加载 lua/plugins
--       - 只保留在 VSCode 下确实可靠的选项与键映射（normal/visual 模式键由 nvim 处理）
--       - 插入模式的 jk 退出无法在 nvim 侧生效，改由 VSCode 的
--         vscode-neovim.compositeKeys 处理（见 ~/.config/Code/User/settings.json）
--       - 运行快捷键转发到 VSCode 任务（见 ~/.config/Code/User/tasks.json）

-- leader 必须在定义映射之前设置（VSCode 分支不加载 lua/config/lazy.lua）
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local keymap = vim.keymap
local opt = vim.opt

-- ======================== 编辑器选项（其余交给 VSCode） ========================
opt.relativenumber = true -- 相对行号（显示由 VSCode 同步）
opt.number = true
opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.autoindent = true
opt.smartindent = true
opt.ignorecase = true
opt.smartcase = true
opt.splitright = true
opt.splitbelow = true
opt.scrolloff = 8
opt.timeoutlen = 500
opt.cursorline = true
opt.signcolumn = "yes"

-- 注意：不要在本分支设置以下选项，会和 VSCode 冲突
--   clipboard   —— 扩展已把 "+ / * 桥接到 VSCode 剪贴板，再设 unnamedplus 会打架
--   autochdir   —— 会修改 nvim 的 cwd，影响 VSCode
--   fold*       —— 折叠交给 VSCode

-- ======================== 恢复上次光标位置 ========================
vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = "*",
    callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        local lcount = vim.api.nvim_buf_line_count(0)
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})

-- ======================== VSCode 命令转发 ========================
local function notify(cmd, args)
    if args == nil then
        vim.fn.VSCodeNotify(cmd)
    else
        vim.fn.VSCodeNotify(cmd, args)
    end
end

-- ======================== 窗口 / 编辑器组导航 ========================
-- <C-h/j/k/l> 在 VSCode 中优先被 VSCode 的 keybinding 拦截，nvim 侧映射收不到，
-- 因此这四个键统一在 ~/.config/Code/User/keybindings.json 里绑定到
-- workbench.action.navigateLeft/Right/Up/Down。

-- ======================== 缓冲区 / tab 管理（转发到 VSCode） ========================
keymap.set("n", "H", function() notify("workbench.action.previousEditor") end, { desc = "上一个 tab" })
keymap.set("n", "L", function() notify("workbench.action.nextEditor") end, { desc = "下一个 tab" })
keymap.set("n", "gbh", function() notify("workbench.action.previousEditor") end, { desc = "上一个 tab" })
keymap.set("n", "gbl", function() notify("workbench.action.nextEditor") end, { desc = "下一个 tab" })
keymap.set("n", "gbd", function() notify("workbench.action.closeActiveEditor") end, { desc = "关闭当前 tab" })
keymap.set("n", "gbo", function() notify("workbench.action.closeOtherEditors") end, { desc = "关闭其他 tab" })

-- ======================== 查找与文件 ========================
keymap.set("n", "<leader>ff", function() notify("workbench.action.quickOpen") end, { desc = "快速打开文件" })
-- 打开资源管理器（原 <leader>e，按要求改为 s；注意 s 覆盖 normal 模式的 substitute）
keymap.set("n", "s", function() notify("workbench.view.explorer") end, { desc = "打开资源管理器" })

-- ======================== 编辑基础 ========================
-- VSCode 原生已处理 Ctrl+S 保存；这里保留映射只为普通模式一致性
keymap.set("n", "<C-S>", function() notify("workbench.action.files.save") end, { desc = "保存" })
keymap.set("n", "n", "nzz", { desc = "搜索下一个并居中" })
keymap.set("n", "N", "Nzz", { desc = "搜索上一个并居中" })
keymap.set("n", "<leader>nh", function()
    vim.cmd("nohlsearch")
    notify("closeFindWidget")
end, { desc = "取消搜索高亮" })
keymap.set("v", "ii", "<ESC>", { desc = "退出视觉模式" })

-- 光标移动与普通 Neovim 保持一致
keymap.set("n", "j", "gj", { desc = "按视觉行向下移动" })
keymap.set("n", "k", "gk", { desc = "按视觉行向上移动" })
keymap.set("n", "J", "5j", { desc = "快速向下移动 5 行" })
keymap.set("n", "K", "5k", { desc = "快速向上移动 5 行" })

-- ======================== 竞赛模板内联复制 ========================
-- 只注册 <C-a><C-i>（内联自定义头 / ihxnan 模板并复制完整竞赛代码）。
-- clipboard.lua 的系统剪贴板映射（<C-c>/<C-x>/<C-v> 等）不在此注册，保留 VSCode 原生行为。
-- 原理：Ctrl+A / Ctrl+I 都在 vscode-neovim 的 ctrlKeysForNormalMode 里，normal 模式会被转发给
-- nvim，因此 <C-a><C-i> 序列可被匹配；setreg("+") 会同步到 VSCode 剪贴板。
local clipboard = require("config.clipboard")
clipboard.setup_template_copy()

-- ======================== 代码运行（转发到 VSCode 任务） ========================
-- vscode-neovim 不支持 nvim 内置 :terminal，因此改为调用 VSCode 任务，
-- 任务定义在 ~/.config/Code/User/tasks.json，使用 ${file}/${fileDirname} 指向当前文件。
-- Windows 适配：Windows 无 /tmp，数据文件改用 stdpath("data")/data
--（Windows 下即 %LOCALAPPDATA%\nvim-data\data，与 Windows 版 tasks 模板保持一致）；
-- Linux/macOS 下 DATA 恒为 "/tmp/data"，与原有硬编码值逐字相同。
local is_win = vim.fn.has("win32") == 1
local DATA = is_win and (vim.fn.stdpath("data") .. "/data") or "/tmp/data"
local TASKS = {
    cpp_data = "nvim: run cpp (data)",
    cpp_data_macro = "nvim: run cpp (data + macro)",
    cpp_macro = "nvim: run cpp (macro)",
    python = "nvim: run python",
    python_data = "nvim: run python (data)",
    cuda = "nvim: run cuda",
}

local function with_data(kind)
    return kind == "data" or kind == "data_macro"
end

local function run(kind)
    vim.cmd("write")
    local ft = vim.bo.filetype
    if ft == "python" then
        vim.fn.VSCodeNotify("workbench.action.tasks.runTask",
            with_data(kind) and TASKS.python_data or TASKS.python)
    elseif ft == "cuda" then
        vim.fn.VSCodeNotify("workbench.action.tasks.runTask", TASKS.cuda)
    elseif ft == "cpp" or ft == "c" then
        local label = TASKS.cpp_data
        if kind == "data_macro" then
            label = TASKS.cpp_data_macro
        elseif kind == "macro" then
            label = TASKS.cpp_macro
        elseif kind ~= "data" then
            label = TASKS.cpp_data_macro
        end
        vim.fn.VSCodeNotify("workbench.action.tasks.runTask", label)
    else
        print("暂不支持运行的文件类型: " .. ft)
    end
end

--- 复制剪贴板内容到 /tmp/data
local function paste_to_data()
    local content = vim.fn.getreg("+")
    if not content or content == "" then
        print("⚠️ 剪贴板为空，跳过写入")
        return
    end
    if not content:match("\n$") then
        content = content .. "\n" -- 末尾补换行，避免读入死循环
    end
    local f = io.open(DATA, "w")
    if f then
        f:write(content)
        f:close()
        print("✅ 已写入 " .. DATA .. " (" .. #content .. " 字节)")
    else
        print("❌ 无法写入 " .. DATA)
    end
end

--- 复制当前文件全部内容到系统剪贴板
local function copy_all()
    vim.cmd('normal! gg"+yG``')
end

keymap.set("n", "rc", function()
    paste_to_data()
    copy_all()
    run("data")
end, { desc = "剪贴板→data，复制全文，带数据运行" })
keymap.set("n", "rd", function() run("data_macro") end, { desc = "带数据运行（调试宏）" })
keymap.set("n", "rl", function() run("macro") end, { desc = "本地调试运行（调试宏）" })
keymap.set("n", "rp", function()
    paste_to_data()
    run("data_macro")
end, { desc = "粘贴剪贴板到 data 后带数据运行" })
keymap.set("n", "ru", function() run("cuda") end, { desc = "运行 CUDA/C/C++" })

-- dp：对拍工具。vscode-neovim 不支持 nvim 内置 :terminal，
-- 改为打开 VSCode 集成终端并预填命令（不自动回车，保留手动调参的习惯）。
-- VSCode 终端的 cwd 默认不是文件目录，而 dp 依赖 cwd 找 ans.cpp/test.cpp/data.cpp，故先 cd。
keymap.set("n", "dp", function()
    vim.cmd("write")
    local dir = vim.fn.expand("%:p:h")
    if dir == "" then
        dir = vim.fn.getcwd()
    end
    notify("workbench.action.terminal.focus")
    if is_win then
        -- Windows：VSCode 集成终端默认 profile 为 PowerShell 时用 Set-Location（路径用单引号包住）。
        -- 若默认 profile 是 cmd.exe：改用 cmd 风格（cd /d "<目录>" && dp）。
        notify("workbench.action.terminal.sendSequence", {
            text = "Set-Location -LiteralPath '" .. dir .. "'; dp",
        })
    else
        notify("workbench.action.terminal.sendSequence", { text = "cd '" .. dir .. "' && dp" })
    end
end, { desc = "打开集成终端并预填 dp（手动回车执行）" })
keymap.set("n", "cp", paste_to_data, { desc = "粘贴剪贴板到 data" })
keymap.set("n", "cd", function() vim.cmd.edit({ args = { DATA } }) end, { desc = "打开 data 文件" })
keymap.set("n", "ct", function() vim.cmd("edit ~/Github/Template") end, { desc = "打开算法模板" })

-- 说明：LSP（重命名 / 代码动作 / 诊断）与格式化（<leader>f）均由 VSCode 原生提供，
-- 本分支不注册对应映射；如需可转发到 editor.action.* 系列命令。
