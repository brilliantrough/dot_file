-- 设置主题为 onedark
-- table.insert(lvim.plugins, {
--   "nvim-treesitter/nvim-treesitter",
--   opts = {
--     highlight = {
--       enable = true,
--       custom_captures = {
--         ["comment"] = "Comment",
--         ["function"] = "Function",
--         ["variable"] = "Identifier",
--         ["keyword.control"] = "Keyword",
--         ["keyword.operator"] = "Operator",
--         ["entity.name.type.class"] = "Type",
--         ["storage.type.primitive.java"] = "Type",
--         ["entity.name.type.interface"] = "Type",
--         ["entity.name.namespace"] = "Include",
--         ["entity.name.tag"] = "Tag",
--         ["meta.function-call.generic.python"] = "Function",
--         ["meta.member.access.python"] = "Identifier",
--         ["variable.other.property"] = "Identifier",
--         ["meta.function-call.python"] = "Function",
--         ["variable.other.local.cpp"] = "Identifier",
--         ["variable.other.global"] = "Identifier",
--       },
--     },
--   },
-- })

table.insert(lvim.plugins, {
  "navarasu/onedark.nvim",
  opts = {
    colors = {
      purple = "#c978dd",
      blue = "#00aeff",
    },
  }
})
lvim.colorscheme = 'onedark'
vim.g.lightline = {
  colorscheme = 'onedark',
}

-- 配置 airline 颜色方案
vim.g.airline_theme = 'onedark'

-- -- 使用 nvim-treesitter 配置高亮
-- local api = vim.api

-- -- 设置高亮函数
-- local function set_highlight(group, color)
--   api.nvim_set_hl(0, group, color)
-- end

-- -- 配置高亮颜色
-- set_highlight("Comment", { fg = "#04ff43", bg = "NONE", italic = true })
-- set_highlight("Function", { fg = "#00aeff", bg = "NONE" })
-- set_highlight("Keyword", { fg = "#c978dd", bg = "NONE" }) -- 控制符
-- set_highlight("Operator", { fg = "#f07d3b", bg = "NONE" }) -- 算数符
-- set_highlight("Type", { fg = "#E5C07B", bg = "NONE" }) -- 类名
-- set_highlight("StorageClass", { fg = "#c0526a", bg = "NONE" }) -- 原始类型
-- set_highlight("Interface", { fg = "#c0526a", bg = "NONE" }) -- 接口
-- set_highlight("Namespace", { fg = "#74817c", bg = "NONE" }) -- 导入部分
-- set_highlight("Tag", { fg = "#d35c5c", bg = "NONE" }) -- HTML标签
-- set_highlight("FunctionCall", { fg = "#19aef3", bg = "NONE" }) -- Python函数调用
-- set_highlight("MemberAccess", { fg = "#09e3f3", bg = "NONE" }) -- 成员访问
-- set_highlight("Variable", { fg = "#ABB2BF", bg = "NONE" }) -- 变量
-- set_highlight("GlobalVariable", { fg = "#e6b71e", bg = "NONE", italic = true }) -- 全局变量

