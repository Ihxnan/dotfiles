--
-- ██╗  ██╗███████╗██╗   ██╗███╗   ███╗ █████╗ ██████╗ ███████╗
-- ██║ ██╔╝██╔════╝╚██╗ ██╔╝████╗ ████║██╔══██╗██╔══██╗██╔════╝
-- █████╔╝ █████╗   ╚████╔╝ ██╔████╔██║███████║██████╔╝███████╗
-- ██╔═██╗ ██╔══╝    ╚██╔╝  ██║╚██╔╝██║██╔══██║██╔═══╝ ╚════██║
-- ██║  ██╗███████╗   ██║   ██║ ╚═╝ ██║██║  ██║██║     ███████║
-- ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝
--
--  功能：Neovim 自定义按键映射 + 多语言代码运行/预览 + 窗口/缓冲区高效管理

-- ======================== 基础配置 ========================
vim.g.mapleader = " "     -- 设置<leader>键为空格（自定义快捷键的前缀）
local keymap = vim.keymap -- 简化按键映射函数的调用（:help vim.keymap）

-- ======================== 自定义函数：运行CUDA/C/C++代码 ========================
local run_cuda = function()
    vim.cmd("w") -- 执行前先保存当前文件，避免运行旧代码

    -- 获取当前缓冲区的文件类型（如cuda/c/cpp）
    local filetype = vim.bo.filetype

    -- 根据文件类型执行对应编译运行命令
    if filetype == "cuda" or filetype == "c" or filetype == "cpp" then
        -- 分割窗口并打开终端，执行：
        -- 1. nvcc编译（指定架构sm_89，适配RTX 30/40系显卡）
        -- 2. 运行生成的a.out
        -- 3. 运行后删除a.out临时文件
        vim.cmd("split | terminal nvcc -arch=sm_89 % && ./a.out && rm -f a.out")
    else
        -- 非支持类型给出提示
        print("不支持的文件类型: " .. filetype)
    end
end

-- ======================== 自定义函数：多语言代码通用运行 ========================
local run_code = function()
    vim.cmd("w")                     -- 执行前保存文件
    local filetype = vim.bo.filetype -- 获取当前文件类型

    -- 按文件类型执行不同编译/运行命令
    if filetype == "cpp" or filetype == "c" then
        -- C/C++：g++编译（-O3开启最高级优化）→ 运行 → 删除临时文件
        vim.cmd(
            [[vsplit | terminal bash -c 'echo -e "\033[34m[编译] 开始编译 C++ 文件...\033[0m"; g++ -O3 -fsanitize=undefined "%" -o a.out; if [ $? -eq 0 ]; then echo -e "\033[36m[运行] 程序输出结果：\033[0m"; time ./a.out | lolcat; echo -e "\033[33m[清理] 删除临时文件 a.out\033[0m"; rm -f a.out; echo -e "\033[32m[完成] 所有操作执行完毕\033[0m"; else echo -e "\033[31m[错误] 编译失败！请修复代码后重试\033[0m"; fi']])
    elseif filetype == "python" then
        -- Python：直接用python3运行当前文件
        vim.cmd("split | terminal python3 %")
    elseif filetype == "java" then
        -- Java：先编译 → 运行（取文件名作为类名）→ 删除.class文件 → 保留终端
        local class_name = vim.fn.expand("%:t:r") -- 提取文件名（不含路径和后缀）
        vim.cmd("split | terminal javac % && java " .. class_name .. " | lolcat; rm -f " .. class_name .. ".class")
    elseif filetype == "cmake" then
        -- CMake：清理旧build → 创建新build → 进入build编译 → 保留终端
        vim.cmd("split | terminal rm -rf build && mkdir build && cd build && cmake .. && make; $SHELL")
        vim.cmd("startinsert") -- 自动进入终端插入模式
    elseif filetype == "sh" then
        -- Shell脚本：直接运行
        vim.cmd("split | terminal sh %")
    elseif filetype == "html" then
        -- HTML：用chromium浏览器打开预览
        vim.cmd("split | terminal chromium %")
    else
        print("不支持的文件类型: " .. filetype)
    end
end

-- ======================== 自定义函数：带输入数据运行代码 ========================
local run_code_with_data = function()
    vim.cmd("w") -- 执行前保存文件
    local filetype = vim.bo.filetype

    -- 仅支持C/C++/Python，从指定路径读取输入数据（算法刷题常用）
    if filetype == "cpp" or filetype == "c" then
        -- 编译后，从~/WorkSpace/Algorithm/data读取输入数据
        vim.cmd("split | terminal g++ -O3 % && ./a.out < ~/WorkSpace/Algorithm/data && rm -f a.out")
    elseif filetype == "python" then
        vim.cmd("split | terminal python3 % < ~/WorkSpace/Algorithm/data")
    else
        print("不支持的文件类型: " .. filetype)
    end
