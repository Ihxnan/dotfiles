if status is-interactive
    # Commands to run in interactive sessions can go here
    export EDITOR=/usr/bin/nvim
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    set -x PATH $PATH ~/bin/
    set -x BROWSER /usr/bin/chromium
end

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f /home/ihxnan/anaconda3/bin/conda
    eval /home/ihxnan/anaconda3/bin/conda "shell.fish" "hook" $argv | source
else
    if test -f "/home/ihxnan/anaconda3/etc/fish/conf.d/conda.fish"
        . "/home/ihxnan/anaconda3/etc/fish/conf.d/conda.fish"
    else
        set -x PATH "/home/ihxnan/anaconda3/bin" $PATH
    end
end
# <<< conda initialize <<<

