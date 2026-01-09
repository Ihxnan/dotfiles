function graph --wraps='git log --oneline --graph --decorate --all' --description 'alias graph git log --oneline --graph --decorate --all'
  git log --oneline --graph --decorate --all $argv
        
end
