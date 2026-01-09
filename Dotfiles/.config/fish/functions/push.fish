function push --wraps='hexo clean && hexo generate && hexo deploy' --description 'alias push hexo clean && hexo generate && hexo deploy'
  hexo clean && hexo generate && hexo deploy $argv
        
end
