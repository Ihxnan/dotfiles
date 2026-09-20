--
-- ██╗  ██╗███████╗██╗   ██╗███╗   ███╗ █████╗ ██████╗ ███████╗
-- ██║ ██╔╝██╔════╝╚██╗ ██╔╝████╗ ████║██╔══██╗██╔══██╗██╔════╝
-- █████╔╝ █████╗   ╚████╔╝ ██╔████╔██║███████║██████╔╝███████╗
-- ██╔═██╗ ██╔══╝    ╚██╔╝  ██║╚██╔╝██║██╔══██║██╔═══╝ ╚════██║
-- ██║  ██╗███████╗   ██║   ██║ ╚═╝ ██║██║  ██║██║     ███████║
-- ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝
--
--  功能：Neovim 自定义按键映射 + 多语言代码运行/预览 + 窗口/缓冲区高效管理

-- ======================== 1. 基础配置 ========================
vim.g.mapleader = " " -- 设置<leader>键为空格（自定义快捷键的前缀）
local keymap = vim.keymap -- 简化按键映射函数的调用（:help vim.keymap）
local clipboard = require("config.clipboard")
clipboard.setup_system_clipboard() -- 系统剪贴板快捷键（VSCode 分支不注册，保留 VSCode 原生 Ctrl+C/V/X）
clipboard.setup_template_copy() -- <C-a><C-i>：内联模板并复制完整竞赛代码

-- ======================== 1.1 平台判定与跨平台路径（Windows 适配） ========================
-- is_win 为真时，代码运行 / 终端 / 工具类快捷键走 Windows 实现
--（PowerShell 7 + MinGW-w64 g++）；其余平台一律走本文件原有实现，原有代码保持逐字不变
--（只在各函数开头加了 `if is_win then ...; return end` 形式的平台守卫）。
local is_win = vim.fn.has("win32") == 1

-- 算法输入数据文件：Linux/macOS 沿用 /tmp/data；Windows 无 /tmp，改用 stdpath("data")/data
--（Windows 下即 %LOCALAPPDATA%\nvim-data\data，与 Windows 版 tasks 模板里的路径一致；
--  可用 :lua= vim.fn.stdpath("data") 核对。Linux 下 DATA_FILE 恒为 "/tmp/data"，与原有硬编码值逐字相同）
local DATA_FILE = is_win and (vim.fn.stdpath("data") .. "/data") or "/tmp/data"

-- ======================== 2. 自定义函数 ========================

-- 2.1 ANSI 颜色常量 & 辅助函数（用于终端输出着色）
local C = {
	blue = "\\033[34m",
	cyan = "\\033[36m",
	yellow = "\\033[33m",
	green = "\\033[32m",
	red = "\\033[31m",
	reset = "\\033[0m",
}

--- 生成带颜色的 echo 命令片段
local function e(msg, color)
	return 'echo -e "' .. color .. msg .. C.reset .. '"'
end

--- 将命令列表拼接为 vsplit + terminal bash -c 的 Ex 命令
local function term_cmd(cmds)
	return "vsplit | terminal bash -c '" .. table.concat(cmds, "; ") .. "'"
end

-- 2.1.5 Windows 专用实现（PowerShell 7 + MinGW-w64 g++）============================
-- 仅在 is_win 为真时被调用；Linux / macOS 完全不经过这里。
-- 设计要点：
--   * 命令通过 pwsh 的 -EncodedCommand（base64 / UTF-16LE）传递，绕开
--     vim → &shell(cmd/pwsh) → pwsh 的多层引号、空格与中文路径转义问题；
--   * -EncodedCommand 是预先算好的 base64，vim 不会在其中展开 `%`，因此文件名一律
--     在 Lua 侧用 vim.fn.expand("%:p") 取绝对路径再自行加引号；
--   * 数据重定向：PowerShell 没有 `<` 操作符，改用 `Get-Content -Raw <file> | <exe>`；
--   * 计时用 Stopwatch（对应 Linux 分支的 `time`），避免 Measure-Command 吞掉输出。

