# Neovim Config — Working Knowledge

Personal full-IDE Neovim config in Lua, plugin-managed by `lazy.nvim`; a dotfiles
repo, not a build project. Leader = space, local leader = `\`. Targets Neovim 0.11+.

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
| `lua/config/test.py`, `.reasonix/` | Scratch — not loaded by Neovim |

## Commands

- No build/test/lint — pure config. Run with `nvim .`.
- Plugin UI `:Lazy`; LSP/tool installer `:Mason`.
- Format a file inside nvim with `<Tab>` or `<leader>f` (stylua/conform).

## Architecture

- **Config layer** (`lua/config/`, loaded at startup):
  - `lazy.lua` — lazy.nvim bootstrap + `{ import = "plugins" }`.
  - `options.lua` — global vim options; `BufReadPost` restore-cursor autocmd; NeoTree transparent highlights; `autochdir`; indent-based fold.
  - `keymaps.lua` — all mappings + code-run functions; requires `clipboard.lua`.
  - `clipboard.lua` — exports `copy_all_with_info` (inliner) plus `setup_system_clipboard()` / `setup_template_copy()`; `keymaps.lua` calls both, `vscode.lua` only the latter.
  - `vscode.lua` — VSCode 分支：精简 options + 转发到 VSCode 命令的键映射（`vim.fn.VSCodeNotify`）；运行快捷键走 VSCode tasks（`~/.config/Code/User/tasks.json`）。
- **Plugin layer** (`lua/plugins/`) — 29 spec files, mostly lazy-loaded by `event`/`ft`/`keys`.
- **LSP layer** (`lua/plugins/mason.lua`) — 7 servers via `vim.lsp.config` (0.11+ API): `lua_ls`, `ts_ls`, `html`, `cssls`, `jsonls`, `pyright`, `clangd`. Writes `~/.config/clangd/config.yaml` with `-std=gnu++20` fallback. Mason auto-installs: black, isort, ruff, clang-format, stylua, shfmt, prettierd, taplo, cmakelang.
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

## Notes

- `lua/config/REASONIX.md` is unrelated Reasonix memory (C++ competitive-programming template) — not loaded by Neovim.
- `lua/config/test.py` and `.reasonix/` are scratch files; not part of the config.
- **VSCode 适配（vscode-neovim）**: `vim.g.vscode` 分支 → `lua/config/vscode.lua`（不加载任何插件）；`jk` 退出插入由 `~/.config/Code/User/settings.json` 的 `vscode-neovim.compositeKeys` 提供；窗口导航 `<C-h/j/k/l>` 由 `keybindings.json` 的 `workbench.action.navigate*` 提供；运行任务在 `~/.config/Code/User/tasks.json`（label 与 `vscode.lua` 的 `TASKS` 表一一对应）。VSCode 配置改动前已备份为 `~/.config/Code/User/*.bak-*`。另：`<C-a><C-i>`（内联模板并复制）在 VSCode 分支也可用（`clipboard.lua` 的 `setup_template_copy()`），其余剪贴板映射保留 VSCode 原生行为。运行键 `dp` 走 VSCode 集成终端（预填 `cd '<文件目录>' && dp`，不自动回车），`rc/rd/rl/rp/ru` 走 `tasks.json` —— 均因 vscode-neovim 不支持 nvim 内置 `:terminal`。
