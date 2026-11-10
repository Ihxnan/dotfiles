function ask -a page
    set -l q (string join ' ' $argv[2..-1])
    set -l slug (string replace -a ' ' '-' "$page")
    tldr $slug >/dev/null 2>&1
    or begin
        echo "tldr 里没有 $page 这个页面，换个名字试试"
        return 1
    end
    test -z "$q"; and set q "$page 怎么用"
    aichat -r neko -f "`tldr $slug`" "$q" | sed '/<think>/,/<\/think>/d'
end