--- Windows 上的 PowerShell 可执行名：优先 pwsh 7，缺失时回退 Windows PowerShell 5.1
---（下面的脚本只用 `;` + 显式判断，不依赖 pwsh 7 的 && 链，5.1 也能跑）
local PWSH = vim.fn.executable("pwsh") == 1 and "pwsh" or "powershell"

--- pwsh 双引号字符串字面量（转义反引号 / 双引号 / $）
local function ps_quote(s)
	local escaped = s:gsub("`", "``"):gsub('"', '`"'):gsub("%$", "`$")
	return '"' .. escaped .. '"'
end

--- 把 pwsh 脚本编译成 -EncodedCommand 参数：base64(UTF-16LE)
-- local function pwsh_encoded(script)
-- 	local ok, utf16 = pcall(vim.fn.iconv, script, "utf-8", "utf-16le")
-- 	if not ok or utf16 == "" then
-- 		-- iconv 不可用时的兜底：逐字节补 0（ASCII 安全；路径含非 ASCII 会失真）
-- 		utf16 = script:gsub(".", function(c)
-- 			return c .. "\0"
-- 		end)
-- 	end
-- 	return PWSH .. " -NoLogo -NoProfile -EncodedCommand " .. vim.base64.encode(utf16)
-- end

--- 将 pwsh 脚本放进 vsplit terminal 执行（term_cmd 的 Windows 版本）
-- local function term_cmd_win(script)
-- 	return "vsplit | terminal " .. pwsh_encoded(script)
-- end

--- 将 pwsh 脚本放进 vsplit terminal 执行（term_cmd 的 Windows 版本）
local function term_cmd_win(script)
	return "vsplit | terminal " .. PWSH .. " -NoLogo -NoProfile -Command " .. ps_quote(script)
end

--- 用 "; " 把多条 pwsh 语句拼接成单条脚本（pwsh 7 支持 && / ||，但这里统一用 ; + 显式判断）
local function win_script(steps)
	return table.concat(steps, "; ")
end

--- MinGW-w64 默认不带 libasan / libubsan，加 -fsanitize=... 会链接失败。
--- 若用的是 llvm-mingw（自带 ASan/UBSan）或已安装 libasan，可改为：
---   local WIN_CPP_FLAGS = "-O2 -Wall -Wextra -fsanitize=address,undefined -g"
local WIN_CPP_FLAGS = "-O2 -Wall -Wextra"

--- Windows 下的 C/C++ 编译运行脚本（with_data 决定是否从 DATA_FILE 喂输入）
local function win_cpp_script(file_q, macro, with_data)
	local run = with_data and ("Get-Content -Raw " .. ps_quote(DATA_FILE) .. " | .\\a.exe") or ".\\a.exe"
	return win_script({
		"Write-Host '[Compile] MinGW-w64 g++ ...' -ForegroundColor Blue",
		"g++ " .. WIN_CPP_FLAGS .. macro .. " " .. file_q .. " -o a.exe",
		"if ($LASTEXITCODE -ne 0) { Write-Host '[Error] Compilation failed!' -ForegroundColor Red; exit 1 }",
		"Write-Host '[Run] Program output:' -ForegroundColor Cyan",
		"$sw = [Diagnostics.Stopwatch]::StartNew()",
		run,
		"$sw.Stop(); Write-Host ('[Time] {0:N3} s' -f $sw.Elapsed.TotalSeconds) -ForegroundColor DarkGray",
		"Write-Host '[Clean] Removing a.exe' -ForegroundColor Yellow",
		"Remove-Item -ErrorAction SilentlyContinue a.exe",
		"Write-Host '[Done] All operations completed' -ForegroundColor Green",
	})
end

