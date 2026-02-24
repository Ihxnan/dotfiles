# 个人命令行工具集合

这是一个包含各种实用 shell 脚本和可执行文件的个人工具集合，主要用于系统管理、多媒体控制、开发工具和日常任务自动化。

## 主要工具

### 系统管理
- `gpu.sh` - 显示 NVIDIA GPU 使用率
- `i3wm.sh` - 设置系统默认启动图形界面
- `time.sh` - 同步系统时间到 Windows 时间服务器
- `mykill` - 根据进程名终止进程
- `psmode` - 进程状态管理工具

### 多媒体控制
- `music_toggle` - 音乐播放/暂停切换（支持 MPD 和 Spotify）
- `music_next` - 下一曲
- `music_prev` - 上一曲
- `mpd_toggle` - MPD 音乐播放器控制
- `spotify_toggle` - Spotify 播放器控制

### 开发工具
- `dotfiles` - 克隆配置文件仓库
- `gitssl` - Git SSL 配置工具
- `submit` - Git 提交自动化脚本（add、commit、push）
- `u` - 更新工具
- `Syyu` - 系统更新工具

### 搜索和界面工具
- `rofi-search.sh` - 使用 Rofi 进行 Google 搜索
- `html` - HTML 处理工具

### 网络工具
- `dp` / `dp.cn` - 网络诊断工具
- `yun` - 云服务工具
- `ubuntu` / `manjaro` - 发行版特定工具

### 其他工具
- `move` - 文件移动工具
- `pipes` - 管道工具
- `key` - 密钥管理
- `tuo` - 工具
- `tty.sh` - 终端配置
- `zhu` - 工具

## 使用说明

大多数脚本需要可执行权限：
```bash
chmod +x <脚本名>
```

## 环境要求

- Linux 系统（主要针对 Arch/Manjaro 发行版）
- Bash shell 环境
- NVIDIA GPU（对于 gpu.sh）
- i3 窗口管理器（对于 i3wm.sh）
- MPD 音乐播放器（对于音乐控制脚本）
- Spotify（对于 spotify_toggle）
- Rofi（对于 rofi-search.sh）
