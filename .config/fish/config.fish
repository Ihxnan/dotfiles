if status is-interactive
    # Commands to run in interactive sessions can go here
end

set fish_greeting ""

starship init fish | source
zoxide init fish --cmd cd | source

function y
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	yazi $argv --cwd-file="$tmp"
	if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
		builtin cd -- "$cwd"
	end
	rm -f -- "$tmp"
end

function code
	command code --ozone-platform=wayland $argv
end


function ls
	command eza $argv
end

thefuck --alias | source

function f 

    command bash $HOME/.config/scripts/fastfetch-random-wife.sh

   end

set -x PATH $CUDA_HOME/bin $PATH ~/bin

bind \cy forward-char

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f /opt/anaconda/bin/conda
    eval /opt/anaconda/bin/conda "shell.fish" "hook" $argv | source
else
    if test -f "/opt/anaconda/etc/fish/conf.d/conda.fish"
        . "/opt/anaconda/etc/fish/conf.d/conda.fish"
    else
        set -x PATH "/opt/anaconda/bin" $PATH
    end
end
# <<< conda initialize <<<