--- Windows 版代码运行（对应 run_code）
local function run_code_win(with_data, with_macro)
	vim.cmd("w")
	local ft = vim.bo.filetype
	local file_q = ps_quote(vim.fn.expand("%:p"))
	local data_label = with_data and "（带数据）" or ""
	print("🚀 正在运行 " .. ft .. data_label .. " ... (Windows/pwsh)")

	if ft == "cpp" or ft == "c" then
		local macro = with_macro and " -DIHXNAN" or ""
		vim.cmd(term_cmd_win(win_cpp_script(file_q, macro, with_data)))
	elseif ft == "python" then
		local run_cmd = with_data and ("Get-Content -Raw " .. ps_quote(DATA_FILE) .. " | python -B " .. file_q)
			or ("python -B " .. file_q)
		vim.cmd(term_cmd_win(win_script({
			"Write-Host '[Check] Syntax checking...' -ForegroundColor Blue",
			"python -B -m py_compile " .. file_q,
			"if ($LASTEXITCODE -ne 0) { Write-Host '[Error] Syntax error! Fix your code' -ForegroundColor Red; exit 1 }",
			"Write-Host '[Run] Executing Python file' -ForegroundColor Cyan",
			"$sw = [Diagnostics.Stopwatch]::StartNew()",
			run_cmd,
			"$sw.Stop(); Write-Host ('[Time] {0:N3} s' -f $sw.Elapsed.TotalSeconds) -ForegroundColor DarkGray",
			"Get-ChildItem -Recurse -Directory -Filter __pycache__ -ErrorAction SilentlyContinue"
				.. " | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue",
			"Write-Host '[Done] Python finished' -ForegroundColor Green",
		})))
	elseif ft == "java" then
		if with_data then
			print("⚠️ Java 暂不支持带数据运行")
			return
		end
		local class_stem = vim.fn.expand("%:t:r")
		vim.cmd(term_cmd_win(win_script({
			"javac " .. file_q,
			"if ($LASTEXITCODE -eq 0) { java " .. ps_quote(class_stem) .. " }",
			-- 注意：.class 必须拼进 ps_quote 内，否则 pwsh 会把 "Name".class 当成字符串属性访问
			"Remove-Item -ErrorAction SilentlyContinue " .. ps_quote(class_stem .. ".class"),
		})))
	elseif ft == "cmake" then
		if with_data then
			print("⚠️ CMake 暂不支持带数据运行")
			return
		end
		print("🔧 正在构建 CMake 项目 ...")
		vim.cmd(term_cmd_win(win_script({
			"Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue",
			"New-Item -ItemType Directory -Force build | Out-Null",
			"Push-Location build",
			"cmake -G 'MinGW Makefiles' ..",
			"cmake --build .",
			"Pop-Location",
		})))
	elseif ft == "sh" then
		if with_data then
			print("⚠️ Shell 暂不支持带数据运行")
			return
		end
		-- Windows 无 sh：PATH 里有 Git Bash / WSL 的 bash 时用它，否则明确提示
		vim.cmd(term_cmd_win(win_script({
			"if (Get-Command bash -ErrorAction SilentlyContinue) { bash "
				.. file_q
				.. " } else { Write-Host '[Skip] Windows 需 Git Bash / WSL 才能运行 .sh' -ForegroundColor Yellow }",
		})))
	elseif ft == "html" then
		if with_data then
			print("⚠️ HTML 暂不支持带数据运行")
			return
		end
		vim.cmd(term_cmd_win(win_script({ "Start-Process " .. file_q })))
	else
		print("❌ 不支持的文件类型: " .. ft)
	end
end

--- Windows 版本地调试运行（对应 run_local；C/C++ 带 -DIHXNAN）
local function run_local_win()
	vim.cmd("w")
	local ft = vim.bo.filetype

	if ft == "cpp" or ft == "c" then
		print("🚀 正在运行 " .. ft .. "（本地调试模式）... (Windows/pwsh)")
		vim.cmd(term_cmd_win(win_cpp_script(ps_quote(vim.fn.expand("%:p")), " -DIHXNAN", false)))
	else
		-- 其他文件类型回退到普通运行
		run_code_win(false, false)
	end
end

--- Windows 版 CUDA / C / C++ 运行（对应 run_cuda）
local function run_cuda_win()
	vim.cmd("w")
	local filetype = vim.bo.filetype

	if filetype == "cuda" or filetype == "c" or filetype == "cpp" then
		vim.cmd(term_cmd_win(win_script({
			"nvcc -arch=sm_89 " .. ps_quote(vim.fn.expand("%:p")) .. " -o a.exe",
			"if ($LASTEXITCODE -eq 0) { .\\a.exe }",
			"Remove-Item -ErrorAction SilentlyContinue a.exe",
		})))
	else
		print("不支持的文件类型: " .. filetype)
	end
