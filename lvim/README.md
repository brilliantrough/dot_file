# LunarVim 配置说明

这套配置的入口是 `config.lua`，实际会按顺序加载：`my_keymap.lua`、`my_onedark.lua`、`my_playground.lua`、`my_config.lua`、`my_surround.lua`。

## 我额外加了什么

- 主题改成 `onedark`，并自定义了紫色和蓝色。
- 额外启用 `nvim-treesitter/playground`，方便查看 Treesitter 解析结果。
- 额外启用 `nvim-surround`，补充包裹/修改包裹字符的能力。
- 给 `.zshrc`、`.aliases`、`.variable`、`.func` 这些文件强制识别为 `zsh`，并让 `bashls` 同时服务 `sh` 和 `zsh`。
- 增加了复制消息和清空消息区的命令，方便排查报错和复制提示信息。

## 我自定义的快捷键

| 按键 | 模式 | 作用 |
| --- | --- | --- |
| `<A-h>` | 普通模式 | 切换到上一个 buffer |
| `<A-l>` | 普通模式 | 切换到下一个 buffer |
| `<C-n>` | 普通模式 | 打开或关闭 `NvimTree` |
| `<C-/>` 实际对应 `<C-_>` | 普通模式 | 注释当前行 |
| `<C-/>` 实际对应 `<C-_>` | 可视模式 | 注释选区 |
| `<C-c>` | 普通模式 | 调用 `:CopyMessages`，复制最近一条完整消息 |
| `<A-j>` | `toggleterm` 终端内 | 切到下一个浮动终端，并直接进入输入模式 |
| `<A-k>` | `toggleterm` 终端内 | 切到上一个浮动终端，并直接进入输入模式 |

## 我自定义的命令

- `:CopyMessages`：复制最近一条完整消息到系统剪贴板寄存器 `+`。
- `:ClearMessages`：清空消息区。

如果 `:CopyMessages` 没把内容送到系统剪贴板，通常是当前环境没有可用的剪贴板提供者。

## 额外插件怎么用

### nvim-surround

这是一个默认操作很值得记住的插件：

- `ys{motion}{char}`：给一段内容加包裹。
- `ds{char}`：删除当前包裹。
- `cs{target}{replacement}`：把一种包裹改成另一种包裹。

几个最容易回忆的例子：

- `ysiw)`：把当前单词包成 `(word)`。
- `ds]`：删除 `[]` 这种包裹。
- `cs'"`：把单引号改成双引号。

### nvim-treesitter/playground

- `:TSPlaygroundToggle`：打开或关闭 Treesitter Playground。
- 打开后常用键：`o` 打开 query editor，`i` 切换高亮组显示，`t` 切换 injected languages，`<CR>` 跳回源码里的当前节点。
- 如果只想快速看当前节点或高亮信息，也可以用 `:TSNodeUnderCursor` 和 `:TSHighlightCapturesUnderCursor`。

## 现成值得记住的能力

- 详细快捷键速查已经整理在 `lvim-keymaps.md`，里面同时包含 LunarVim 默认快捷键和我自己加的快捷键。
- 常用默认入口可以优先记这些：`<leader>e` 文件树、`<leader>f` 查文件、`<leader>st` 全文搜索、`<leader>gg` 打开 lazygit、`<leader>la` Code Action、`<leader>lf` 格式化、`<leader>Lk` 查看键位映射。
- 终端相关默认入口：`<C-\\>` 打开默认终端，`<M-1>` / `<M-2>` / `<M-3>` 打开不同方向的 `toggleterm`。

## 目录里每个文件的作用

- `config.lua`：主入口，只负责加载各个 `my_*.lua`。
- `my_keymap.lua`：自定义快捷键、自定义命令、浮动终端切换逻辑。
- `my_onedark.lua`：主题与颜色设置。
- `my_playground.lua`：Treesitter Playground 插件。
- `my_config.lua`：zsh 文件类型和 `bashls` 扩展。
- `my_surround.lua`：`nvim-surround` 插件。
- `lazy-lock.json`：插件版本锁定文件。
- `lvim-keymaps.md`：完整快捷键备忘。
- `lv-settings.lua`：一份本地保存的 LunarVim 设置快照，当前 **没有** 在 `config.lua` 里被加载，改它不会直接影响当前配置。
