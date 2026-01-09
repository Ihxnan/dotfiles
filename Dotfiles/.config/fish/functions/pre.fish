function pre --wraps='hexo clean && hexo server' --description 'alias pre hexo clean && hexo server'
  hexo clean && hexo server $argv
        
end