end
-- ======================== Windows 实现结束 ========================

-- 2.2 多语言代码通用运行
--- 运行代码（可选带输入数据重定向；with_macro 为 true 时编译加本地调试宏 -DIHXNAN）
local function run_code(with_data, with_macro)
	-- Windows 平台守卫（Linux / macOS 不进入，下面原代码逐字未改）
	if is_win then
		run_code_win(with_data, with_macro)
		return
	end
	vim.cmd("w")
	local ft = vim.bo.filetype
	local data_label = with_data and "（带数据）" or ""
	local data_redirect = with_data and " < /tmp/data" or ""

	print("🚀 正在运行 " .. ft .. data_label .. " ...")

	if ft == "cpp" or ft == "c" then
		-- with_macro 为 true 时（rl/rd/rp）编译加本地调试宏 -DIHXNAN；rc 不加
		local macro = with_macro and " -DIHXNAN" or ""
		local cmds = {
			e("[Compile] Starting C++ compilation...", C.blue),
			'g++ -O2 -fsanitize=address,undefined,leak "%" -o a.out' .. macro .. " 2>&1",
			"if [ $? -eq 0 ]; then " .. e("[Run] Program output:", C.cyan),
			"time ./a.out" .. data_redirect,
			e("[Clean] Removing temporary file a.out", C.yellow),
			"rm -f a.out",
			e("[Done] All operations completed", C.green),
			"else " .. e("[Error] Compilation failed! Please fix your code and try again", C.red),
			"fi",
		}
		vim.cmd(term_cmd(cmds))
	elseif ft == "python" then
		local cmds = {
			e("[Check] Syntax checking...", C.blue),
			'python3 -B -m py_compile "%" 2>&1',
			"if [ $? -eq 0 ]; then "
				.. e("[Run] Executing Python file" .. (with_data and " (with input data)" or "") .. "...", C.cyan),
			'time python3 -B "%"'
				.. data_redirect
				.. "| lolcat; find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null",
			e("[Done] Python finished", C.green),
			"else " .. e("[Error] Syntax error! Fix your code", C.red),
			"fi",
		}
		vim.cmd(term_cmd(cmds))
	elseif ft == "java" then
		if with_data then
			print("⚠️ Java 暂不支持带数据运行")
			return
		end
		local class_name = vim.fn.expand("%:t:r")
		vim.cmd("split | terminal javac % && java " .. class_name .. "; rm -f " .. class_name .. ".class")
	elseif ft == "cmake" then
		if with_data then
			print("⚠️ CMake 暂不支持带数据运行")
			return
		end
		print("🔧 正在构建 CMake 项目 ...")
		vim.cmd("split | terminal rm -rf build && mkdir build && cd build && cmake .. && make; $SHELL")
		vim.cmd("startinsert")
	elseif ft == "sh" then
		if with_data then
			print("⚠️ Shell 暂不支持带数据运行")
			return
		end
		vim.cmd("split | terminal sh %")
	elseif ft == "html" then
		if with_data then
			print("⚠️ HTML 暂不支持带数据运行")
			return
		end
		vim.cmd("split | terminal chromium %")
	else
		print("❌ 不支持的文件类型: " .. ft)
	end
end

-- 2.3 本地调试运行（C/C++ 带 -DIHXNAN 宏）
local run_local = function()
	-- Windows 平台守卫（Linux / macOS 不进入，下面原代码逐字未改）
	if is_win then
		run_local_win()
		return
	end
	vim.cmd("w")
	local ft = vim.bo.filetype

	-- 仅 C/C++ 使用带 -DIHXNAN 的编译方式（启用本地调试宏）
	if ft == "cpp" or ft == "c" then
		print("🚀 正在运行 " .. ft .. "（本地调试模式）...")
		local cmds = {
			e("[Compile] Starting C++ compilation (local debug)...", C.blue),
			'g++ -O2 -fsanitize=address,undefined,leak "%" -o a.out -DIHXNAN 2>&1',
			"if [ $? -eq 0 ]; then " .. e("[Run] Program output:", C.cyan),
			"time ./a.out",
			e("[Clean] Removing temporary file a.out", C.yellow),
			"rm -f a.out",
			e("[Done] All operations completed", C.green),
			"else " .. e("[Error] Compilation failed! Please fix your code and try again", C.red),
			"fi",
		}
		vim.cmd(term_cmd(cmds))
	else
		-- 其他文件类型回退到普通运行
		run_code(false)
	end
