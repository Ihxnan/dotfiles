# dotfiles

chezmoi 管理的 Arch / CachyOS 配置，主要面向 Wayland 桌面：

- **桌面**：niri、dms / dux-shell、fuzzel、satty、matugen、xsettingsd
- **终端**：kitty、alacritty、fish / zsh / bash、starship
- **编辑器**：Neovim、Vim
- **工具**：yazi、btop、cava、fcitx5、lazygit
- **AI 技能**：`~/.agents` 下的 agent skills

## 前置要求

- Arch Linux 或 CachyOS
- `git`、`chezmoi`、`sudo`
- age 私钥放在 `~/.config/chezmoi/key.txt`（用于解密 SSH 私钥和 fish secret）
- 仓库固定在 `~/Github/chezmoi`（`.chezmoi.toml.tmpl` 中的 `sourceDir` 已写死该路径）
- 首次安装需要联网；安装 AUR 包时会按需安装 `paru`

## 用法

首次安装：

```bash
chezmoi init --apply ihxnan
```

日常操作：

```bash
chezmoi status                  # 查看哪些受管文件有变化
chezmoi diff                    # 查看工作区与 source 的差异
chezmoi apply -n -v             # 预演 apply，不实际写入
chezmoi apply                   # 应用配置
chezmoi add ~/.config/foo       # 开始跟踪一个文件
chezmoi re-add                  # 把工作区改动写回 source
chezmoi edit ~/.config/foo      # 直接编辑 source 中的受管文件
chezmoi cd                      # 进入 source 目录
chezmoi update                  # git pull 后自动 apply
```

> `chezmoi apply` 会执行 `run_onchange_*` 脚本，可能安装软件包、修改 `/etc/pacman.conf`、启用服务或要求 sudo。执行前建议先跑 `chezmoi diff` 或 `chezmoi apply -n -v`。

## 结构

chezmoi 命名规则：

- `dot_*` → `~/.`，例如 `dot_bashrc` → `~/.bashrc`
- `private_*` → 权限 `0600`
- `executable_*` → 添加可执行权限
- `encrypted_*` → 使用 age 加密
- `*.tmpl` → Go 模板，apply 时渲染

主要文件：

```text
.
├── .chezmoi.toml.tmpl                              # age 加密、sourceDir、merge 工具
├── .chezmoiignore.tmpl                             # 忽略规则与无密钥时的降级处理
├── .chezmoidata/packages.yaml                      # 包清单、服务、用户组
├── run_onchange_after_install-packages.sh.tmpl     # 装包与系统初始化
├── run_onchange_after_symlink-hpp.sh.tmpl          # 刷新 /usr/local/include 头文件链接
├── dot_agents/                                     # agent skills，安装到 ~/.agents
├── dot_config/                                     # 各应用配置
├── dot_local/bin/                                  # 个人命令行工具
├── private_dot_ssh/                                # SSH 配置、公钥、加密私钥
└── dot_bashrc / dot_zshrc / dot_vimrc / ...        # 各 shell 与编辑器配置
```

### 配置与脚本

- `.chezmoi.toml.tmpl`
  - `encryption = "age"`，身份文件为 `~/.config/chezmoi/key.txt`
  - `sourceDir` 固定为 `~/Github/chezmoi`
  - merge 冲突时使用 `nvim -d`
- `.chezmoiignore.tmpl`
  - 忽略 `.git` 与 `README.md`
  - 未找到 age 私钥时，跳过 `~/.ssh/id_ed25519` 和 `~/.config/fish/conf.d/secret.fish`，避免 apply 整体失败
- `.chezmoidata/packages.yaml`
  - 按 `pacman` / `archlinuxcn` / `shorin` / `aur` 分组
  - 同时声明 `system_services`、`user_services`、`user_groups`
- `run_onchange_after_install-packages.sh.tmpl`
  - 按需添加 `archlinuxcn` 与 `shorin-arch` 仓库
  - 导入并本地签名对应的 GPG key
  - 执行 `pacman -Syu`，安装清单中的软件包
  - 启用系统/用户服务，并把当前用户加入 `libvirt` 组
