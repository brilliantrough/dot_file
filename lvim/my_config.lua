
-- 添加对 zsh 和自定义文件的支持
vim.filetype.add({
  filename = {
    [".zshrc"] = "zsh",
    [".aliases"] = "zsh",
    [".variable"] = "zsh",
    [".func"] = "zsh",
  },
})

-- 为 zsh 启用 LSP
require("lvim.lsp.manager").setup("bashls", {
  filetypes = { "sh", "zsh" },
})
