# LunarVim 快捷键速查

这份文档基于当前目录 `/home/pzy000/.config/lvim` 的实际配置整理。

- 当前 `leader` 键是 `Space`
- 当前系统中没有单独的用户级 `~/.config/nvim` 配置目录
- 文档同时包含：
  - LunarVim 默认快捷键
  - 你在 `my_keymap.lua` 中新增的快捷键

## 文件与目录

| 按键 | 作用 | 来源 |
| --- | --- | --- |
| `<leader>e` | 打开或关闭文件树 `NvimTree` | LunarVim |
| `<C-n>` | 打开或关闭文件树 `NvimTree` | 自定义 |
| `<leader>f` | 查找项目文件 | LunarVim |
| `<leader>;` | 打开 Dashboard | LunarVim |
| `<leader>Lc` | 打开 `config.lua` | LunarVim |
| `<leader>Lf` | 查找 LunarVim 配置文件 | LunarVim |
| `<leader>Lg` | 在 LunarVim 配置文件中搜索 | LunarVim |
| `<leader>Lk` | 查看键位映射 | LunarVim |

## 缓冲区与窗口

### 缓冲区

| 按键 | 作用 | 来源 |
| --- | --- | --- |
| `<A-h>` | 切换到上一个 buffer | 自定义 |
| `<A-l>` | 切换到下一个 buffer | 自定义 |
| `<leader>c` | 关闭当前 buffer | LunarVim |
| `<leader>bj` | 选择并跳转到某个 buffer | LunarVim |
| `<leader>bf` | 列出并查找 buffers | LunarVim |
| `<leader>bb` | 切换到上一个 buffer | LunarVim |
| `<leader>bn` | 切换到下一个 buffer | LunarVim |
| `<leader>be` | 选择要关闭的 buffer | LunarVim |
| `<leader>bh` | 关闭左侧所有 buffer | LunarVim |
| `<leader>bl` | 关闭右侧所有 buffer | LunarVim |
| `<leader>bD` | 按目录排序 buffer | LunarVim |
| `<leader>bL` | 按语言类型排序 buffer | LunarVim |
| `<leader>bW` | 保存但不触发自动命令 | LunarVim |

### 窗口跳转与尺寸

| 按键 | 作用 | 来源 |
| --- | --- | --- |
| `<C-h>` | 跳到左侧窗口 | LunarVim |
| `<C-j>` | 跳到下方窗口 | LunarVim |
| `<C-k>` | 跳到上方窗口 | LunarVim |
| `<C-l>` | 跳到右侧窗口 | LunarVim |
| `<C-Up>` | 减小窗口高度 | LunarVim |
| `<C-Down>` | 增大窗口高度 | LunarVim |
| `<C-Left>` | 减小窗口宽度 | LunarVim |
| `<C-Right>` | 增大窗口宽度 | LunarVim |

### 行移动

| 按键 | 作用 | 来源 |
| --- | --- | --- |
| 普通模式 `<A-j>` | 当前行下移 | LunarVim |
| 普通模式 `<A-k>` | 当前行上移 | LunarVim |
| 插入模式 `<A-j>` | 当前行下移并回到插入模式 | LunarVim |
| 插入模式 `<A-k>` | 当前行上移并回到插入模式 | LunarVim |
| 可视块模式 `<A-j>` | 选中块下移 | LunarVim |
| 可视块模式 `<A-k>` | 选中块上移 | LunarVim |

## 搜索与 Telescope

| 按键 | 作用 | 来源 |
| --- | --- | --- |
| `<leader>sf` | 查找文件 | LunarVim |
| `<leader>st` | 全文搜索 | LunarVim |
| `<leader>sh` | 查找帮助文档 | LunarVim |
| `<leader>sH` | 查找高亮组 | LunarVim |
| `<leader>sk` | 查找键位映射 | LunarVim |
| `<leader>sC` | 查找命令 | LunarVim |
| `<leader>sr` | 打开最近文件 | LunarVim |
| `<leader>sR` | 查看寄存器 | LunarVim |
| `<leader>sM` | 查看 man pages | LunarVim |
| `<leader>sb` | 查看 Git 分支 | LunarVim |
| `<leader>sc` | 选择配色方案 | LunarVim |
| `<leader>sp` | 带预览地选择配色方案 | LunarVim |
| `<leader>sl` | 恢复上一次 Telescope 搜索 | LunarVim |

### Telescope 内部常用按键

| 按键 | 作用 | 来源 |
| --- | --- | --- |
| 插入模式 `<C-n>` | 下一项 | LunarVim |
| 插入模式 `<C-p>` | 上一项 | LunarVim |
| 插入模式 `<C-j>` | 下一条历史 | LunarVim |
| 插入模式 `<C-k>` | 上一条历史 | LunarVim |
| 插入模式 `<C-c>` | 关闭 Telescope | LunarVim |
| 插入模式 `<C-q>` | 发送到 quickfix 并打开 | LunarVim |
| 插入模式 `<CR>` | 打开选中项 | LunarVim |
| 普通模式 `<C-n>` | 下一项 | LunarVim |
| 普通模式 `<C-p>` | 上一项 | LunarVim |
| 普通模式 `<C-q>` | 发送到 quickfix 并打开 | LunarVim |
| `buffers` 选择器插入模式 `<C-d>` | 删除 buffer | LunarVim |
| `buffers` 选择器普通模式 `dd` | 删除 buffer | LunarVim |

