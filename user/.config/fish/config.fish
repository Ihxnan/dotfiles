if status is-interactive
    # Commands to run in interactive sessions can go here
    set -g fish_escape_delay_ms 100
    bind \cy accept-autosuggestion
end
set fish_greeting ""
set -p PATH ~/.local/bin ~/.npm-global/bin ~/.local/share/pnpm/bin
starship init fish | source
zoxide init fish --cmd cd | source
# 111
function jk
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	yazi $argv --cwd-file="$tmp"
	if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
		builtin cd -- "$cwd"
	end
	rm -f -- "$tmp"
end

function cat 
	command bat $argv
end
function ls
	# command eza --icons $argv
	command lsi $argv
end

function lt
	command eza --icons --tree $argv
end
# grub
abbr grub 'LANGUAGE=en_US.UTF-8 LANG=en_US.UTF-8 sudo grub-mkconfig -o /boot/grub/grub.cfg'
# 小黄鸭补帧 需要steam安装正版小黄鸭
abbr lsfg 'LSFG_PROCESS="miyu"'
# fa运行fastfetch
abbr fa fastfetch
abbr reboot 'systemctl reboot'
function sl 
	command sl | lolcat	
end
function 滚
	sysup 
end
function raw
	command ~/.local/bin/random-anime-wallpaper-dms $argv
end

function 安装
	command yay -S $argv
end

function 卸载
	command yay -Rns $argv
end 

set -x PAC_OPENCODE_MODEL "deepseek/deepseek-v4-pro"

# OpenClaw Completion
test -f "/home/ihxnan/.openclaw/completions/openclaw.fish"; and source "/home/ihxnan/.openclaw/completions/openclaw.fish"

# OpenCode API config
set -x ANTHROPIC_BASE_URL https://api.deepseek.com/anthropic
set -x ANTHROPIC_AUTH_TOKEN sk-a8cc5dc2a0c44811b7dfe3fcbd3ba77b
set -x ANTHROPIC_MODEL deepseek-v4-pro
set -x ANTHROPIC_DEFAULT_OPUS_MODEL deepseek-v4-pro
set -x ANTHROPIC_DEFAULT_SONNET_MODEL deepseek-v4-pro
set -x ANTHROPIC_DEFAULT_HAIKU_MODEL deepseek-v4-flash
set -x CLAUDE_CODE_SUBAGENT_MODEL deepseek-v4-flash
set -x CLAUDE_CODE_EFFORT_LEVEL max

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /home/ihxnan/.lmstudio/bin
# End of LM Studio CLI section

