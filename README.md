# Dotfiles

个人 Linux 桌面环境配置，基于 Arch Linux + i3wm 的平铺窗口管理器，支持动态主题切换、自动壁纸、音乐播放等功能。

## ArchLinux 一键安装脚本

> **前置：联网** — Arch ISO 启动后先连 WiFi：
> ```sh
> iwctl                          # 进入交互终端
> device list                    # 查看网卡名（如 wlan0）
> station wlan0 scan             # 扫描
> station wlan0 get-networks     # 列出可用网络
> station wlan0 connect SSID     # 连接（按提示输入密码）
> quit                           # 退出
> ```

```sh
# Gitee（国内推荐）
bash <(curl -L https://gitee.com/ihxnan/dotfiles/raw/main/archinstall.sh)

# GitHub
bash <(curl -L https://raw.githubusercontent.com/Ihxnan/dotfiles/main/archinstall.sh)
```

## 同步配置

系统安装完成后，克隆仓库并执行安装脚本：

```sh
# Gitee（国内推荐）
git clone https://gitee.com/ihxnan/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh

# GitHub
git clone https://github.com/Ihxnan/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh
```

`install.sh` 会安装所有依赖包、配置 Oh My Zsh、创建所需目录，
并自动执行 `symlink.sh` 创建配置文件符号链接。

> **注意**：克隆后的 `~/dotfiles` 目录请勿删除，所有配置文件
> 通过符号链接指向该目录，删除后配置将全部失效。

## 核心组件

- **窗口管理器**: i3wm + polybar
- **终端**: Alacritty / Kitty
- **主题**: matugen (根据壁纸自动生成配色)
- **音乐[^1]**: MPD + ncmpcpp + Cava
- **编辑器[^配置]**: Neovim
- **Shell**: Zsh + Oh My Zsh + Powerlevel10k
- **文件管理**: Yazi

## 快捷键

- `Mod+Return`: Kitty 终端
- `Mod+d`: 应用启动器
- `Mod+↑/←/→/↓`: 音乐控制
- `Mod+F10`: 随机切换壁纸[^壁纸文件夹]

[^1]:请将音乐文件下载到`~/Music`下
[^配置]: 首次运行`nvim`自动配置
[^壁纸文件夹]:  默认为`~/.wallpapers`
