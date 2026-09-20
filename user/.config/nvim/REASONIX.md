# Neovim Config — Working Knowledge

Personal full-IDE Neovim config in Lua, plugin-managed by `lazy.nvim`; a dotfiles
repo, not a build project. Leader = space, local leader = `\`. Targets Neovim 0.11+
(当前 runtime 0.12.5)。本目录是 dotfiles 仓库 `/home/ihxnan/Github/dotfiles` 内的 `user/.config/nvim`
（`~/.config/nvim` 是指向它的 symlink），因此改动会直接进入该仓库；git 操作在仓库根执行。

## Project

- Entry point `init.lua`: `if vim.g.vscode then require("config.vscode") else require("config.lazy"), config.options, config.keymaps end` — VSCode(vscode-neovim) 与普通 Neovim 走不同分支。
- `lua/config/lazy.lua` bootstraps lazy.nvim and auto-imports every `lua/plugins/*.lua` spec.

## Stack

- **lazy.nvim** — plugin loader (auto-discovers `lua/plugins/`); `lazy-lock.json` pins commits.
- **nvim-treesitter** + **nvim-ts-autotag** — syntax trees (fold, highlight, autotag).
- **mason.nvim** + **mason-tool-installer.nvim** + **nvim-lspconfig** — LSP/format tooling gateway.
- **blink.cmp** — completion (v1.x, preset `none`; accept with `<C-y>`).
- **tokyonight** (transparent), **alpha-nvim** (dashboard; disables snacks dashboard), **lualine** (musicode + macro), **bufferline**, **which-key**.
- **neo-tree** v3.x (replaces netrw), **telescope** (transparent), **flash**, **Comment.nvim**, **nvim-autopairs**, **indent-blankline** (ibl), **mini.icons**, **noice** + **nui**, **toggleterm**, **suda** (sudo write), **vim-fetch**, **vim-table-mode**.
- Markdown: **render-markdown**, **live-preview** (chromium), **image.nvim** (kitty backend).
- **conform.nvim** (formatting), **gitsigns**, **opencode.nvim**.

## Layout

| Path | Purpose |
|------|---------|
| `init.lua` | Entry point — requires `config.lazy`, `config.options`, `config.keymaps` |
| `lua/config/` | Core: `lazy.lua`, `options.lua`, `keymaps.lua`, `clipboard.lua`, `vscode.lua` |
| `lua/config/vscode.lua` | vscode-neovim 精简配置，仅 `vim.g.vscode` 为真时加载（不加载任何插件） |
| `lua/plugins/` | One `.lua` file per plugin spec (29 files), discovered by `{ import = "plugins" }` |
| `after/ftplugin/cpp.lua` | C++ overrides — disables Treesitter indent, Allman/Microsoft `cinoptions` |
| `snippets/` | VS Code–style snippets (cmake, cpp, html, python) |
| `lazy-lock.json` | Lockfile pinning plugin commits |
| `reasonix.toml` | Reasonix 权限/沙箱配置（见 Notes） |
| `lua/config/test.py`, `.reasonix/` | Scratch — not loaded by Neovim |

## Commands

- No build/test/lint — pure config. Run with `nvim .`; 插件 UI `:Lazy`，LSP/tool 安装 `:Mason`，健康检查 `:checkhealth`。
- Lua 语法校验（不加载插件，改完 config 后跑；输出 `all lua files compile OK`）：
  `nvim --headless -u NONE -c 'lua for _,f in ipairs(vim.fn.glob("**/*.lua",false,true)) do local ok,e=loadfile(f); if not ok then error(f..": "..tostring(e)) end end print("all lua files compile OK")' -c 'qa!'`
- Format inside nvim with `<Tab>` or `<leader>f` (conform, `lsp_fallback = true`); CLI 可用 `~/.local/share/nvim/mason/bin/stylua <file>`（仓库无 `.stylua.toml`，stylua 无独立安装，由 Mason 提供）。
- 副作用注意：正常启动 nvim 会幂等重写 clangd 配置（Linux `~/.config/clangd/config.yaml`；Windows `%LOCALAPPDATA%\clangd\config.yaml`，见 `lua/plugins/mason.lua`）。

## Architecture

- **Config layer** (`lua/config/`, loaded at startup):
  - `lazy.lua` — lazy.nvim bootstrap + `{ import = "plugins" }`；设置 `mapleader`/`maplocalleader`。
  - `options.lua` — global vim options; `BufReadPost` restore-cursor autocmd; NeoTree transparent highlights; `autochdir`; indent-based fold.
  - `keymaps.lua` — all mappings + code-run functions; requires `clipboard.lua`.
  - `clipboard.lua` — exports `copy_all_with_info` (inliner) plus `setup_system_clipboard()` / `setup_template_copy()`; `keymaps.lua` calls both, `vscode.lua` only the latter.
  - `vscode.lua` — VSCode 分支：精简 options + 转发到 VSCode 命令的键映射（`vim.fn.VSCodeNotify`）；运行快捷键走 VSCode tasks（`~/.config/Code/User/tasks.json`）。
