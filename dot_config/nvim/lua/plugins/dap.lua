return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"nvim-neotest/nvim-nio",
			"theHamsta/nvim-dap-virtual-text",
		},
		keys = {
			-- VSCode 风格
			{
				"<F5>",
				function()
					require("dap").continue()
				end,
				desc = "DAP：启动/继续",
			},
			{
				"<leader>dc",
				function()
					require("dap").continue()
				end,
				desc = "DAP：启动/继续",
			},
			{
				"<F9>",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "DAP：切换断点",
			},
			{
				"<leader>db",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "DAP：切换断点",
			},
			{
				"<F10>",
				function()
					require("dap").step_over()
				end,
				mode = { "n", "i" },
				desc = "DAP：步过",
			},
			{
				"<leader>dn",
				function()
					require("dap").step_over()
				end,
				desc = "DAP：步过",
			},
			{
				"<F11>",
				function()
					require("dap").step_into()
				end,
				mode = { "n", "i" },
				desc = "DAP：步入",
			},
			{
				"<leader>di",
				function()
					require("dap").step_into()
				end,
				desc = "DAP：步入",
			},
			{
				"<S-F11>",
				function()
					require("dap").step_out()
				end,
				desc = "DAP：步出",
			},
			{
				"<leader>do",
				function()
					require("dap").step_out()
				end,
				desc = "DAP：步出",
			},
			{
				"<S-F5>",
				function()
					require("dap").terminate()
				end,
				desc = "DAP：结束调试",
			},
			{
				"<leader>dt",
				function()
					require("dap").terminate()
				end,
				desc = "DAP：结束调试",
			},
			{
				"<leader>dB",
				function()
					require("dap").set_breakpoint(vim.fn.input("条件: "))
				end,
				desc = "DAP：条件断点",
			},
			{
				"<leader>du",
				function()
					require("dapui").toggle()
				end,
				desc = "DAP：开关调试面板",
			},
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			-- 断点/执行位置图标：比默认的单个 "B" 更醒目（图标 + 高亮 + 行号着色）
			vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#ff4b6e", bold = true })
			vim.api.nvim_set_hl(0, "DapBreakpointCondition", { fg = "#ffb03b", bold = true })
			vim.api.nvim_set_hl(0, "DapLogPoint", { fg = "#4fb6ff", bold = true })
			vim.api.nvim_set_hl(0, "DapBreakpointRejected", { fg = "#8a8a8a", bold = true })
			vim.api.nvim_set_hl(0, "DapStopped", { fg = "#3ddc84", bold = true })
			vim.api.nvim_set_hl(0, "DapStoppedLine", { link = "Visual" })

			vim.fn.sign_define("DapBreakpoint", {
				text = "●",
				texthl = "DapBreakpoint",
				numhl = "DapBreakpoint",
			})
			vim.fn.sign_define("DapBreakpointCondition", {
				text = "◆",
				texthl = "DapBreakpointCondition",
				numhl = "DapBreakpointCondition",
			})
			vim.fn.sign_define("DapLogPoint", {
				text = "◆",
				texthl = "DapLogPoint",
				numhl = "DapLogPoint",
			})
			vim.fn.sign_define("DapBreakpointRejected", {
				text = "●",
				texthl = "DapBreakpointRejected",
				numhl = "DapBreakpointRejected",
			})
			vim.fn.sign_define("DapStopped", {
				text = "▶",
				texthl = "DapStopped",
				linehl = "DapStoppedLine",
				numhl = "DapStopped",
			})

			-- 左栏（屏宽 32%）上下：scopes / watches
			-- 底部（屏高 25%）左中右：stacks / breakpoints / 程序终端
			dapui.setup({
				layouts = {
					{
						elements = {
							{ id = "scopes", size = 0.6 }, -- 变量作用域
							{ id = "watches", size = 0.4 }, -- 监视表达式
						},
						size = 0.32, -- 占屏宽 32%
						position = "left",
					},
					{
						elements = {
							{ id = "breakpoints", size = 0.5 }, -- 断点（左）
							{ id = "stacks", size = 0.5 }, -- 调用栈（右）
						},
						size = 0.25, -- 占屏高 25%
						position = "bottom",
					},
				},
			})
			require("nvim-dap-virtual-text").setup()

			-- codelldb 由 Mason 安装（见 lua/plugins/mason.lua 的 ensure_installed）
			dap.adapters.codelldb = {
				type = "server",
				port = "${port}",
				executable = {
					command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
					args = { "--port", "${port}" },
				},
			}

			-- 启动前编译当前文件：gcc/g++ -g -O0 -DIHXNAN，编译不过就不进入调试
			local function build()
				vim.cmd("write")
				local src = vim.fn.expand("%:p")
				local out = vim.fn.fnamemodify(src, ":r")
				local cc = (vim.bo.filetype == "c") and "gcc" or "g++"
				local msg = vim.fn.system({ cc, "-g", "-O0", "-DIHXNAN", src, "-o", out })
				if vim.v.shell_error ~= 0 then
					vim.fn.setqflist({}, " ", {
						title = "编译失败",
						lines = vim.split(msg, "\n", { trimempty = true }),
					})
					vim.cmd("copen")
					print("❌ [dap] 编译失败，已取消调试")
					return nil
				end
				return out
			end

			-- 程序在 nvim 内置终端里跑（codelldb 默认 internalConsole 没有 stdin），
			-- 终端开在底部 12 行并自动聚焦，scanf/cin 可以直接敲
			dap.defaults.fallback.focus_terminal = true
			-- 程序终端挤进底部那一行的最左边：terminal | breakpoints | stacks
			-- 注意：不能直接改 dapui 窗口的 buffer（dapui 的 force_buffers 会抢回去），
			-- 只能在它最左边的窗口上 split 出新窗口，让终端天然落在最左
			local dap_term_buf -- 记住自己建的终端 buffer，结束调试时好关掉
			dap.defaults.fallback.terminal_win_cmd = function()
				local bottom = {}
				for _, win in ipairs(vim.api.nvim_list_wins()) do
					local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
					if ft == "dapui_stacks" or ft == "dapui_breakpoints" then
						bottom[#bottom + 1] = { win = win, col = vim.api.nvim_win_get_position(win)[2] }
					end
				end
				if #bottom < 2 then
					-- dapui 没开时退回到普通底部横条
					vim.cmd("belowright 12new")
					return vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
				end
				table.sort(bottom, function(a, b)
					return a.col < b.col
				end)

				-- 在最左那块上向左 split，终端就落在最左
				local splitright = vim.o.splitright
				vim.o.splitright = false
				vim.api.nvim_set_current_win(bottom[1].win)
				vim.cmd("vsplit")
				vim.o.splitright = splitright
				local win = vim.api.nvim_get_current_win()
				local buf = vim.api.nvim_create_buf(false, true) -- 必须新建 buffer，不能共用 dapui 的
				vim.api.nvim_win_set_buf(win, buf)
				dap_term_buf = buf

				-- 三列平分
				local total = vim.api.nvim_win_get_width(win)
				for _, item in ipairs(bottom) do
					total = total + vim.api.nvim_win_get_width(item.win)
				end
				local each = math.max(15, math.floor(total / 3) - 1)
				for _, item in ipairs(bottom) do
					vim.api.nvim_win_set_width(item.win, each)
				end
				return buf, win
			end

			local cpp = {
				{
					name = "Launch (g++ -g -O0 -DIHXNAN)",
					type = "codelldb",
					request = "launch",
					program = build,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
					args = {},
					console = "integratedTerminal", -- 关键：程序输出/输入走真终端
				},
			}
			dap.configurations.cpp = cpp
			dap.configurations.c = cpp

			-- 开始调试时自动打开面板，结束时自动关闭
			local editor_win
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open({ reset = true }) -- reset：每次开始调试都按上面的尺寸重排
				editor_win = vim.api.nvim_get_current_win()
			end
			-- 断点停下时把焦点还给代码窗口，否则 nvim-dap 会把源码开在终端那块
			dap.listeners.before.event_stopped["dap_focus_editor"] = function()
				if editor_win and vim.api.nvim_win_is_valid(editor_win) then
					vim.api.nvim_set_current_win(editor_win)
				end
			end
			-- 结束调试时连程序终端一起关掉（dapui 只管自己的面板）
			local function close_terminal()
				local b = dap_term_buf
				dap_term_buf = nil
				if not (b and vim.api.nvim_buf_is_valid(b)) then
					return
				end
				-- buffer 名会被解析成绝对路径，所以按 buffer 号关窗口，不靠名字
				for _, win in ipairs(vim.api.nvim_list_wins()) do
					if vim.api.nvim_win_get_buf(win) == b then
						pcall(vim.api.nvim_win_close, win, true)
					end
				end
				pcall(vim.api.nvim_buf_delete, b, { force = true })
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				pcall(close_terminal)
				pcall(dapui.close)
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				pcall(close_terminal)
				pcall(dapui.close)
			end
			-- 兜底：程序一退出（含 terminate 杀掉进程）就关掉终端窗口，
			-- 不依赖 terminated/exited 事件是否到达
			vim.api.nvim_create_autocmd("TermClose", {
				callback = function(args)
					if not (dap_term_buf and args.buf == dap_term_buf) then
						return
					end
					local b = dap_term_buf
					dap_term_buf = nil
					vim.schedule(function()
						if not vim.api.nvim_buf_is_valid(b) then
							return
						end
						for _, win in ipairs(vim.api.nvim_list_wins()) do
							if vim.api.nvim_win_get_buf(win) == b then
								pcall(vim.api.nvim_win_close, win, true)
							end
						end
						pcall(vim.api.nvim_buf_delete, b, { force = true })
						pcall(dapui.close) -- 事件偶尔不到，面板也一起收掉
					end)
				end,
			})
		end,
	},
}
