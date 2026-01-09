function g --wraps='sudo pacman -Syyu' --description 'alias g sudo pacman -Syyu'
  sudo pacman -Syyu $argv
        
end