## 注释

| 按键 | 作用 | 来源 |
| --- | --- | --- |
| `<leader>/` | 注释当前行 | LunarVim |
| 可视模式 `<leader>/` | 注释选区 | LunarVim |
| `<C-/>` 实际对应 `<C-_>` | 注释当前行 | 自定义 |
| 可视模式 `<C-/>` 实际对应 `<C-_>` | 注释选区 | 自定义 |
| `gcc` | 注释当前行 | LunarVim |
| `gbc` | 块注释当前行 | LunarVim |
| `gc{motion}` | 按 motion 注释 | LunarVim |
| `gb{motion}` | 按 motion 块注释 | LunarVim |
| `gco` | 在下方插入注释行 | LunarVim |
| `gcO` | 在上方插入注释行 | LunarVim |
| `gcA` | 在行尾添加注释 | LunarVim |

## Git

| 按键 | 作用 | 来源 |
| --- | --- | --- |
| `<leader>gg` | 打开 lazygit | LunarVim |
| `<leader>gj` | 下一个 hunk | LunarVim |
| `<leader>gk` | 上一个 hunk | LunarVim |
| `<leader>gl` | 查看 blame | LunarVim |
| `<leader>gL` | 查看完整 blame | LunarVim |
| `<leader>gp` | 预览 hunk | LunarVim |
| `<leader>gr` | 重置 hunk | LunarVim |
| `<leader>gR` | 重置整个 buffer | LunarVim |
| `<leader>gs` | stage hunk | LunarVim |
| `<leader>gu` | 撤销 stage hunk | LunarVim |
| `<leader>go` | 查看已改动文件 | LunarVim |
| `<leader>gb` | 查看分支 | LunarVim |
| `<leader>gc` | 查看提交记录 | LunarVim |
| `<leader>gC` | 查看当前文件提交记录 | LunarVim |
| `<leader>gd` | 对比 `HEAD` 差异 | LunarVim |

## LSP

| 按键 | 作用 | 来源 |
| --- | --- | --- |
| `<leader>la` | Code Action | LunarVim |
| `<leader>ld` | 当前 buffer 诊断 | LunarVim |
| `<leader>lw` | 工作区诊断 | LunarVim |
| `<leader>lf` | 格式化 | LunarVim |
| `<leader>li` | 查看 LSP 信息 | LunarVim |
| `<leader>lI` | 打开 Mason | LunarVim |
| `<leader>lj` | 下一个诊断 | LunarVim |
| `<leader>lk` | 上一个诊断 | LunarVim |
| `<leader>ll` | 执行 CodeLens | LunarVim |
| `<leader>lq` | 诊断写入 loclist | LunarVim |
| `<leader>lr` | 重命名符号 | LunarVim |
| `<leader>ls` | 当前文档符号 | LunarVim |
| `<leader>lS` | 工作区符号 | LunarVim |
| `<leader>le` | 查看 quickfix | LunarVim |

## 调试

| 按键 | 作用 | 来源 |
| --- | --- | --- |
| `<leader>dt` | 切换断点 | LunarVim |
| `<leader>db` | Step Back | LunarVim |
| `<leader>dc` | Continue | LunarVim |
| `<leader>dC` | Run To Cursor | LunarVim |
| `<leader>dd` | Disconnect | LunarVim |
| `<leader>dg` | 获取当前会话 | LunarVim |
| `<leader>di` | Step Into | LunarVim |
| `<leader>do` | Step Over | LunarVim |
| `<leader>du` | Step Out | LunarVim |
| `<leader>dp` | Pause | LunarVim |
| `<leader>dr` | 切换 REPL | LunarVim |
| `<leader>ds` | Start | LunarVim |
| `<leader>dq` | Quit | LunarVim |
| `<leader>dU` | 切换 DAP UI | LunarVim |

## 终端

| 按键 | 作用 | 来源 |
| --- | --- | --- |
| `<C-\\>` | 打开默认终端 | LunarVim |
| `<M-1>` | 打开横向终端 | LunarVim |
| `<M-2>` | 打开纵向终端 | LunarVim |
| `<M-3>` | 打开浮动终端 | LunarVim |
| 终端模式 `<C-h>` | 跳到左侧窗口 | LunarVim |
| 终端模式 `<C-j>` | 跳到下方窗口 | LunarVim |
| 终端模式 `<C-k>` | 跳到上方窗口 | LunarVim |
| 终端模式 `<C-l>` | 跳到右侧窗口 | LunarVim |
| `1<C-\\>` | 打开或切换编号为 1 的终端 | ToggleTerm |
| `2<C-\\>` | 打开或切换编号为 2 的终端 | ToggleTerm |
| `3<C-\\>` | 打开或切换编号为 3 的终端 | ToggleTerm |
| 终端模式 `<A-j>` | 切换到下一个浮动 terminal，并直接进入输入模式 | 自定义 |
| 终端模式 `<A-k>` | 切换到上一个浮动 terminal，并直接进入输入模式 | 自定义 |

