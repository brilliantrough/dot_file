#!/usr/bin/env bash
# linux-setup.sh — 一键 zsh + oh-my-zsh + 插件 + tmux + 配置文件(brilliantrough/dot_file)
# 用法:bash linux-setup.sh   (交互确认 + 幂等;已存在的配置覆盖前存 .bak)
#
# 干什么:
#   0. 代理提醒(直连 GitHub 常失败,建议先 export http_proxy/https_proxy)
#   0.5 提权检查:root 可直接跑;普通用户检测 sudo 免密,可选一键写入 /etc/sudoers.d 配置 NOPASSWD
#   0.6 apt 源检查:仍是官方默认源则提醒换清华/南大镜像(不代改,只给网址)
#   1. 系统包:zsh tmux git wget(必需)+ vim neovim autojump ca-certificates(可选,缺才装,征求同意)
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
dlto() { # $1=url $2=dest(wget 优先,curl 兜底,均遵循 http(s)_proxy);超时防代理抖动时无限静默等待
  if command -v wget >/dev/null 2>&1; then wget -qT 30 -O "$2" "$1"; else curl -fsSL --connect-timeout 8 -m 60 -o "$2" "$1"; fi
}
# fetch <repo相对路径> <目标绝对路径> — 已存在征求覆盖(.bak 备份)
fetch() {
  local dest="$2"
  if [ -L "$dest" ]; then
    echo "跳过: $dest 是符号链接(指向 $(readlink "$dest")),不覆盖以免破坏链接目标"
    return 0
  fi
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

# ---- 0.5 提权检查(root / sudo 免密) ----
SUDO="sudo"; can_install=1
if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
  echo "以 root 运行:无需 sudo"
elif command -v sudo >/dev/null 2>&1; then
  if sudo -n true 2>/dev/null; then
    echo "sudo 免密已可用"
  elif ask "sudo 需要密码输入。是否配置免密 sudo(写入 /etc/sudoers.d/,期间需输入一次密码)?"; then
    sudoers_tmp="$(mktemp)"
    printf '%s ALL=(ALL) NOPASSWD:ALL\n' "$(id -un)" > "$sudoers_tmp"
    # 先 visudo 校验再落盘:坏的 sudoers 会锁死 sudo
    if sudo visudo -cf "$sudoers_tmp" >/dev/null 2>&1 \
       && sudo install -m 440 -o root -g root -- "$sudoers_tmp" "/etc/sudoers.d/99-$(id -un)-nopasswd"; then
      if sudo -n true 2>/dev/null; then
        echo "免密 sudo 已配置并即刻生效"
      else
        echo "WARN: 已写入但仍需密码,请检查 /etc/sudoers.d"
      fi
    else
      echo "WARN: 免密 sudo 配置失败(visudo 校验或写入失败),继续用密码 sudo"
    fi
    rm -f "$sudoers_tmp"
  fi
else
  SUDO=""; can_install=0
  echo "WARN: 非 root 且未安装 sudo,将跳过系统包安装" >&2
fi

# ---- 0.6 apt 源检查 ----
src_files=""
for f in /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; do
  if [ -f "$f" ]; then src_files="$src_files $f"; fi
done
if [ -n "$src_files" ]; then
  # 只看非注释行;deb822(.sources) 的 URIs: 行同样命中
  # shellcheck disable=SC2086
  if grep -qE '^[[:space:]]*[^#].*(deb\.debian\.org|security\.debian\.org|httpredir\.debian\.org|archive\.ubuntu\.com|security\.ubuntu\.com|ports\.ubuntu\.com)' $src_files 2>/dev/null; then
    echo "提醒: apt 仍是官方默认源(国内访问慢、易超时失败)。建议先换国内镜像源再继续:"
    echo "  清华(含各发行版帮助页): https://mirrors.tuna.tsinghua.edu.cn/help/ubuntu/  |  .../help/debian/"
    echo "  南大: https://mirror.nju.edu.cn/"
    echo "  (脚本不代改源:发行版/版本代号与 deb822 格式差异大,改错会锁死 apt;换完重跑本脚本)"
    ask "仍是默认源,继续吗?" || exit 1
  else
    echo "apt 源: 非官方默认源(已换源或自定义)"
  fi
fi

# ---- 1. 系统包 ----
req=""; opt=""
for p in zsh tmux git wget; do
  command -v "$p" >/dev/null 2>&1 || req="$req $p"
done
command -v vim      >/dev/null 2>&1 || opt="$opt vim"
command -v nvim     >/dev/null 2>&1 || opt="$opt neovim"
command -v autojump >/dev/null 2>&1 || opt="$opt autojump"
if [ "$can_install" -eq 0 ]; then
  if [ -n "$req$opt" ]; then
    echo "跳过系统包安装(无提权),请手动安装:$req $opt"
  fi
elif [ -n "$req$opt" ]; then
  if ask "缺少系统包:$req $opt。用 apt-get 安装?(含 ca-certificates)"; then
    $SUDO apt-get update
    # req 与 opt 分开装:否则某个可选包(如 neovim/autojump)不在 apt 源里时,
    # apt 会因 "Unable to locate package" 整批失败,连 zsh 都装不上
    if [ -n "$req" ]; then
      # shellcheck disable=SC2086
      $SUDO apt-get install -y $req ca-certificates
    fi
    if [ -n "$opt" ]; then
      # shellcheck disable=SC2086
      $SUDO apt-get install -y $opt || echo "WARN: 可选包安装失败(如 neovim/autojump 不在 apt 源里),不影响后续"
    fi
  else
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
