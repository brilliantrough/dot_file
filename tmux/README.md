# tmux 配置说明

这里保存的是一套基于 [Oh My Tmux](https://github.com/gpakosz/.tmux) 的配置。`~/.tmux.conf` 更像主配置框架，真正和我日常使用习惯最相关的覆盖项主要在 `~/.tmux.conf.local`。

## 先记住最重要的一点

我的 tmux 前缀键不是默认的 `Ctrl-b`，而是 **`Ctrl-x`**。

## 常用快捷键

| 按键 | 作用 |
| --- | --- |
| `prefix + e` | 打开并编辑 `~/.tmux.conf.local`，保存后自动重新加载 |
| `prefix + r` | 重新加载 tmux 配置 |
| `prefix + C-c` | 新建 session |
| `prefix + C-f` | 查找并切换 session |
| `prefix + BTab` | 切回上一个 session |
| `prefix + W` | 新建 window |
| `prefix + H` | 切到下一个 window |
| `prefix + L` | 切到上一个 window |
| `prefix + -` | 纵向分屏（上下） |
| `prefix + \|` | 横向分屏（左右） |
| `prefix + h/j/k/l` | 在 pane 之间左/下/上/右跳转 |
| `prefix + +` | 最大化当前 pane，再按一次恢复 |
| `prefix + m` | 开关鼠标模式 |
| `prefix + U` | 调用 urlview，提取当前 pane 里的链接 |
| `prefix + b` | 查看 tmux buffer 列表 |
| `prefix + p` | 粘贴最近一次 buffer |
| `prefix + P` | 选择某个 buffer 再粘贴 |
| `prefix + Ctrl-p` | 粘贴 buffer |
| `Home` | 发送正确的 Home 键序列给当前程序 |
| `End` | 发送正确的 End 键序列给当前程序 |

## 复制模式与剪贴板

我现在是 `vi` 风格复制模式，并且做了额外增强：

- `prefix + Escape` 或 `prefix + Enter`：进入复制模式。
- 在复制模式里按 `v`：开始选择。
- 按 `Ctrl-v`：切换矩形选择。
- 按 `y`：复制到系统剪贴板，但**不退出**复制模式。
- 按 `Y`：复制到系统剪贴板，并**退出**复制模式。
- 按 `Enter`：复制到系统剪贴板，并退出复制模式。
- 按 `H`：跳到当前行开头。
- 按 `L`：跳到当前行结尾。
- 按 `Escape` 或 `q`：退出复制模式。
- 鼠标拖选结束时会自动复制到系统剪贴板。
- 鼠标中键会把系统剪贴板内容读进 tmux 再粘贴。

这套复制逻辑依赖 `xclip`，如果系统里没有 `xclip`，鼠标拖选和 `copy-pipe` 行为就不会完整生效。

## 当前这套 tmux 配置提供了什么能力

- 开启鼠标支持、系统剪贴板支持、`zsh` 作为默认 shell、50000 行历史记录。
- 颜色按 truecolor 方式设置，状态栏是深色 onedark 风格。
- 状态栏会显示 session、uptime、前缀状态、鼠标状态、电池、电量百分比、时间、用户名和主机名。
- window 和 pane 编号都从 `1` 开始。
- `automatic-rename` 已关闭，所以 window 名称不会总被当前程序覆盖。
- `visual-activity` 已开启，窗口有活动时会有更明显提示。

## 我加载了哪些插件

- `tmux-resurrect`：保存/恢复 tmux 会话。
- `tmux-continuum`：配合会话恢复做持续保存。
- `tmux-prefix-highlight`：在状态栏里提示当前是否按下前缀键。
- `tmux-copycat`：快速搜索/复制 pane 中的路径、URL 等信息。
- `tmux-sessionist`：增强 session 操作。
- `tmux-pain-control`：增强 pane 管理。
- `vim-tmux-navigator`：和 Vim/Neovim 之间统一窗格移动习惯。
- `tmux-onedark-theme`：状态栏主题。

插件自动更新在启动和 reload 时都被关掉了，所以一般需要自己手动触发安装或更新。

- `prefix + I`：安装插件。
- `prefix + u`：更新插件。
- `prefix + Alt-u`：卸载插件。
- `prefix + Ctrl-s`：保存当前 tmux 会话。
- `prefix + Ctrl-r`：恢复上一次保存的 tmux 会话。

## 一些容易忘的备注

- `prefix + H` / `prefix + L` 现在被我拿去切换 window 了，所以不再用来左右调整 pane 大小。
- pane 大小调整里，主配置还保留了 `prefix + J` / `prefix + K` 这种 resize 绑定，但我平时更常用直接切 pane。
- `tmux-resurrect` 这套配置是朝着“重启后把 Neovim/tmux 环境一起恢复”去配的。
- 这个目录只是仓库里的副本，真正生效的是用户主目录下的 `~/.tmux.conf` 和 `~/.tmux.conf.local`。

## 目录里每个文件的作用

- `.tmux.conf`：Oh My Tmux 主配置，尽量少直接改。
- `.tmux.conf.local`：我自己的覆盖配置和自定义快捷键，真正最值得回忆的是这里。