### 多开浮动 Terminal

- `1<C-\\>` 打开第 1 个浮动 terminal
- 关闭或隐藏后，`2<C-\\>` 可以打开第 2 个浮动 terminal
- 在浮动 terminal 里按 `<A-k>` 可以切回上一个浮动 terminal
- 在浮动 terminal 里按 `<A-j>` 可以切到下一个浮动 terminal
- 这些切换会自动重新打开已创建但当前隐藏的浮动 terminal
- 切换完成后会直接进入可输入状态，不需要再按 `i`

## Quickfix 与基础编辑

| 按键 | 作用 | 来源 |
| --- | --- | --- |
| `]q` | quickfix 下一项 | LunarVim |
| `[q` | quickfix 上一项 | LunarVim |
| `<C-q>` | 切换 quickfix 窗口 | LunarVim |
| `<leader>w` | 保存 | LunarVim |
| `<leader>q` | 退出 | LunarVim |
| `<leader>h` | 清除搜索高亮 | LunarVim |
| 可视模式 `<` | 左缩进并保持选区 | LunarVim |
| 可视模式 `>` | 右缩进并保持选区 | LunarVim |
| 命令行模式 `<C-j>` | 补全菜单下一项 | LunarVim |
| 命令行模式 `<C-k>` | 补全菜单上一项 | LunarVim |

## 插件与 LunarVim 管理

| 按键 | 作用 | 来源 |
| --- | --- | --- |
| `<leader>pi` | `Lazy install` | LunarVim |
| `<leader>ps` | `Lazy sync` | LunarVim |
| `<leader>pS` | `Lazy clear` | LunarVim |
| `<leader>pc` | `Lazy clean` | LunarVim |
| `<leader>pu` | `Lazy update` | LunarVim |
| `<leader>pp` | `Lazy profile` | LunarVim |
| `<leader>pl` | `Lazy log` | LunarVim |
| `<leader>pd` | `Lazy debug` | LunarVim |
| `<leader>Ld` | 查看 LunarVim 文档 | LunarVim |
| `<leader>Li` | 查看 LunarVim 信息面板 | LunarVim |
| `<leader>LI` | 查看 LunarVim 更新日志 | LunarVim |
| `<leader>Lr` | 重新加载配置 | LunarVim |
| `<leader>Lu` | 更新 LunarVim | LunarVim |
| `<leader>Ti` | 查看 Treesitter 配置 | LunarVim |

## 日志与消息

| 按键 | 作用 | 来源 |
| --- | --- | --- |
| `<C-c>` | 复制最近一条完整消息 | 自定义 |
| `:CopyMessages` | 复制最近一条完整消息 | 自定义 |
| `:ClearMessages` | 清空消息区 | 自定义 |
| `<leader>Lld` | 在终端查看默认日志 | LunarVim |
| `<leader>LlD` | 直接打开默认日志文件 | LunarVim |
| `<leader>Lll` | 在终端查看 LSP 日志 | LunarVim |
| `<leader>LlL` | 直接打开 LSP 日志文件 | LunarVim |
| `<leader>Lln` | 在终端查看 Neovim 日志 | LunarVim |
| `<leader>LlN` | 直接打开 Neovim 日志文件 | LunarVim |

## 你自定义的快捷键汇总

这些映射都来自 `my_keymap.lua`：

| 按键 | 作用 |
| --- | --- |
| `<A-h>` | 上一个 buffer |
| `<A-l>` | 下一个 buffer |
| `<C-n>` | 切换文件树 |
| `<C-/>` 实际对应 `<C-_>` | 注释当前行 |
| 可视模式 `<C-/>` 实际对应 `<C-_>` | 注释选区 |
| `<C-c>` | 复制最近一条完整消息 |
| 终端模式 `<A-j>` | 下一个浮动 terminal |
| 终端模式 `<A-k>` | 上一个浮动 terminal |

## 复习建议

- 先记住最常用的入口：`<leader>e`、`<leader>f`、`<leader>sf`、`<leader>st`、`<leader>la`、`<leader>gg`
- 缓冲区操作优先记 `bb`、`bn`、`bj`、`be`
- Git 操作优先记 `gj`、`gk`、`gp`、`gr`、`gs`
- LSP 操作优先记 `la`、`lf`、`lr`、`ld`
- 如果要查看系统内完整映射，可直接用 `<leader>Lk`
