require("config.options")
require("config.lazy")
require("config.keymaps")

vim.opt.runtimepath:append("$HOME/WorkSpace/NvimPluginMyself/example")

local pkg = require("example")

pkg.setup()
