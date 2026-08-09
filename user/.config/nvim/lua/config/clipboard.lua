--
--  ██████╗██╗     ██╗██████╗ ██████╗  ██████╗  █████╗ ██████╗ ██████╗
-- ██╔════╝██║     ██║██╔══██╗██╔══██╗██╔═══██╗██╔══██╗██╔══██╗██╔══██╗
-- ██║     ██║     ██║██████╔╝██████╔╝██║   ██║███████║██████╔╝██████╔╝
-- ██║     ██║     ██║██╔═══╝ ██╔══██╗██║   ██║██╔══██║██╔══██╗██╔══██╗
-- ╚██████╗███████╗██║██║     ██████╔╝╚██████╔╝██║  ██║██║  ██║██████╔╝
--  ╚═════╝╚══════╝╚═╝╚═╝     ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝
--
--  功能：剪贴板操作快捷键 + 竞赛代码模板一键复制
--        - Ctrl+x / Ctrl+c / Ctrl+v 兼容系统剪贴板
--        - Ctrl+a+Ctrl+i 内联模板引用并复制完整竞赛代码

local keymap = vim.keymap

-- ======================== 系统剪贴板快捷键 ========================
-- 兼容 Windows 系统剪贴板 + 黑洞寄存器
keymap.set("n", "<C-x>", '"+dd', { desc = "Ctrl+x：剪切当前行到系统剪贴板" })
keymap.set("n", "<C-c>", '"+yy', { desc = "Ctrl+c：复制当前行到系统剪贴板" })
keymap.set("n", "<C-a><C-c>", 'gg"+yG``', { desc = "Ctrl+a+Ctrl+c：复制全部到系统剪贴板" })
keymap.set("n", "<C-a><C-x>", 'gg"+dG', { desc = "Ctrl+a+Ctrl+x：剪切全部到系统剪贴板" })
keymap.set("n", "<C-v>", '"+P', { desc = "Ctrl+v：从系统剪贴板粘贴" })
keymap.set(
	"n",
	"<C-a><C-v>",
	'ggVG"_d"+P',
	{ desc = "Ctrl+a+Ctrl+v：全选→黑洞删除→粘贴系统剪贴板覆盖" }
)

-- ======================== 竞赛模板一键复制 ========================

-- 头文件搜索目录
local INCLUDE_DIR = "/usr/local/include/"

-- 常见 C/C++ 标准库头：单独 #include 时视为标准库，不参与内联
local STD_HEADERS = {}
for _, h in ipairs({
	"algorithm", "array", "atomic", "bitset", "cassert", "cctype",
	"cerrno", "cfenv", "cfloat", "chrono", "cinttypes", "climits",
	"clocale", "cmath", "complex", "condition_variable", "csetjmp",
	"csignal", "cstdarg", "cstdbool", "cstddef", "cstdint", "cstdio",
	"cstdlib", "cstring", "ctgmath", "ctime", "cuchar", "cwchar",
	"cwctype", "deque", "exception", "filesystem", "forward_list",
	"fstream", "functional", "future", "initializer_list", "iomanip",
	"ios", "iosfwd", "iostream", "istream", "iterator", "limits",
	"list", "locale", "map", "memory", "mutex", "new", "numeric",
	"optional", "ostream", "queue", "random", "ratio", "regex",
	"scoped_allocator", "set", "shared_mutex", "sstream", "stack",
	"stdexcept", "streambuf", "string", "string_view", "system_error",
	"thread", "tuple", "type_traits", "typeindex", "typeinfo",
	"unordered_map", "unordered_set", "utility", "valarray", "variant",
	"vector",
	"assert.h", "ctype.h", "errno.h", "float.h", "limits.h", "locale.h",
	"math.h", "setjmp.h", "signal.h", "stdarg.h", "stddef.h", "stdio.h",
	"stdlib.h", "string.h", "time.h", "wchar.h", "wctype.h", "complex.h",
	"fenv.h", "inttypes.h", "iso646.h", "stdbool.h", "stdint.h",
	"tgmath.h", "uchar.h",
}) do
	STD_HEADERS[h] = true
