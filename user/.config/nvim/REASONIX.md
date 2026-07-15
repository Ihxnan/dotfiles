# Neovim Config — Working Knowledge

## Project

Full IDE Neovim config (Lua) using `lazy.nvim` as plugin manager. Entry point:
`init.lua` → `lua/config/lazy.lua` (lazy.nvim bootstrap), `lua/config/options.lua`,
`lua/config/keymaps.lua`.

## Stack

- **lazy.nvim** — plugin loader; auto-discovers `lua/plugins/*.lua`
- **nvim-treesitter** — syntax tree parsing (fold, highlight, autotag)
- **mason.nvim** + **mason-tool-installer.nvim** — LSP/DAP/linter installer gateway
- **blink.cmp** — autocompletion engine (v1.x, preset `none`; accept with `<C-y>`)
- **tokyonight** — colorscheme (night style, transparent background)
- **alpha-nvim** — startup dashboard (disables snacks.nvim's dashboard)
- **neo-tree.nvim** (v3.x) — file explorer (replaces netrw; `<leader>e`)
- **lualine.nvim** — statusline (tokyonight theme, musicode integration, macro recording)
- **bufferline.nvim** — tab-line buffer management (cycle with `H`/`L`)
- **conform.nvim** — auto-format on save (`BufWritePre`); `<Tab>` or `<leader>f` to format
- **gitsigns.nvim** — git gutter signs + blame/hunk operations
- **telescope.nvim** — fuzzy finder (`<leader>ff`), transparent background

## Layout

| Path | Purpose |
|------|---------|
| `init.lua` | Entry point — requires `config.lazy`, `config.options`, `config.keymaps` |
| `lua/config/` | Core settings: `lazy.lua`, `options.lua`, `keymaps.lua`, `clipboard.lua` |
| `lua/plugins/` | One `.lua` file per plugin — discovered by lazy.nvim's `{ import = "plugins" }` |
| `after/ftplugin/` | Filetype overrides — currently `cpp.lua` (disables Treesitter indent, sets C indent) |
| `snippets/` | VS Code–style snippets (cmake, cpp, html, python) |
| `lazy-lock.json` | Lockfile pinning plugin commits |

## Commands

Neovim config — no build/run/test commands. Open with `nvim .`.

## Architecture

- **Config layer** (`lua/config/`): 4 files loaded at startup:
  - `lazy.lua` — bootstraps lazy.nvim and imports `lua/plugins/`
  - `options.lua` — global vim options (relativenumber, tabstop=4, clipboard, fold, etc.)
  - `keymaps.lua` — all normal/insert/visual/terminal keymaps; requires `clipboard.lua`
  - `clipboard.lua` — system clipboard mappings + C++ competition template inlining tool
- **Plugin layer** (`lua/plugins/`): 27 plugin specs, each lazy-loaded when possible
- **LSP layer** (`lua/plugins/mason.lua`): 7 servers configured via `vim.lsp.config` (0.11+ API):
  - `lua_ls`, `ts_ls`, `html`, `cssls`, `jsonls`, `pyright`, `clangd`
  - Mason auto-installs formatters/linters: black, isort, ruff, clang-format, stylua, shfmt, prettierd, taplo, cmakelang

## Conventions

- **Leader key** = space; local leader = `\`
- **Insert-mode escape** = `jk` (insert/terminal/visual modes)
- **Window navigation**: `<C-h/j/k/l>` works in normal, insert, and terminal modes
- **Window management**: `<leader>wv` (hsplit), `<leader>wh` (vsplit), `gw{h,j,k,l}` (relocate), `gwd`/`gwo` (close), `<M-=>`/`<M-->` (resize)
- **Buffer management**: `H`/`L` cycle tabs (bufferline), `gb{h,l,d,o}` for prev/next/delete/close-others
- **Code run shortcuts**: `rc` (run), `rd` (run with data), `rp` (paste+run), `ru` (CUDA/C/C++), `dp` (dp tool), `cd` (open data file), `cp` (paste to data), `ct` (open template)
- **LSP shortcuts**: `<leader>rn` rename, `<leader>ca` code action, `gr` references, `gI` implementation, `gT` type def (Python), `<leader>]`/`<leader>[` diagnostic jump
- **Format**: `<Tab>` or `<leader>f` to format; auto-format on save via conform.nvim
- **Clipboard**: `"+` register for system clipboard; `<C-x/c/v>` in normal mode; `<C-c>` in visual mode copies to `"+`
- **Search**: `<leader>ff` telescope find files; `n`/`N` with auto-center (`nzz`/`Nzz`); `<leader>nh` clear highlight
- **Git**: `<leader>e` toggle neotree; `Ctrl+g` opens lazygit in a tab; gitsigns for gutter blame/hunks
- **C++ indentation**: `after/ftplugin/cpp.lua` disables Treesitter indent, uses `cindent` with Allman-style `cinoptions`
- **ASCII art banners** at the top of most config files (aesthetic convention)
- **Transparent backgrounds**: neo-tree, telescope, tokyonight all set transparent
- **File navigation**: `j`/`k` wrap-to-visual-line (`gj`/`gk`); `J`/`K` jump 5 lines

## Notes

- No package.json or build scripts — pure Neovim config, not a node/Rust/Python project.
- `lua/config/REASONIX.md` is unrelated Reasonix project memory (C++ competitive programming templates) — not loaded by Neovim.