end

-- ======================== 自定义函数：HTML实时预览 ========================
local preview_code = function()
    vim.cmd("w") -- 保存文件
    local filetype = vim.bo.filetype

    -- 仅支持HTML，调用LivePreview插件启动实时预览
    if filetype == "html" then
        vim.cmd("LivePreview start")
    else
        print("不支持的文件类型: " .. filetype)
    end
end

-- ======================== 自定义函数：关闭HTML预览 ========================
local close_code = function()
    local filetype = vim.bo.filetype

    if filetype == "html" then
        vim.cmd("LivePreview close") -- 关闭LivePreview预览窗口
    else
        print("不支持的文件类型: " .. filetype)
    end
end

-- ======================== 插入模式 (i-mode) 快捷键 ========================
keymap.set("i", "jk", "<ESC>")          -- 快速退出插入模式（替代ESC键，减少抬手）
keymap.set("i", "<C-s>", "<ESC>:w<CR>") -- 插入模式下Ctrl+s快速保存

-- 插入模式下快速切换窗口（无需先退出插入模式）
keymap.set("i", "<C-h>", "<ESC><C-w>h", { desc = "插入模式：切换到左侧窗口" })
keymap.set("i", "<C-j>", "<ESC><C-w>j", { desc = "插入模式：切换到下方窗口" })
keymap.set("i", "<C-k>", "<ESC><C-w>k", { desc = "插入模式：切换到上方窗口" })
keymap.set("i", "<C-l>", "<ESC><C-w>l", { desc = "插入模式：切换到右侧窗口" })

-- ======================== 终端模式 (t-mode) 快捷键 ========================
keymap.set("t", "jk", "<C-\\><C-n>") -- 终端模式下jk退出到普通模式
-- 终端模式下快速切换窗口（先退出终端插入模式，再切换）
keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc = "终端模式：切换到左侧窗口" })
keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j", { desc = "终端模式：切换到下方窗口" })
keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k", { desc = "终端模式：切换到上方窗口" })
keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l", { desc = "终端模式：切换到右侧窗口" })

-- ======================== 视觉模式 (v-mode) 快捷键 ========================
-- 选中行上下移动（移动后保持选中状态并重新缩进）
keymap.set("v", "J", ":m '>+1<CR>gv=gv") -- 选中行向下移动
keymap.set("v", "K", ":m '<-2<CR>gv=gv") -- 选中行向上移动
keymap.set("v", "ii", "<ESC>")           -- 视觉模式下ii退出到普通模式
keymap.set("v", "<C-c>", "y")            -- 视觉模式下Ctrl+c复制选中内容（兼容系统习惯）

-- ======================== 普通模式 (n-mode) 快捷键 ========================
-- 窗口管理：新建窗口
keymap.set("n", "<leader>wv", "<C-w>s", { desc = "Leader+wv：水平分割窗口（上下）" })
keymap.set("n", "<leader>wh", "<C-w>v", { desc = "Leader+wh：垂直分割窗口（左右）" })
keymap.set("n", "<C-g>", ":tabe<CR>:term lazygit<CR>i") -- Ctrl+g：新建标签页并打开lazygit
keymap.set("n", "<leader>t", ":w<CR><C-w>v:terminal<CR>i", { desc = "Leader+t：保存并新建垂直终端窗口（插入模式）" })
keymap.set("n", "<leader>i", ":w<CR><C-w>v:terminal<CR>iiflow<CR>", { desc = "Leader+i：保存并打开iflow工具" })

-- 代码运行相关快捷键
keymap.set("n", "rc", run_code, { desc = "普通模式rc：运行当前代码（多语言通用）" })
keymap.set("n", "ru", run_cuda, { desc = "普通模式ru：运行CUDA/C/C++代码" })
keymap.set("n", "cd", ":e ~/WorkSpace/Algorithm/data<CR>", { desc = "普通模式cd：快速打开算法输入数据文件" })
keymap.set("n", "rd", run_code_with_data, { desc = "普通模式rd：带输入数据运行代码（算法刷题）" })
keymap.set("n", "dp", ":w<CR><C-w>v:terminal<CR>idp -k", { desc = "普通模式dp：保存并运行dp工具（-k参数）" })
keymap.set("n", "<F5>", ":w<CR>:silent !code . &<CR>", { desc = "F5：保存并在VSCode中打开当前目录（调试用）" })

