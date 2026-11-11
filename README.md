# dotfiles

chezmoi 管理的 Arch / CachyOS 配置：niri、fish/zsh、Neovim、kitty、fcitx5 等。

## 用法

```bash
chezmoi init --apply ihxnan
```

日常：

```bash
chezmoi diff          		   # see pending changes
chezmoi apply         		   # apply the changes
chezmoi add path/to/dotfile    # start tracking one
chezmoi re-add                 # update repository
```

## 结构

- `dot_*`、`private_*`：目标文件（`dot_` → `.`，`private_` → 0600）
- `.chezmoidata/packages.yaml`：包清单，按 pacman / archlinuxcn / shorin / AUR 分组
- `run_onchange_after_install-packages.sh.tmpl`：包清单变化时自动装包（需要 sudo）
- `run_onchange_after_symlink-hpp.sh.tmpl`：`~/Github/Template/**/*.hpp` → `/usr/local/include`

## ⚠️ 不可逆操作

`chezmoi apply` 不只是复制文件，它会：

1. **覆盖 `$HOME` 下的受管文件**。手改了受管文件却没`chezmoi add`，改动会被 source 版本覆盖且找不回来。
2. **`symlink.py -c`** —— 删除 `/usr/local/include` 下**所有**符号链接；同名普通文件会被直接 `unlink()` 删除。