- **Plugin layer** (`lua/plugins/`) — 29 spec files, mostly lazy-loaded by `event`/`ft`/`keys`.
- **LSP layer** (`lua/plugins/mason.lua`) — 7 servers via `vim.lsp.config` + `vim.lsp.enable` (0.11+ API): `lua_ls`, `ts_ls`, `html`, `cssls`, `jsonls`, `pyright`, `clangd`（cmd 指向 `~/.local/share/nvim/mason/bin/`）。Writes `~/.config/clangd/config.yaml` with `-std=gnu++20` fallback. Mason auto-installs (via `mason-tool-installer`): black, isort, ruff, clang-format, clangd, lua-language-server, stylua, shfmt, prettierd, typescript-language-server, html-lsp, css-lsp, json-lsp, htmlhint, cmakelang, taplo.
- **Filetype layer** (`after/ftplugin/cpp.lua`) — Treesitter indent off, `cindent` + Allman `cinoptions`.

## Conventions

- **Escape**: `jk` in insert/terminal modes; `ii` in visual mode.
- **Windows**: nav `<C-h/j/k/l>` in n/i/t modes; `<leader>wv` horizontal split, `<leader>wh` vertical split; move `gw{h,j,k,l}`; close `gwd`/`gwo`; resize `<M-=>`/`<M-->`.
- **Buffers**: `H`/`L` save-then-cycle tabs (bufferline); `gbh`/`gbl` prev/next; `gbd` delete; `gbo` close others.
- **Run shortcuts**: `rc` = clipboard→`/tmp/data` + copy full code + run (no macro); `rl` local debug (`-DIHXNAN`); `rd` run with data (`-DIHXNAN`); `rp` paste+run; `ru` CUDA/C/C++ (`nvcc -arch=sm_89`); `dp` dp tool; `cp` paste clipboard→`/tmp/data`; `cd` open `/tmp/data`; `ct` open `~/Github/Template`. C/C++ builds with `g++ -O2 -fsanitize=address,undefined,leak` into a `vsplit` terminal.
- **HTML preview**: `gmp` start / `gmc` close (LivePreview).
- **LSP**: `<leader>rn` rename, `<leader>ca` action, `gr` references, `gI` implementation, `gT` type def (Python only), `<leader>]`/`<leader>[` diagnostic jump, `<leader>dl`/`<leader>dh` diagnostics.
- **Format is MANUAL** — auto-format on save is disabled in `lua/plugins/formatter.lua`; use `<Tab>` or `<leader>f`.
- **Clipboard**: `unnamedplus`; `"+` register. Normal `<C-x>`/`<C-c>`/`<C-v>`, `<C-a><C-c>` copy all, `<C-a><C-i>` inline template + copy; visual `<C-c>` copies.
- **Terminals/tools**: `<leader>t` vertical fish terminal, `<leader>s` horizontal, `<leader>i` reasonix, `<A-t>` toggleterm, `Ctrl+g` lazygit tab, `F5` open dir in VS Code.
- **Search/nav**: `<leader>ff` telescope files; `n`/`N` auto-center (`nzz`/`Nzz`); `<leader>nh` clear highlight; `j`/`k` = `gj`/`gk`; `J`/`K` jump 5 lines.
- **Files/git**: `<leader>e` toggle neo-tree; gitsigns for gutter/blame/hunks.
- **Save**: `<C-S>` normal mode, `<C-s>` insert mode.
- **Style**: ASCII-art banner comment at top of each config file; comments in Chinese; transparent backgrounds (tokyonight/neo-tree/telescope); `tabstop=shiftwidth=softtabstop=4` + `expandtab`.

## Windows 适配（pwsh 7 + MinGW-w64）

同一份配置用**运行时条件分支**支持 Windows：涉平台的文件都以 `local is_win = vim.fn.has("win32") == 1`
判定，Windows 逻辑放在 `if is_win then ... return end` 守卫内，**Linux 分支的原有代码与字符串一律逐字保留**
（用 `/tmp` 快照 diff 逐条验证，方法见本节末尾）。

