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
keymap.set("n", "<C-x>", '"+dd',          { desc = "Ctrl+x：剪切当前行到系统剪贴板" })
keymap.set("n", "<C-c>", '"+yy',          { desc = "Ctrl+c：复制当前行到系统剪贴板" })
keymap.set("n", "<C-a><C-c>", 'gg"+yG``', { desc = "Ctrl+a+Ctrl+c：复制全部到系统剪贴板" })
keymap.set("n", "<C-a><C-x>", 'gg"+dG',   { desc = "Ctrl+a+Ctrl+x：剪切全部到系统剪贴板" })
keymap.set("n", "<C-v>", '"+P',           { desc = "Ctrl+v：从系统剪贴板粘贴" })
keymap.set("n", "<C-a><C-v>", 'ggVG"_d"+P', { desc = "Ctrl+a+Ctrl+v：全选→黑洞删除→粘贴系统剪贴板覆盖" })

-- ======================== 竞赛模板一键复制 ========================

-- 头文件搜索目录
local INCLUDE_DIR   = "/usr/local/include/"

-- Ctrl+a+Ctrl+i：解析 MACRO/TEMPLATE/INCLUDE/SOLVE 标签区域，内联后拼接完整竞赛代码
local function copy_all_with_info()
  local ft = vim.bo.filetype
  if ft ~= "cpp" and ft ~= "c" then
    print("❌ 当前文件类型为 " .. ft .. "，仅支持 C/C++ 文件使用此快捷键喵～")
    return
  end

  local save_pos = vim.fn.getpos('.')
  local last_line = vim.fn.line('$')

  -- 已知标签名
  local labels = { "INCLUDE", "SOLVE" }

  -- 检测行是否为标签区域的开始/结束标记
  local function check_marker(line)
    if not line:match("^%s*/%*") then return nil end
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

  local result_parts = {}
  local include_pattern = '^%s*#include%s*[<"]([^>"]+)[>"]'
  local included_count = 0
  local state = "outside"
  local need_separator = false

  -- 带惰性空行的插入函数（区域有实际内容才插空行）
  local function emit(text)
    if need_separator then
      table.insert(result_parts, "")
      need_separator = false
    end
    table.insert(result_parts, text)
  end

  for i = 1, last_line do
    local line = vim.fn.getline(i)
    local label, kind = check_marker(line)

    if label then
      if kind == "open" then
        if #result_parts > 0 then
          need_separator = true  -- 标记需要空行，等实际内容写入时才插入
        end
        state = label
      else  -- close
        state = "outside"
      end
    else
      if state == "outside" then
        -- 标签区外的行丢弃，不保留
      elseif state == "SOLVE" then
        -- solve：原样复制
        emit(line)
      elseif state == "INCLUDE" then
        -- include：将 #include <Name> 内联为 /usr/local/include/<Name> 的代码
        local name = line:match(include_pattern)
        if name then
          local filepath = INCLUDE_DIR .. name
          local f = io.open(filepath, "r")
          if f then
            local code = f:read("*all")
            f:close()
            -- 直接插入代码，不加注释标记
            for cline in code:gmatch("[^\r\n]+") do
              emit(cline)
            end
            need_separator = true  -- 不同内联模板之间添加空行
            included_count = included_count + 1
            print("✅ 已内联 <" .. name .. "> (" .. #code .. " 字节)")
          else
            -- 文件不存在，保留原始 include 行
            emit(line)
          end
        else
          emit(line)
        end
      end
    end
  end

  local processed_str = table.concat(result_parts, "\n")

  vim.fn.setpos('.', save_pos)

  local full = processed_str
  vim.fn.setreg('+', full)
  vim.fn.setreg('"', full)
  local total = #full
  print("✅ 已复制 " .. included_count .. " 个模板 (" .. total .. " 字节)")
end

keymap.set("n", "<C-a><C-i>", copy_all_with_info,
    { desc = "Ctrl+a+Ctrl+i：内联模板引用并复制完整竞赛代码" })
