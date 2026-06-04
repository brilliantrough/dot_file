-- nvim-surround
table.insert(lvim.plugins, {
  "kylechui/nvim-surround",
  version = "*", -- 使用最新稳定版
  config = function()
    require("nvim-surround").setup({
      -- 这里可以优化你的插件配置
    })
  end
})