- `run_onchange_after_symlink-hpp.sh.tmpl`
  - 监听 `~/Github/Template` 下 `.hpp` 与 `symlink.py` 的校验和
  - 变化时执行 `sudo python3 ~/Github/Template/symlink.py -c -v`
  - 找不到 `symlink.py` 时直接跳过

### 应用配置

- `dot_config/niri/`：niri 主配置、dms 快捷键、脚本
- `dot_config/niri/scripts/`：`niri-binds`、`niri-force-kill-window`、`niri-pick`、`niri_tilemod.py`、`screenshot-sound.sh`
- `dot_config/nvim/`：Neovim 配置，插件定义在 `lua/plugins/`
- `dot_config/yazi/`、`dot_config/btop/`、`dot_config/cava/`：TUI 工具配置
- `dot_config/fish/`、`dot_config/fcitx5/`、`dot_config/kitty/`、`dot_config/alacritty/`：shell、输入法与终端
- `dot_config/scripts/`：`matugen-update.sh`、`qute-reload.sh` 等辅助脚本
- `dot_local/bin/`：`dp`、`u`、`wp`、`quicksave`、`wf-recorder-menu` 等个人命令

### niri 自动平铺

`dot_config/niri/config.kdl` 通过 `spawn-sh-at-startup` 启动 `niri_tilemod.py`：

- 工作区只有一个窗口时自动铺满
- 打开第二个窗口时左右平分
- 第三个及之后的窗口并入当前聚焦列，上下平分
- 跨工作区移动窗口时也按同样规则重新排列

### agent skills

`dot_agents/` 会安装到 `~/.agents`，包含：

- `citation-management`
- `find-skills`
- `frontend-design`
- `git-advanced-workflows`
- `git-commit`
- `literature-review`
- `markitdown`
- `scientific-visualization`
- `scientific-writing`
- `statistical-analysis`

`dot_agents/dot_skill-lock.json` 记录每个技能的来源仓库、commit 与校验信息。

## 密钥与加密

- age recipient 写在 `.chezmoi.toml.tmpl`，私钥不应提交到仓库
- 受 age 加密的文件：
  - `private_dot_ssh/encrypted_private_id_ed25519.age` → `~/.ssh/id_ed25519`
  - `dot_config/fish/conf.d/encrypted_private_secret.fish.age` → `~/.config/fish/conf.d/secret.fish`
- 没有 `~/.config/chezmoi/key.txt` 时，上述文件会被忽略并给出警告；配置好私钥后重新 `chezmoi apply` 即可

## 维护

- 新增软件包：编辑 `.chezmoidata/packages.yaml`，下次 apply 时 `run_onchange` 会自动重装
- 新增 dotfile：先用 `chezmoi add <path>`，再 `chezmoi cd` 提交
- 修改受管文件：改完工作区文件后执行 `chezmoi re-add`，或直接 `chezmoi edit`
- 更新 agent skills：更新 `dot_agents/` 与 `dot_skill-lock.json` 后重新 apply

## ⚠️ 不可逆操作

`chezmoi apply` 不只是复制文件，它会：

1. **覆盖 `$HOME` 下的受管文件**。手改了受管文件却没 `chezmoi add`，改动会被 source 版本覆盖且找不回来。
2. **`symlink.py -c`** —— 删除 `/usr/local/include` 下**所有**符号链接；同名普通文件会被直接 `unlink()` 删除。
3. **修改系统配置** —— 装包脚本会追加 `/etc/pacman.conf` 仓库、导入并签名 GPG key、执行 `pacman -Syu`、启用服务、修改用户组。
4. **自动执行脚本** —— `run_onchange_*` 会在模板内容或数据变化时随 apply 运行，可能直接触发上述系统级操作。

执行前务必预览：

```bash
chezmoi diff
chezmoi apply -n -v
```
