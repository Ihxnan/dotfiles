# Dotfiles

#### 个人系统配置与工具偏好的配置文件集合

本仓库整合了日常使用的各类工具与系统配置，旨在实现跨设备快速同步个人工作流，减少新环境下的重复配置成本。

---

## 前置要求
在使用前，请确保系统以安装以下工具(用于拉取仓库与执行部署脚本)：

| 工具                                 | 作用               | 安装命令                                                                            |
| :-:                                  | :-:                | :-:                                                                                 |
| [Git](https://git-scm.com/downloads) | 版本控制与仓库拉取 | **Arch 系列**: `sudo pacman -S git` <br> **Debian 系列**: `sudo apt install git`    |

---

## 安装步骤

### 1. 克隆仓库到本地

首先，通过 git 命令将 Dotfiles 仓库克隆到本地计算机，并进入仓库目录（后续所有操作均在此目录下执行）
    
#### 推荐：通过 GitHub 官方源拉取（需能访问 GitHub）
```bash
git clone https://github.com/Ihxnan/Dotfiles.git
cd Dotfiles
```
#### 备用：若无法访问 GitHub，使用Gitee
#### 注意：后续nvim插件大概率装不上
```bash
git clone https://gitee.com/Ihxnan/Dotfiles.git
cd Dotfiles
```

### 2. 执行对应系统的部署脚本
根据你的 Linux 发行版（Arch 或 Debian 系列，如 Ubuntu、Deepin 等），执行对应的脚本安装所需软件, 并部署配置文件。

#### Arch 系列系统(Manjaro/EndeavourOS 等)
```bash
bash scripts/arch
```
#### Debian 系列系统(Ubuntu/Deepin/Pop!_OS 等)
```bash
bash scripts/debian
```

---

## 关键注意事项

### 1. Neovim 插件自动安装
- 系统重启后(安装脚本执行晚会自动重启)，**首次启动 Neovim**（终端输入 `nvim`）时，插件管理器 `lazy.nvim` 会自动下载并安装所有插件。
- 若安装过程中出现短暂报错（如网络波动导致部分插件下载中断），无需手动处理，关闭并重新打开 Neovim 即可继续完成剩余插件安装。

### 2. vim 插件安装
打开vim, 输入`:PlugInstal`安装插件

### 3. 镜像源拉取后的插件恢复（若使用备用克隆地址）
若通过 `gitclone.com` 镜像源拉取仓库，可能导致 Neovim 插件无法正常安装，可执行以下命令重置 Neovim 配置：
```bash
rm -rf ~/.config/nvim/ ~/.vimrc
```

### 4. Arch 系列
paru 更新时会要求输入用户密码

### 5. nvidia 闭源驱动
```
sudo mhwd -a pci nonfree 0300
```

---


## 配置内容清单
本仓库包含以下工具的完整配置，部署后即可直接使用个人定制化环境：

| 工具类型        | 具体工具  | 配置文件路径         | 功能说明                     |
| --------------- | --------- | -------------------- | ---------------------------- |
| 窗口管理器      | i3        | `.i3/config`         | 高效键盘流窗口管理配置       |
| 终端模拟器      | Alacritty | `.config/alacritty/` | 高性能终端，含配色与快捷键   |
| Shell           | Fish      | `.config/fish/`      | 自动补全、高亮的友好 Shell   |
| 代码编辑器      | Neovim    | `.config/nvim/`      | 全 Lua 配置的 IDE 级编辑器   |
| 代码编辑器      | Vim       | `.vimrc`             | 轻量 Vim 基础配置            |
| 文件管理器      | Ranger    | `.config/ranger/`    | 终端可视化文件管理工具       |
| 状态栏          | i3blocks  | `.config/i3blocks/`  | i3 窗口管理器配套状态栏      |
| 窗口 compositor | Picom     | `.config/picom.conf` | 窗口透明与动画效果配置       |
| 包管理器        | Pacman    | `Arch/pacman.conf`   | Arch 系软件源与安装优化配置  |
| 代码编辑器      | VS Code   | `vscode`             | 含插件列表、快捷键与配色方案 |
| 音乐播放器      | mpd       | `.config/mpd`        | mpd基础配置                  |
| mpd服务器       | ncmpcpp   | `.config/ncmpcpp`    | ncmpcpp快捷键和基础配置      |


---

## 脚本功能说明
仓库内 `scripts` 目录提供辅助脚本，便于日常维护配置：

| 脚本路径               | 功能                           | 使用场景                     |
|------------------------|--------------------------------|------------------------------|
| `scripts/backup`       | 备份当前系统配置到仓库         | 本地修改配置后，同步到仓库   |
| `scripts/submit`       | 提交本地更新到远程 GitHub 仓库 | 配置优化后，推送更新到云端   |
| `scripts/arch_only`    | 仅部署 Arch 系 Pacman 配置     | 无需完整部署，仅更新包管理器 |

---
