# 关于

此仓库用来存储 Linux 系统中的一些配置文件，通常这些配置文件都是以点开头的隐藏文件。

## 一键配置

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/brilliantrough/dot_file/master/linux-setup.sh)"
```

脚本做的事（**仅面向 Debian/Ubuntu 系,apt**；交互确认 + 幂等；配置覆盖前存 `.bak`）：

询问默认：装缺的软件/插件、部署配置 → `[Y/n]`（回车即装）；覆盖已有配置、配置免密 sudo、无代理或仍是默认源下继续 → `[y/N]`。

| 步骤 | 内容 |
|---|---|
| 0 | 代理提醒；提权检查（root 直接用；普通用户可选一键配置 sudo 免密）；apt 源检查（仍是官方源则提示换清华/南大镜像） |
| 1 | 系统包：`zsh tmux git wget`（必需）+ `vim neovim autojump make python3-pip ca-certificates`（可选） |
| 1.5 | openssh：缺 `sshd` 则装 `openssh-server` 并尝试设为开机自启（部分发行版/容器镜像默认不装） |
| 1.6 | 用户级运行时：`uv`（+ Python 3.9~3.13）、`fnm`（+Node LTS）、`bun`。提前装好，agent-skills 的 `opencode-setup.sh` 即可直接通过 |
| 2-3 | oh-my-zsh（`--unattended`，切默认 shell）+ 插件 zsh-syntax-highlighting / zsh-autosuggestions |
| 4 | 部署 `~/.zshrc` `~/.aliases` `~/.func` `~/.tmux.conf` `~/.tmux.conf.local` `~/.condarc` |
| 5 | tmux 插件管理器 tpm（+ 按 `.tmux.conf` 安装插件） |
| 6 | ripgrep：有 sudo 走 apt，否则从 GitHub 下 musl 二进制到 `~/.local/bin` |
| 7 | mihomo：按架构下二进制到 `~/.local/bin`（不做全局安装） |
| 8 | LunarVim（需 nvim>=0.9）+ 部署 lvim 配置到 `~/.config/lvim` |

无 sudo 时跳过「装软件」的步骤（1 的 apt 安装、8 的 LunarVim），但第 4/5 步与 6/7 的二进制下载只动用户目录，照常执行。国内网络建议先 `export http_proxy/https_proxy`。

## tmux

`.tmux.conf` 和 `.tmux.conf.local`，并由脚本安装 tpm 与其中声明的插件。

## neovim

`init.vim` 和 `coc-settings.json`（vim-plug + coc 的旧配置，仅存档；脚本不部署——现在主要用 lvim）。

## lvim

LunarVim 配置（部署到 `~/.config/lvim/`）。脚本第 8 步会安装 LunarVim（`release-1.4/neovim-0.9`）并部署这些文件；若系统 nvim < 0.9 会跳过安装，但仍部署配置。

手动部署：

```bash
mkdir -p ~/.config/lvim && cp -r lvim/* ~/.config/lvim/
```

## python

`.condarc` → `~/.condarc`（清华源），由脚本部署。

## zsh

`.zshrc` 保持通用配置;个人函数、别名拆在 `.func` 和 `.aliases`,部署到 `~/.func`、`~/.aliases`,并在 `.zshrc` 中 source。

## opencode

`opencode/opencode.json` → `~/.config/opencode/opencode.json`（脚本每次运行按模板覆盖各 provider 的 models,apiKey 等本地字段保留）

`opencode/claude-mem.settings.json` → `~/.claude-mem/settings.json`（`CLAUDE_MEM_PROVIDER=openrouter` 走的是 **OpenAI 协议**：`POST <BASE_URL>/chat/completions` + `Authorization: Bearer <key>`，不是 Anthropic 的 `/v1/messages` + `x-api-key`。所以 `CLAUDE_MEM_OPENROUTER_API_KEY` 要填 **OpenAI 协议**的 key，`CLAUDE_MEM_OPENROUTER_BASE_URL` 填 OpenAI 兼容网关地址）

`opencode/magic-context.jsonc` → `~/.config/cortexkit/magic-context.jsonc`

敏感信息(key、网关地址)一律以 `<YOUR_*>` 占位符入库,部署时替换。

## docker

`docker/Dockerfile` —— 在项目方 base 镜像上叠加「系统级」软件：apt 包（zsh/tmux/git/openssh/neovim/autojump/ripgrep/python3…）+ `uv`/`fnm`/`bun`/`mihomo` 装到 `/usr/local`，并用 `uv` 预装 Python 3.9~3.13。

**关键原则（已实测）**：容器启动时会用 `-v <持久目录>:$HOME` 覆盖家目录做持久化 → 镜像里写在 `$HOME` 下的东西启动时会被挂载**遮蔽（mask）**，等于白装。所以镜像只装 `/usr`、`/usr/local`；凡是天然住在 `$HOME` 的（oh-my-zsh / tpm / LunarVim / dotfiles）都留到容器启动后再装，装进被挂载的家目录即持久化。

```bash
docker build -t myserver docker/          # 需要代理时:--build-arg https_proxy=http://host:7890
docker run -d --name srv -v /你的持久目录:/root myserver sleep infinity
# 首次在容器里做家目录配置(镜像里已有的软件会被自动跳过,只装 $HOME 内的东西)
docker exec -it srv zsh -lc 'bash <(curl -fsSL https://raw.githubusercontent.com/brilliantrough/dot_file/master/linux-setup.sh)'
```

opencode 三件套同理，在容器内跑 agent-skills 的 `opencode-setup.sh`。

## squid

`/etc/squid/squid.conf` 文件（已停用,仅存档）

## proxychains

`/etc/proxychains.conf` 文件（已停用,仅存档）
