# 关于

此仓库用来存储 Linux 系统中的一些配置文件，通常这些配置文件都是以点开头的隐藏文件。

## 一键配置

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/brilliantrough/dot_file/master/linux-setup.sh)"
```

安装 zsh、oh-my-zsh(含语法高亮/自动建议插件)、tmux,并部署 zsh 与 tmux 配置文件。国内网络建议先 `export http_proxy/https_proxy`。

## tmux

`.tmux.conf` 和 `.tmux.conf.local` 文件

## neovim

`init.vim` 和 `coc-settings.json` 文件

## lvim

LunarVim 配置文件，放在 `~/.config/lvim/` 目录下。

如果已经安装好 LunarVim，可在仓库根目录执行：

```bash
mkdir -p ~/.config/lvim
cp -r lvim/* ~/.config/lvim/
```

## squid

`/etc/squid/squid.conf` 文件

## proxychains

`/etc/proxychains.conf` 文件

## zsh

`.zshrc` 保持通用配置;个人函数、别名拆在 `.func` 和 `.aliases`,部署到 `~/.func`、`~/.aliases`,并在 `.zshrc` 中 source。

## opencode

`opencode/opencode.jsonc` → `~/.config/opencode/opencode.jsonc`

`opencode/claude-mem.settings.json` → `~/.claude-mem/settings.json`

`opencode/magic-context.jsonc` → `~/.config/cortexkit/magic-context.jsonc`

敏感信息(key、网关地址)一律以 `<YOUR_*>` 占位符入库,部署时替换。

## python

`.condarc` 文件
