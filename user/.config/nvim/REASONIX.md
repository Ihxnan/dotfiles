# Neovim Config — Working Knowledge

## Stack

- **Neovim** (Lua) — full IDE config using `lazy.nvim` as plugin manager
- **lazy.nvim** — plugin loader; entry point `init.lua` imports `config.lazy`
- **nvim-treesitter** — syntax tree parsing (fold, highlight, autotag)
- **mason.nvim** — LSP/DAP/linter installer gateway
- **blink.cmp** — autocompletion engine
- **tokyonight** — colorscheme

## Layout

| Path | Purpose |
|------|---------|
| `init.lua` | Entry point — bootstraps lazy.nvim, requires `config/` modules |
| `lua/config/` | Core settings: `options.lua`, `keymaps.lua`, `clipboard.lua`, `lazy.lua` |
| `lua/plugins/` | One `.lua` file per plugin — auto-discovered by lazy.nvim's `{ import = "plugins" }` |
| `after/ftplugin/` | Filetype overrides — currently only `cpp.lua` (disables Treesitter indent, sets C indent) |
| `snippets/` | VS Code–style snippets (cmake, cpp, html, python) |
| `lazy-lock.json` | Lockfile pinning plugin commits |

## Conventions

- **Leader key** = space; local leader = `\`
- **Insert-mode escape** = `jk` across insert/terminal/visual modes
- **Window navigation**: `<C-h/j/k/l>` works in normal, insert, and terminal modes
- **Code run shortcuts** (`rc`/`ru`/`rd`/`rp`) open a split-terminal for output
- **Clipboard**: `"+` register for system clipboard; custom `Ctrl+x/c/v` mappings
- **ASCII art banners** at the top of most config files (aesthetic convention)
- **C++ indentation**: `after/ftplugin/cpp.lua` disables Treesitter-based indent for C/C++, falls back to `cindent` with custom `cinoptions`

## Watch out for

- **No package.json or build scripts** — this is a pure Neovim config, not a node/Rust/Python project. Plugin pinning lives in `lazy-lock.json`.
- **`lua/config/REASONIX.md`** is unrelated Reasonix project memory (C++ competitive programming templates) — not the REASONIX.md at the project root.
- **`musicode.lua.back`** is a disabled plugin spec (`.back` extension) — not loaded.