end

-- 2.4 CUDA/C/C++ 运行
local run_cuda = function()
	-- Windows 平台守卫（Linux / macOS 不进入，下面原代码逐字未改）
	if is_win then
		run_cuda_win()
		return
	end
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

-- 2.5 HTML 实时预览 & 关闭
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

local close_code = function()
	local filetype = vim.bo.filetype

	if filetype == "html" then
		vim.cmd("LivePreview close") -- 关闭LivePreview预览窗口
	else
		print("不支持的文件类型: " .. filetype)
	end
end

-- 2.6 剪贴板工具
--- 粘贴剪贴板内容到 data 文件
local paste_to_data = function()
	local content = vim.fn.getreg("+")
	if not content or content == "" then
		print("⚠️ 剪贴板为空，跳过写入")
		return
	end
	local file = io.open(DATA_FILE, "w") -- Linux 下 DATA_FILE 恒为 "/tmp/data"
	if file then
		-- 确保末尾有换行符，避免 C++ 的 gc() 读到 EOF 后死循环
		local to_write = content
		if not to_write:match("\n$") then
			to_write = to_write .. "\n"
		end
		file:write(to_write)
		file:close()
		local lines = vim.fn.substitute(content, "[^\\n]", "", "g")
		local line_count = #lines + 1
		local preview = content:len() > 40 and content:sub(1, 40) .. "…" or content
		print("✅ 已写入 " .. line_count .. " 行到 data 文件 (" .. content:len() .. " 字节)")
	else
		print("❌ 错误：无法打开 data 文件写入")
	end
end

--- 粘贴剪贴板内容 + 延迟运行代码（带数据）
local run_code_with_paste = function()
	vim.cmd("w")
	paste_to_data()
	vim.defer_fn(function()
		run_code(true, true)
	end, 50)
end

-- ======================== 3. 通用模式快捷键 ========================

-- 3.1 插入模式
keymap.set("i", "jk", "<ESC>") -- 快速退出插入模式（替代ESC键，减少抬手）
keymap.set("i", "<C-s>", "<ESC>:w<CR>") -- 插入模式下Ctrl+s快速保存

-- 3.2 终端模式
keymap.set("t", "jk", "<C-\\><C-n>") -- 终端模式下jk退出到普通模式

-- 3.3 视觉模式
keymap.set("v", "J", ":m '>+1<CR>gv=gv") -- 选中行向下移动
keymap.set("v", "K", ":m '<-2<CR>gv=gv") -- 选中行向上移动
keymap.set("v", "ii", "<ESC>") -- 视觉模式下ii退出到普通模式
keymap.set("v", "<C-c>", '"+y') -- 视觉模式下Ctrl+c复制选中内容到系统剪贴板

-- ======================== 4. 窗口管理 ========================

-- 4.1 窗口导航 - 插入模式
keymap.set("i", "<C-h>", "<ESC><C-w>h", { desc = "插入模式：切换到左侧窗口" })
keymap.set("i", "<C-j>", "<ESC><C-w>j", { desc = "插入模式：切换到下方窗口" })
keymap.set("i", "<C-k>", "<ESC><C-w>k", { desc = "插入模式：切换到上方窗口" })
keymap.set("i", "<C-l>", "<ESC><C-w>l", { desc = "插入模式：切换到右侧窗口" })

-- 4.2 窗口导航 - 终端模式
keymap.set("t", "<C-h>", "<C-\\><C-n><C-w>h", { desc = "终端模式：切换到左侧窗口" })
keymap.set("t", "<C-j>", "<C-\\><C-n><C-w>j", { desc = "终端模式：切换到下方窗口" })
keymap.set("t", "<C-k>", "<C-\\><C-n><C-w>k", { desc = "终端模式：切换到上方窗口" })
keymap.set("t", "<C-l>", "<C-\\><C-n><C-w>l", { desc = "终端模式：切换到右侧窗口" })

