#!/usr/bin/env bash
# linux-setup.sh — 一键 zsh + oh-my-zsh + 插件 + tmux + 配置文件(brilliantrough/dot_file)
# 用法:bash linux-setup.sh   (交互确认 + 幂等;已存在的配置覆盖前存 .bak)
#
# 干什么:
#   0. 代理提醒(直连 GitHub 常失败,建议先 export http_proxy/https_proxy)
#   1. 系统包:zsh tmux git wget autojump ca-certificates(缺才装,征求同意)
#   2. oh-my-zsh(--unattended) + 默认 shell 切 zsh
#   3. omz 插件:zsh-syntax-highlighting、zsh-autosuggestions
#   4. 配置文件:~/.zshrc ~/.aliases ~/.func ~/.tmux.conf ~/.tmux.conf.local
#      (.func 含 <YOUR_*> 占位符,装完记得填,见文末清单)
#
# opencode 三件套请用 brilliantrough/agent-skills 仓库的 opencode-setup.sh。

set -euo pipefail

RAW="https://raw.githubusercontent.com/brilliantrough/dot_file/master"

ask() { # 读 /dev/tty:curl|bash 时 stdin 是脚本管道,绝不能从 stdin 读,否则会吞掉脚本行
  local a=""
  # 不能加 2>/dev/null:read -p 的提示符写往 stderr,吞掉后提示不可见,脚本像卡死
  if { [ -t 0 ] || [ -e /dev/tty ]; } && read -r -p "$1 [y/N] " a < /dev/tty; then
    [[ "$a" =~ ^[Yy]$ ]]
  else
    false  # 非交互环境一律默认否
  fi
}
dlto() { # $1=url $2=dest(wget 优先,curl 兜底,均遵循 http(s)_proxy)
  if command -v wget >/dev/null 2>&1; then wget -qO "$2" "$1"; else curl -fsSL -o "$2" "$1"; fi
}
# fetch <repo相对路径> <目标绝对路径> — 已存在征求覆盖(.bak 备份)
fetch() {
  local dest="$2"
  if [ -f "$dest" ]; then
    ask "$dest 已存在,用 dot_file 仓库版本覆盖?(原文件存为 $dest.bak)" || return 0
    cp "$dest" "$dest.bak"
  fi
  dlto "$RAW/$1" "$dest" && echo "fetched: $dest"
}

echo "== linux 环境一键配置(zsh / oh-my-zsh / tmux)=="

# ---- 0. 代理提醒 ----
proxy="${http_proxy:-${https_proxy:-${all_proxy:-}}}"
if [ -n "$proxy" ]; then
  echo "代理: $proxy"
else
  echo "提醒: 未检测到代理环境变量。直连 GitHub 经常失败,建议先 export http_proxy/https_proxy 再继续。"
  ask "没有代理也继续吗?" || exit 1
fi

# ---- 1. 系统包 ----
missing=""
for p in zsh tmux git wget; do
  command -v "$p" >/dev/null 2>&1 || missing="$missing $p"
done
command -v autojump >/dev/null 2>&1 || missing="$missing autojump"
if [ -n "$missing" ]; then
  if ask "缺少系统包:$missing。用 apt-get 安装?(含 ca-certificates)"; then
    sudo apt-get update
    # shellcheck disable=SC2086
    sudo apt-get install -y $missing ca-certificates  else
    echo "跳过安装;后续步骤可能失败"
  fi
fi

# ---- 2. oh-my-zsh ----
if [ -d "$HOME/.oh-my-zsh" ]; then
  echo "oh-my-zsh 已存在,跳过安装"
elif ask "安装 oh-my-zsh?(--unattended,并把默认 shell 切到 zsh)"; then
  # mktemp 而非固定 /tmp 路径:fs.protected_regular=2 时,粘滞目录(/tmp)里
  # 改写他人属主的已存在文件会 EACCES,root 也不豁免;临时文件属主必是自己
  omz_install="$(mktemp)"
  # raw.githubusercontent.com 被墙时回退官方镜像 install.ohmyz.sh(README 推荐)
  dlto https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh "$omz_install" 2>/dev/null \
    || dlto https://install.ohmyz.sh/ "$omz_install"
  # ZSH 显式指定:防止继承环境里已有的 ZSH 变量指去别处
  ZSH="$HOME/.oh-my-zsh" sh "$omz_install" --unattended
  rm -f "$omz_install"
  chsh -s "$(command -v zsh)" 2>/dev/null || echo "chsh 未完成(可能需要密码),可手动: chsh -s \$(which zsh)"
fi

# ---- 3. omz 插件 ----
if [ -d "$HOME/.oh-my-zsh/custom/plugins" ]; then
  for repo in zsh-users/zsh-syntax-highlighting zsh-users/zsh-autosuggestions; do
    dest="$HOME/.oh-my-zsh/custom/plugins/${repo##*/}"
    if [ -d "$dest" ]; then
      echo "插件已存在,跳过: ${dest##*/}"
    else
      git clone --depth=1 "https://github.com/$repo.git" "$dest"
    fi
  done
fi

# ---- 4. 配置文件 ----
fetch zsh/.zshrc "$HOME/.zshrc"
fetch zsh/.aliases "$HOME/.aliases"
fetch zsh/.func "$HOME/.func"
fetch tmux/.tmux.conf "$HOME/.tmux.conf"
fetch tmux/.tmux.conf.local "$HOME/.tmux.conf.local"

# ---- 完成 ----
echo ""
echo "== done. 注意事项 =="
echo "1. ~/.func 含 <YOUR_*> 占位符(已加引号,可直接 source;填真实值后 set_claude_env 才可用)"
echo "2. exec zsh 或重新登录生效;.zshrc 会自动 source ~/.aliases 和 ~/.func"
echo "3. opencode 三件套(claude-mem/magic-context/ponytail/notify): 用 brilliantrough/agent-skills 仓库的 opencode-setup.sh"