-- 窗口焦点切换（普通模式）
keymap.set("n", "<C-h>", "<C-w>h", { desc = "普通模式Ctrl+h：切换到左侧窗口" })
keymap.set("n", "<C-j>", "<C-w>j", { desc = "普通模式Ctrl+j：切换到下方窗口" })
keymap.set("n", "<C-k>", "<C-w>k", { desc = "普通模式Ctrl+k：切换到上方窗口" })
keymap.set("n", "<C-l>", "<C-w>l", { desc = "普通模式Ctrl+l：切换到右侧窗口" })

-- 窗口位置移动（将当前窗口移动到指定方向）
keymap.set("n", "gwh", "<C-w>H", { desc = "gwh：将当前窗口移到最左侧" })
keymap.set("n", "gwj", "<C-w>J", { desc = "gwj：将当前窗口移到最下方" })
keymap.set("n", "gwk", "<C-w>K", { desc = "gwk：将当前窗口移到最上方" })
keymap.set("n", "gwl", "<C-w>L", { desc = "gwl：将当前窗口移到最右侧" })

-- 窗口关闭
keymap.set("n", "gwd", "<C-w>q", { desc = "gwd：关闭当前窗口" })
keymap.set("n", "gwo", "<C-w>o", { desc = "gwo：关闭其他所有窗口，仅保留当前窗口" })

-- 窗口大小调整（Alt+=/-）
vim.keymap.set("n", "<M-=>", "<C-w>>", { desc = "Alt+=：扩大当前窗口宽度" })
vim.keymap.set("n", "<M-->", "<C-w><", { desc = "Alt+-：缩小当前窗口宽度" })

-- 搜索相关
keymap.set("n", "<leader>nh", ":nohl<CR>") -- Leader+nh：取消搜索高亮

-- 缓冲区（标签页）管理
keymap.set("n", "gbh", ":bprevious<CR>", { desc = "gbh：切换到上一个缓冲区" })
keymap.set("n", "gbl", ":bnext<CR>", { desc = "gbl：切换到下一个缓冲区" })
keymap.set("n", "gbd", ":bdelete<CR>", { desc = "gbd：关闭当前缓冲区" })
keymap.set("n", "gbo", ":BufferLineCloseOthers<CR>", { desc = "gbo：关闭其他所有缓冲区" })

-- BufferLine插件：切换缓冲区（保存后切换，避免丢失修改）
keymap.set("n", "H", ":w<CR>:BufferLineCyclePre<CR>")  -- H：保存并切换到上一个缓冲区
keymap.set("n", "L", ":w<CR>:BufferLineCycleNext<CR>") -- L：保存并切换到下一个缓冲区

-- HTML预览
keymap.set("n", "gmp", preview_code) -- gmp：启动HTML实时预览
keymap.set("n", "gmc", close_code)   -- gmc：关闭HTML实时预览

-- 快速保存/编辑效率
keymap.set("n", "<C-S>", ":w<CR>") -- 普通模式Ctrl+S快速保存
keymap.set("n", "j", "gj")         -- j：按视觉行向下移动（兼容折行）
keymap.set("n", "k", "gk")         -- k：按视觉行向上移动（兼容折行）
keymap.set("n", "J", "5j")         -- J：快速向下移动5行
keymap.set("n", "K", "5k")         -- K：快速向上移动5行
keymap.set("n", "n", "nzz")        -- n：搜索下一个并居中显示
keymap.set("n", "N", "Nzz")        -- N：搜索上一个并居中显示

-- 快速剪切/复制/粘贴（兼容系统操作习惯）
keymap.set("n", "<C-x>", "dd")           -- Ctrl+x：剪切当前行
keymap.set("n", "<C-c>", "yy")           -- Ctrl+c：复制当前行
keymap.set("n", "<C-a><C-c>", "ggyG``")  -- Ctrl+a+Ctrl+c：复制全部内容
keymap.set("n", "<C-a><C-x>", "ggdG")    -- Ctrl+a+Ctrl+x：剪切全部内容
keymap.set("n", "<C-v>", "p")            -- Ctrl+v：粘贴内容
keymap.set("n", "<C-a><C-v>", "gg0vG$p") -- Ctrl+a+Ctrl+v：覆盖粘贴全部内容