-- 4.3 窗口导航 - 普通模式
keymap.set("n", "<C-h>", "<C-w>h", { desc = "切换到左侧窗口" })
keymap.set("n", "<C-j>", "<C-w>j", { desc = "切换到下方窗口" })
keymap.set("n", "<C-k>", "<C-w>k", { desc = "切换到上方窗口" })
keymap.set("n", "<C-l>", "<C-w>l", { desc = "切换到右侧窗口" })

-- 4.4 窗口创建
keymap.set("n", "<leader>wv", "<C-w>s", { desc = "Leader+wv：水平分割窗口（上下）" })
keymap.set("n", "<leader>wh", "<C-w>v", { desc = "Leader+wh：垂直分割窗口（左右）" })

-- 4.5 窗口位置移动
keymap.set("n", "gwh", "<C-w>H", { desc = "gwh：将当前窗口移到最左侧" })
keymap.set("n", "gwj", "<C-w>J", { desc = "gwj：将当前窗口移到最下方" })
keymap.set("n", "gwk", "<C-w>K", { desc = "gwk：将当前窗口移到最上方" })
keymap.set("n", "gwl", "<C-w>L", { desc = "gwl：将当前窗口移到最右侧" })

-- 4.6 窗口关闭
keymap.set("n", "gwd", "<C-w>q", { desc = "gwd：关闭当前窗口" })
keymap.set("n", "gwo", "<C-w>o", { desc = "gwo：关闭其他所有窗口" })

-- 4.7 窗口大小调整
keymap.set("n", "<M-=>", "<C-w>>", { desc = "Alt+=：扩大当前窗口宽度" })
keymap.set("n", "<M-->", "<C-w><", { desc = "Alt+-：缩小当前窗口宽度" })

-- ======================== 5. 缓冲区管理 ========================

-- 5.1 缓冲区切换（基于 BufferLine 插件）
keymap.set("n", "H", ":w<CR>:BufferLineCyclePre<CR>", { desc = "Shift+H：保存并切换到上一个缓冲区" })
keymap.set("n", "L", ":w<CR>:BufferLineCycleNext<CR>", { desc = "Shift+L：保存并切换到下一个缓冲区" })

-- 5.2 缓冲区基本操作
keymap.set("n", "gbh", ":bprevious<CR>", { desc = "gbh：切换到上一个缓冲区" })
keymap.set("n", "gbl", ":bnext<CR>", { desc = "gbl：切换到下一个缓冲区" })
keymap.set("n", "gbd", ":bdelete<CR>", { desc = "gbd：关闭当前缓冲区" })
keymap.set("n", "gbo", ":BufferLineCloseOthers<CR>", { desc = "gbo：关闭其他所有缓冲区" })

-- ======================== 6. 代码运行快捷键 ========================
keymap.set("n", "rc", function()
	-- 1. 剪贴板内容写入 data；2. 复制完整代码到剪贴板；3. 带数据运行（不加 -DIHXNAN）
	paste_to_data()
	clipboard.copy_all_with_info()
	run_code(true, false)
end, { desc = "rc：剪贴板→data，复制完整代码，带数据运行（无宏）" })
keymap.set("n", "rl", run_local, { desc = "rl：本地调试运行C/C++代码（带 -DIHXNAN 宏）" })
keymap.set("n", "ru", run_cuda, { desc = "ru：运行CUDA/C/C++代码" })
keymap.set("n", "rd", function()
	run_code(true, true)
end, { desc = "rd：带数据运行代码（算法刷题，带 -DIHXNAN）" })
keymap.set(
	"n",
	"rp",
	run_code_with_paste,
	{ desc = "rp：粘贴剪贴板到 data 后带数据运行代码（带 -DIHXNAN）" }
)
keymap.set(
	"n",
	"dp",
	is_win and ":w<CR><C-w>v:terminal<CR>idp" or ":w<CR><C-w>v:terminal fish -l<CR>idp",
	{ desc = "dp：保存并运行dp工具（-k参数）" }
)
-- Windows 下 DATA_FILE 是绝对路径（形如 %LOCALAPPDATA%\nvim-data\data），含空格时 Ex 命令需 fnameescape；
-- Linux 分支保持原有拼接，rhs 与改动前逐字相同（仍为 ":e /tmp/data<CR>"）。
keymap.set(
	"n",
	"cd",
	is_win and (":e " .. vim.fn.fnameescape(DATA_FILE) .. "<CR>") or (":e " .. DATA_FILE .. "<CR>"),
	{ desc = "cd：快速打开算法输入数据文件" }
)
keymap.set("n", "cp", paste_to_data, { desc = "cp：覆盖写入剪贴板内容到 data 文件" })
keymap.set("n", "ct", ":e ~/Github/Template<CR>", { desc = "ct：快速打开算法模板文件" })

