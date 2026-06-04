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
--
-- 在已打开的浮动 toggleterm 之间循环切换
local function switch_float_toggleterm(step)
  local ok, terminal = pcall(require, "toggleterm.terminal")
  if not ok then
    vim.notify("toggleterm is not available", vim.log.levels.WARN)
    return
  end

  local float_terms = vim.tbl_filter(function(term)
    return term.direction == "float"
  end, terminal.get_all())

  if #float_terms < 2 then
    vim.notify("No other floating terminal", vim.log.levels.INFO)
    return
  end

  local current_id = terminal.get_focused_id()
  if not current_id then
    local identified_id = terminal.identify()
    current_id = identified_id
  end

  local current_index = nil
  for index, term in ipairs(float_terms) do
    if term.id == current_id then
      current_index = index
      break
    end
  end

  if not current_index then
    current_index = step > 0 and 0 or 2
  end

  local next_index = ((current_index - 1 + step) % #float_terms) + 1
  local target = float_terms[next_index]
  if target:is_open() then
    target:focus()
  else
    target:open()
  end
  vim.schedule(function()
    if target and target.bufnr and vim.api.nvim_buf_is_valid(target.bufnr) then
      target:set_mode(terminal.mode.INSERT)
    end
  end)
end

_G.switch_next_float_terminal = function()
  switch_float_toggleterm(1)
end

_G.switch_prev_float_terminal = function()
  switch_float_toggleterm(-1)
end

vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "term://*toggleterm#*",
  callback = function(args)
    local opts = { buffer = args.buf, noremap = true, silent = true }
    vim.keymap.set({ "t", "n" }, "<A-j>", _G.switch_next_float_terminal, opts)
    vim.keymap.set({ "t", "n" }, "<A-k>", _G.switch_prev_float_terminal, opts)
  end,
})

--
-- 定义一个函数用来复制最近一条完整的消息
function _G.copy_full_last_message()
  -- 获取所有消息
  local messages = vim.api.nvim_exec('messages', true)
  
  -- 分割消息字符串为行数组
  local message_lines = vim.split(messages, '\n', {})

  -- 从底部开始查找并聚合最近一条完整消息
  local last_message = {}
  local is_message_complete = false

  for i = #message_lines, 1, -1 do
    local line = message_lines[i]

    -- 当发现首个非空行开始聚合
    if not is_message_complete and line ~= "" then
      is_message_complete = true
    end

    -- 在发现信息时聚合行; 一旦信息开始，捕获所有非空行
    if is_message_complete then
      table.insert(last_message, 1, line) -- 插入行到顶部以保持顺序
      -- 在发现空行后表示一条消息的终结
      if line == "" then
        break
      end
    end
  end
  
  -- 将消息复制到系统剪贴板
  if #last_message > 0 then
    local message_str = table.concat(last_message, '\n')
    vim.fn.setreg('+', message_str)
    print("Copied the last full message to clipboard.")
  else
    print("No message to copy")
  end
end

-- 定义一个自定义命令 CopyMessages 来调用此函数
vim.cmd([[command! CopyMessages lua copy_full_last_message()]])

-- （可选）通过快捷键来调出这个命令
vim.api.nvim_set_keymap('n', '<C-c>', ':CopyMessages<CR>', { noremap = true, silent = true })

-- 定义一个 Lua 函数来清空 messages
function _G.clear_messages()
  -- 执行没有输出影响的命令，重定向到“NULL”
  vim.cmd('redir @a | messages clear | redir END')
end

-- 在配置文件中创建 ClearMessages 命令
vim.cmd([[command! ClearMessages lua clear_messages()]])
