-- lvim.builtin.which_key.mappings["<A-l>"] = { ":bn<CR>", "Next Tab" }
-- lvim.builtin.which_key.mappings["<A-h>"] = { ":bp<CR>", "Previous Tab" }
vim.api.nvim_set_keymap('n', '<A-l>', ':bn<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<A-h>', ':bp<CR>', { noremap = true, silent = true })

-- 使用 vim.api.nvim_set_keymap 设置快捷键
local options = { noremap = true, silent = true }

-- Ctrl+n 切换 nvim-tree 的状态
vim.api.nvim_set_keymap('n', '<C-n>', ':NvimTreeToggle<CR>', options)

-- 如果需要在打开时聚焦 nvim-tree
-- vim.api.nvim_set_keymap('n', '<C-n>', ':NvimTreeToggle<CR>:wincmd p<CR>', options)

-- 在 normal 模式下用 Ctrl+/ 注释
vim.api.nvim_set_keymap('n', '<C-_>', ':lua require("Comment.api").toggle.linewise.current()<CR>', options)

-- 在 visual 模式下用 Ctrl+/ 注释选中部分
vim.api.nvim_set_keymap('v', '<C-_>', ':lua require("Comment.api").toggle.linewise(vim.fn.visualmode())<CR>', options)

-- <C-_> 是 Ctrl + / 的 ASCII 表示，因为 / 位于 _ 的位置