-- ======================== 7. HTML 预览快捷键 ========================
keymap.set("n", "gmp", preview_code, { desc = "gmp：启动HTML实时预览" })
keymap.set("n", "gmc", close_code, { desc = "gmc：关闭HTML实时预览" })

-- ======================== 8. 搜索与导航 ========================
keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Leader+nh：取消搜索高亮" })
keymap.set("n", "n", "nzz", { desc = "n：搜索下一个并居中显示" })
keymap.set("n", "N", "Nzz", { desc = "N：搜索上一个并居中显示" })

-- ======================== 9. 编辑效率 ========================

-- 9.1 常用工具启动
keymap.set(
	"n",
	"<C-g>",
	is_win and ":tabe<CR>:term lazygit<CR>i" or ":tabe<CR>:term fish -l -c lazygit<CR>i",
	{ desc = "Ctrl+g：新建标签页并打开lazygit" }
)
keymap.set(
	"n",
	"<leader>t",
	is_win and ":w<CR><C-w>v:terminal<CR>" or ":w<CR><C-w>v:terminal fish -l<CR>i",
	{ desc = "Leader+t：保存并新建垂直终端窗口（fish 登录模式）" }
)
keymap.set(
	"n",
	"<leader>s",
	is_win and ":w<CR><C-w>s:terminal<CR>" or ":w<CR><C-w>s:terminal fish -l<CR>i",
	{ desc = "Leader+t：保存并新建水平终端窗口（fish 登录模式）" }
)
keymap.set(
	"n",
	"<leader>i",
	is_win and ":w<CR><C-w>v:terminal<CR>ireasonix<CR>" or ":w<CR><C-w>v:terminal fish -l<CR>ireasonix<CR>",
	{ desc = "Leader+i：保存并打开reasonix工具" }
)
keymap.set({ "n", "t" }, "<A-t>", "<Cmd>ToggleTerm<CR>", { desc = "Alt+t：切换 toggleterm 悬浮终端" })
keymap.set(
	"n",
	"<F5>",
	is_win and ":w<CR>:silent !code .<CR>" or ":w<CR>:silent !code . &<CR>",
	{ desc = "F5：保存并在VSCode中打开当前目录" }
)

-- 9.2 快速保存
keymap.set("n", "<C-S>", ":w<CR>", { desc = "Ctrl+S：快速保存" })

-- 9.3 光标快速移动（兼容折行）
keymap.set("n", "j", "gj", { desc = "j：按视觉行向下移动" })
keymap.set("n", "k", "gk", { desc = "k：按视觉行向上移动" })
keymap.set("n", "J", "5j", { desc = "J：快速向下移动5行" })
keymap.set("n", "K", "5k", { desc = "K：快速向上移动5行" })

local submit = function()
	vim.cmd("w")
	local name = vim.fn.expand("%:p")
	print("正在提交：" .. name)

	vim.system({
		"/home/ihxnan/.local/bin/server",
		"push",
		name,
	}, { text = true }, function(res)
		-- 回调函数不在 nvim 主线程，必须套 vim.schedule
		vim.schedule(function()
			if res.code == 0 then
				vim.notify("✅ 提交成功\n" .. res.stdout, vim.log.levels.INFO)
			else
				vim.notify("❌ 提交失败\n" .. res.stderr, vim.log.levels.ERROR)
			end
		end)
	end)
end

keymap.set("n", "<leader>p", submit, { desc = "Leader+p: 把当前文件提交到服务器" })

keymap.set("n", "<leader>q", ":q<CR>")
