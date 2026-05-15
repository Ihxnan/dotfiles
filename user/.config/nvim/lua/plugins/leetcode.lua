return {
    "rainLyn/leetcode.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
    },
    opts = {

        storage = {
            home = vim.fn.expand("~/CODE/leetcode"),
            cache = vim.fn.expand("~/CODE/leetcode/.cache"),
        },

        injector = {
            ["cpp"] = {
                imports = function()
                    return {
                        "#include <algorithm>",
                        "#include <map>",
                        "#include <queue>",
                        "#include <regex>",
                        "#include <set>",
                        "#include <stack>",
                        "#include <string>",
                        "#include <unordered_map>",
                        "#include <unordered_set>",
                        "#include <vector>",
                        "",
                        "using namespace std;"
                    }
                end,
            },
        }
    }
}