- `lua/config/keymaps.lua` — Windows 下编译/运行改走 `pwsh -EncodedCommand`（base64/UTF-16LE，规避多层引号转义）+ MinGW `g++`；`PWSH` 在无 pwsh 时回退 `powershell`；产物 `a.exe`；数据重定向用 `Get-Content -Raw <data> | .\a.exe`（PowerShell 没有 `<`）；`WIN_CPP_FLAGS` 刻意不含 `-fsanitize`（MinGW-w64 不带 libasan/libubsan）。
- `lua/config/options.lua` — 仅 win32：`shell=pwsh`（回退 `powershell`）+ `shellcmdflag=-NoLogo -NoProfile -Command`。
- `lua/config/clipboard.lua` — `IHXNAN_INCLUDE_DIR` / `IHXNAN_TEMPLATE_PY` 环境变量优先；Windows 默认 MinGW include 与常见 Python 安装位置。
- `lua/config/vscode.lua` — `DATA` 同下；`dp` 用 `Set-Location -LiteralPath`。
- `lua/plugins/mason.lua` — LSP cmd 自动补 `.cmd`/`.exe`；clangd 配置写 `%LOCALAPPDATA%\clangd\config.yaml`；pyright 加 `~/.virtualenvs/*`。
- `lua/plugins/{image,live-preview,suda,nvim-treesitter}.lua` — backend `sixel`、browser `default`、`suda_smart_edit=false`、Python 走 `python` / `python -m pytest`。
- 数据文件：Linux 仍是 `/tmp/data`；Windows 用 `stdpath("data").."/data"`（即 `%LOCALAPPDATA%\nvim-data\data`）。

Windows 侧需手动补齐（不在本仓库）：
- VSCode：`vscode-neovim.neovimExecutablePaths.win32` 指向 nvim.exe；把 `user/vscode/vscode.tasks.windows.json` 复制为 `%APPDATA%\Code\User\tasks.json`（label 与 `vscode.lua` 的 `TASKS` 表一一对应）。
- 若设过 `XDG_DATA_HOME`，tasks 模板里写死的数据路径要按 `:lua= vim.fn.stdpath("data")` 对齐。
- Windows 版 tasks 模板硬编码 `pwsh.exe`（只有 PowerShell 5.1 的机器上任务不可用，而 nvim 内快捷键仍可回退）。

在 Linux 上验证 Windows 分支（不需要 Windows 机器）：
1. `cp -rL ~/.config/nvim/. /tmp/winsmoke/nvim/` —— **必须 `-L`**：`~/.config/nvim` 是 symlink，用 `cp -r` 会保留链接、让后续 `sed` 改到仓库源码（踩过一次）。
2. 副本内 `sed -i 's/vim\.fn\.has("win32") == 1/true/g'`，再断言副本不是 symlink。
3. `nvim --headless -u NONE --cmd 'set rtp^=/tmp/winsmoke/nvim'` —— **必须 `^=` 前置**；用 `+=` 仍会加载仓库文件，冒烟会假通过。
4. Windows 分支核对：stub `vim.cmd` 捕获命令 + `vim.base64.decode` 解 `-EncodedCommand` 还原 pwsh 脚本；Linux 回归：`dofile` 一个 dump 全部 `nvim_get_keymap`/options 的快照脚本，与改动前快照 `diff`。

## Notes

- `lua/config/REASONIX.md` is unrelated Reasonix memory（C++ 竞赛模板；同目录 `test.py` 是依赖 `ihxnan` 包的临时脚本，可随时删除）— not loaded by Neovim.
- `.reasonix/truncated-results/`（根目录与 `lua/plugins/` 下各一份）是 agent 会话产物，可忽略/删除。
- `reasonix.toml` — `[permissions] allow = []`，`[sandbox] allow_write = ["${HOME}/.config/Code/User"]`。
- `options.lua` 设 `foldmethod='indent'`，因此同一文件里的 `foldexpr='nvim_treesitter#foldexpr()'` 实际不生效（折叠行为本质是 indent 折叠）。
- **VSCode 适配（vscode-neovim；Windows 侧见上一节）**: `vim.g.vscode` 分支 → `lua/config/vscode.lua`（不加载任何插件）；`jk` 退出插入由 `~/.config/Code/User/settings.json` 的 `vscode-neovim.compositeKeys` 提供；窗口导航 `<C-h/j/k/l>` 由 `keybindings.json` 的 `workbench.action.navigate*` 提供；运行任务在 `~/.config/Code/User/tasks.json`，其 6 个 label（`nvim: run cpp (data)` 等）与 `vscode.lua` 的 `TASKS` 表一一对应。VSCode 配置改动前已备份为 `~/.config/Code/User/*.bak-*`。另：`<C-a><C-i>`（内联模板并复制）在 VSCode 分支也可用（`clipboard.lua` 的 `setup_template_copy()`），其余剪贴板映射保留 VSCode 原生行为。运行键 `dp` 走 VSCode 集成终端（预填 `cd '<文件目录>' && dp`，不自动回车），`rc/rd/rl/rp/ru` 走 `tasks.json` —— 均因 vscode-neovim 不支持 nvim 内置 `:terminal`。