end

-- 判断 #include <Name> 是否为可内联的自定义头文件（位于 INCLUDE_DIR 且非标准库）
local function is_custom_include(name)
	if not name or name:match("/") or STD_HEADERS[name] then
		return false -- 含路径（bits/stdc++.h）或标准库头：不内联
	end
	local f = io.open(INCLUDE_DIR .. name, "r")
	if not f then
		return false -- 文件不存在：不内联
	end
	f:close()
	return true
end

-- Ctrl+a+Ctrl+i：解析 MACRO/TEMPLATE/INCLUDE/SOLVE 标签区域，内联后拼接完整竞赛代码
-- 无标签时按「顶部自定义头文件内联」模式：所有行保留，#include <自定义头> 展开为完整代码
local function copy_all_with_info()
	local ft = vim.bo.filetype
	if ft ~= "cpp" and ft ~= "c" then
		print("❌ 当前文件类型为 " .. ft .. "，仅支持 C/C++ 文件使用此快捷键喵～")
		return
	end

	local save_pos = vim.fn.getpos(".")
	local last_line = vim.fn.line("$")

	-- 已知标签名
	local labels = { "INCLUDE", "SOLVE" }

	-- 检测行是否为标签区域的开始/结束标记
	local function check_marker(line)
		if not line:match("^%s*/%*") then
			return nil
		end
		for _, label in ipairs(labels) do
			if line:match(label) then
				if line:match("/" .. label) then
					return label, "close"
				else
					return label, "open"
				end
			end
		end
		return nil
	end

	-- 文件是否包含标签注释；无标签时启用「顶部自定义头文件内联」模式
	local has_marker = false
	for i = 1, last_line do
		if check_marker(vim.fn.getline(i)) then
			has_marker = true
			break
		end
	end

	local result_parts = {}
	local include_pattern = '^%s*#include%s*[<"]([^>"]+)[>"]'
	local included_count = 0
	local state = "outside"
	local need_separator = false

	-- 带惰性空行的插入函数（区域有实际内容才插空行）
	local function emit(text)
		if need_separator and text ~= "" then
			table.insert(result_parts, "")
		end
		need_separator = false
		table.insert(result_parts, text)
	end

	-- 内联自定义头文件内容（不递归处理其内部 include）
	local function inline_header(name)
		local f = io.open(INCLUDE_DIR .. name, "r")
		local code = f and f:read("*all")
		if f then
			f:close()
		end
		if not code then
			return
		end
		for cline in code:gmatch("[^\r\n]+") do
			emit(cline)
		end
		need_separator = true -- 与后续内容之间添加空行
		included_count = included_count + 1
		print("✅ 已内联 <" .. name .. "> (" .. #code .. " 字节)")
	end

	for i = 1, last_line do
		local line = vim.fn.getline(i)
		local label, kind = check_marker(line)

		if label then
			if kind == "open" then
				if #result_parts > 0 then
					need_separator = true -- 标记需要空行，等实际内容写入时才插入
				end
				state = label
			else -- close
				state = "outside"
			end
		else
			if state == "SOLVE" then
				-- solve：原样复制
				emit(line)
			elseif state == "INCLUDE" or not has_marker then
				-- INCLUDE 区域 / 无标签文件：自定义头文件内联为完整代码，其余行原样保留
				local name = line:match(include_pattern)
				if name and is_custom_include(name) then
					inline_header(name)
				else
					emit(line)
				end
			end
			-- state == "outside"（仅存在于有标签文件）：标签区外的行丢弃
		end
	end

	local processed_str = table.concat(result_parts, "\n")

	vim.fn.setpos(".", save_pos)

	local full = processed_str
	vim.fn.setreg("+", full)
	vim.fn.setreg('"', full)
	local total = #full
	print("✅ 已复制 " .. included_count .. " 个模板 (" .. total .. " 字节)")
end

keymap.set(
	"n",
	"<C-a><C-i>",
	copy_all_with_info,
	{ desc = "Ctrl+a+Ctrl+i：内联模板引用并复制完整竞赛代码" }
)
