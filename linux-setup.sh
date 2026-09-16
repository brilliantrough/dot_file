#!/usr/bin/env bash
# linux-setup.sh — 一键 zsh + oh-my-zsh + 插件 + tmux + 配置文件(仅面向 Debian/Ubuntu 系,apt)
# 用法:bash linux-setup.sh   (交互确认 + 幂等;已存在的配置覆盖前存 .bak)
# 询问默认:装缺的软件/插件、部署配置 → [Y/n](回车即装);覆盖已有配置、配置免密 sudo、
#          无代理或仍是默认源下继续 → [y/N](回车即跳过);非交互环境按各自默认执行
#
# 干什么:
#   0. 代理提醒(大小写的 http(s)_proxy/all_proxy 都查;未设则探测直连,透明代理不拦)
#   0.5 提权检查:root 可直接跑;普通用户检测 sudo 免密,可选一键写入 /etc/sudoers.d 配置 NOPASSWD
#   0.6 apt 源检查:仍是官方默认源则提醒换清华/南大镜像(不代改,只给网址)
#   1. 系统包:zsh tmux git wget(必需)+ vim neovim autojump make python3-pip ca-certificates(可选,缺才装)
#   1.5 openssh:缺 sshd 则装 openssh-server 并尝试设为开机自启(部分发行版/镜像默认不装)
#   1.6 用户级运行时:uv(+Python 3.9~3.13)、fnm(+Node LTS)、bun(无需 sudo;提前装好,opencode-setup.sh 即可直接通过)
#   2. oh-my-zsh(--unattended) + 默认 shell 切 zsh
#   3. omz 插件:zsh-syntax-highlighting、zsh-autosuggestions
#   4. 配置文件:~/.zshrc ~/.aliases ~/.func ~/.tmux.conf ~/.tmux.conf.local ~/.condarc(清华源)
#      (.func 含 <YOUR_*> 占位符,装完记得填,见文末清单)
#   5. tmux 插件管理器 tpm(+插件)
#   6. ripgrep:有 sudo 走 apt,否则 GitHub 二进制到 ~/.local/bin
#   7. mihomo:按架构下载二进制到 ~/.local/bin(不做全局安装)
#   8. LunarVim(需 nvim>=0.9)+ 部署 lvim 配置到 ~/.config/lvim
#      — 6/7/8 是「装软件」:无提权(can_install=0)时跳过;4/5 只动用户目录,始终执行
#
# opencode 三件套请用 brilliantrough/agent-skills 仓库的 opencode-setup.sh。

set -euo pipefail

RAW="https://raw.githubusercontent.com/brilliantrough/dot_file/master"

ask() { # $1=提示 $2=默认(Y/N,缺省 N)
  local a="" def="${2:-N}" hint="y/N"
  [ "$def" = Y ] && hint="Y/n"
  # 不能加 2>/dev/null:read -p 的提示符写往 stderr,吞掉后提示不可见,脚本像卡死
  # 读 /dev/tty:curl|bash 时 stdin 是脚本管道,绝不能从 stdin 读,否则会吞掉脚本行
  if { [ -t 0 ] || [ -e /dev/tty ]; } && read -r -p "$1 [$hint] " a < /dev/tty; then
    if [ -z "$a" ]; then [ "$def" = Y ]; else [[ "$a" =~ ^[Yy]$ ]]; fi
  else
    [ "$def" = Y ]  # 非交互(无 tty):按该询问的默认值
  fi
}
dlto() { # $1=url $2=dest(wget 优先,curl 兜底,均遵循 http(s)_proxy);超时防代理抖动时无限静默等待
  if command -v wget >/dev/null 2>&1; then wget -qT 30 -O "$2" "$1"; else curl -fsSL --connect-timeout 8 -m 60 -o "$2" "$1"; fi
}
# run_installer <url> <sh|bash> [args...] — 先下载再执行(直接 curl|sh 时 curl 失败会被 sh 静默吞掉)
run_installer() {
  local url="$1" sh="$2"; shift 2
  local tmp
  tmp="$(mktemp)"
  if curl -fsSL --connect-timeout 8 -m 60 -o "$tmp" "$url"; then
    "$sh" "$tmp" "$@" || echo "WARN: 安装脚本退出码非 0: $url"
  else
    echo "WARN: 安装脚本下载失败(检查代理): $url"
  fi
  rm -f "$tmp"
}
# _commit <已下载临时文件> <目标> — 与现有内容相同则不动(幂等);不同才先存 .bak 再写
_commit() {
  local tmp="$1" dest="$2"
  if [ -L "$dest" ]; then
    echo "跳过: $dest 是符号链接(指向 $(readlink "$dest")),不覆盖以免破坏链接目标"
    return 0
  fi
  if [ -f "$dest" ] && cmp -s "$tmp" "$dest"; then echo "unchanged: $dest"; return 0; fi
  if [ -f "$dest" ]; then cp "$dest" "$dest.bak"; fi
  cat "$tmp" > "$dest"
  echo "fetched: $dest"
}
# fetch <repo相对路径> <目标绝对路径> — 内容有变才征求覆盖(.bak 备份);一致则静默跳过
fetch() {
  local rel="$1" dest="$2" tmp
  if [ -L "$dest" ]; then
    echo "跳过: $dest 是符号链接(指向 $(readlink "$dest")),不覆盖以免破坏链接目标"
    return 0
  fi
  tmp="$(mktemp)"
  if ! dlto "$RAW/$rel" "$tmp"; then
    rm -f "$tmp"; echo "WARN: $rel 下载失败,保留现有 $dest" >&2; return 0
  fi
  if [ -f "$dest" ] && ! cmp -s "$tmp" "$dest"; then
    ask "$dest 已存在,用 dot_file 仓库版本覆盖?(原文件存为 $dest.bak)" || { rm -f "$tmp"; return 0; }
  fi
  _commit "$tmp" "$dest"
  rm -f "$tmp"
}

echo "== linux 环境一键配置(zsh / oh-my-zsh / tmux)=="

# ---- 0. 代理提醒 ----
# 大小写都查;无代理环境变量时再探测直连(排除路由器层透明代理的情况)
proxy="${http_proxy:-${https_proxy:-${all_proxy:-${HTTP_PROXY:-${HTTPS_PROXY:-${ALL_PROXY:-}}}}}}"
net_ok() {
  if command -v curl >/dev/null 2>&1; then curl -fsSI --connect-timeout 5 -m 8 -o /dev/null https://github.com
  else wget -q --spider -T 8 https://github.com; fi
}
if [ -n "$proxy" ]; then
  echo "代理: $proxy"
elif net_ok 2>/dev/null; then
  echo "未设代理环境变量,但直连 github.com 可达(可能是透明代理),继续"
else
  echo "提醒: 未检测到代理环境变量(大小写的 http(s)_proxy / all_proxy 都查了),且直连 github.com 不通。"
  echo "      建议先 export http_proxy/https_proxy 再继续;有透明代理则可忽略。"
  ask "仍要继续吗?" || exit 1
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
  # 覆盖两种格式:传统 one-line(/etc/apt/sources.list 与 *.list)
  # 和 deb822(Ubuntu 24.04+/26.04「resolute」、Debian 12+ 的 *.sources,看 URIs: 行)
  # 排除 security 行:镜像站帮助明确建议 security 源保持官方,故它是否官方不代表没换源
  # shellcheck disable=SC2086
  active="$(grep -hE '^[[:space:]]*[^#]' $src_files 2>/dev/null | grep -viE 'security' || true)"
  if printf '%s\n' "$active" | grep -qE '(deb\.debian\.org|httpredir\.debian\.org|archive\.ubuntu\.com|ports\.ubuntu\.com)'; then
    echo "提醒: apt 主源仍是官方默认源(国内访问慢、易超时失败)。建议换国内镜像源再继续:"
    echo "  清华: https://mirrors.tuna.tsinghua.edu.cn/help/ubuntu/  (Debian: .../help/debian/)"
    echo "  南大: https://mirror.nju.edu.cn/help/ubuntu/            (Debian: .../help/debian/)"
    echo "  注: Ubuntu 24.04+/26.04(代号 resolute)的源在 /etc/apt/sources.list.d/ubuntu.sources"
    echo "      (deb822 格式,改 URIs:),Debian 12+ 同理是 debian.sources。脚本不代改源(改错会锁死 apt)。"
    ask "仍是默认源,继续吗?" || exit 1
  else
    echo "apt 源: 非官方主源(已换源或自定义)"
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
command -v make     >/dev/null 2>&1 || opt="$opt make"
command -v pip3     >/dev/null 2>&1 || opt="$opt python3-pip"
if [ "$can_install" -eq 0 ]; then
  if [ -n "$req$opt" ]; then
    echo "跳过系统包安装(无提权),请手动安装:$req $opt"
  fi
elif [ -n "$req$opt" ]; then
  if ask "缺少系统包:$req $opt。用 apt-get 安装?(含 ca-certificates)" Y; then
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

# ---- 1.5 openssh(部分发行版/容器镜像默认不装服务端,缺 sshd 就无法远程登录)----
ssh_pkgs=""
[ -x /usr/sbin/sshd ] || command -v sshd >/dev/null 2>&1 || ssh_pkgs="openssh-server"
command -v ssh >/dev/null 2>&1 || ssh_pkgs="$ssh_pkgs openssh-client"
if [ -z "$ssh_pkgs" ]; then
  echo "openssh 已存在(server + client)"
elif [ "$can_install" -eq 0 ]; then
  echo "跳过 openssh 安装(无提权),请手动安装:$ssh_pkgs"
elif ask "未检测到:$ssh_pkgs。安装 openssh(sshd 会尝试设为开机自启)?" Y; then
  # shellcheck disable=SC2086
  if $SUDO apt-get install -y $ssh_pkgs; then
    if [ -x /usr/sbin/sshd ] || command -v sshd >/dev/null 2>&1; then
      if command -v systemctl >/dev/null 2>&1; then
        # Debian/Ubuntu 单元名是 ssh,RHEL 系是 sshd,都试一遍
        $SUDO systemctl enable --now ssh 2>/dev/null || $SUDO systemctl enable --now sshd 2>/dev/null \
          || echo "WARN: openssh-server 已装,但 systemctl 起不来(容器内无 systemd 时需手动启 sshd)"
      else
        echo "openssh-server 已装(无 systemd,需自行启动 sshd)"
      fi
    fi
  else
    echo "WARN: openssh 安装失败"
  fi
else
  echo "跳过 openssh 安装(用户拒绝);拿到 sudo 后可重跑"
fi

# ---- 1.6 用户级运行时:uv / fnm(+Node LTS)/ bun(无需 sudo;opencode-setup.sh 依赖它们) ----
if command -v uv >/dev/null 2>&1 || [ -x "$HOME/.local/bin/uv" ]; then
  echo "uv 已存在,跳过"
elif ask "安装 uv(python 包/项目管理器)?" Y; then
  run_installer https://astral.sh/uv/install.sh sh --no-modify-path
fi
# 常用 Python 版本(uv 管理;已装的会跳过)
if command -v uv >/dev/null 2>&1 || [ -x "$HOME/.local/bin/uv" ]; then
  uv_bin="$(command -v uv 2>/dev/null || echo "$HOME/.local/bin/uv")"
  if ask "用 uv 安装常用 Python 版本 3.9~3.13?" Y; then
    "$uv_bin" python install 3.9 3.10 3.11 3.12 3.13 \
      || echo "WARN: 部分 Python 版本安装失败(可单独重跑: uv python install 3.12)"
  fi
fi

if command -v fnm >/dev/null 2>&1 || [ -x "$HOME/.local/share/fnm/fnm" ]; then
  echo "fnm 已存在,跳过"
elif ask "安装 fnm + Node LTS?" Y; then
  run_installer https://fnm.vercel.app/install bash --skip-shell
fi
# fnm 在但缺 Node:补一个 LTS(--skip-shell 不写 shell 配置,~/.zshrc 里已有 fnm 初始化)
if [ -x "$HOME/.local/share/fnm/fnm" ] || command -v fnm >/dev/null 2>&1; then
  export PATH="$HOME/.local/share/fnm:$PATH"
  eval "$(fnm env)" 2>/dev/null || true
  if ! command -v node >/dev/null 2>&1; then
    fnm install --lts && fnm default lts-latest && eval "$(fnm env)" \
      || echo "WARN: Node LTS 安装失败"
  fi
fi

if command -v bun >/dev/null 2>&1 || [ -x "$HOME/.bun/bin/bun" ]; then
  echo "bun 已存在,跳过"
elif ask "安装 bun?" Y; then
  run_installer https://bun.sh/install bash
fi

# ---- 2. oh-my-zsh ----
if [ -d "$HOME/.oh-my-zsh" ]; then
  echo "oh-my-zsh 已存在,跳过安装"
elif ask "安装 oh-my-zsh?(--unattended,并把默认 shell 切到 zsh)" Y; then
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
fetch python/.condarc "$HOME/.condarc"

# ---- 5. tmux 插件管理器 tpm(用户级,无需 sudo) ----
if ! command -v tmux >/dev/null 2>&1; then
  echo "跳过 tpm:未安装 tmux"
elif [ -d "$HOME/.tmux/plugins/tpm" ]; then
  echo "tpm 已存在,跳过"
elif ask "安装 tmux 插件管理器 tpm(并装 .tmux.conf 里声明的插件)?" Y; then
  git clone --depth=1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" \
    || echo "WARN: tpm clone 失败(检查代理)"
fi
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
  # gpakosz/.tmux 不走上游 tpm 的 conf 钩子,直接跑 tpm 会因 TMUX_PLUGIN_MANAGER_PATH 未设而 abort。
  # 且必须起一个 session 让 server 活着——否则 server 无 session 会立刻退出,set-environment 丢失。
  tmux new-session -d -s _tpm_boot 2>/dev/null || true
  tmux set-environment -g TMUX_PLUGIN_MANAGER_PATH "$HOME/.tmux/plugins" 2>/dev/null || true
  "$HOME/.tmux/plugins/tpm/bin/install_plugins" >/dev/null 2>&1 \
    || echo "WARN: tpm 插件安装未完成,进 tmux 后按 prefix + I 重试"
  tmux kill-session -t _tpm_boot 2>/dev/null || true
fi

# ---- 6. ripgrep:有提权走 apt,否则 GitHub musl 二进制到 ~/.local/bin ----
rg_ok=0
if command -v rg >/dev/null 2>&1; then
  echo "ripgrep 已存在: $(command -v rg)"; rg_ok=1
elif [ "$can_install" -eq 1 ] && ask "安装 ripgrep(apt)?" Y; then
  if $SUDO apt-get install -y ripgrep; then rg_ok=1; else echo "WARN: apt 装 ripgrep 失败,改走二进制"; fi
fi
if [ "$rg_ok" -eq 0 ]; then
  case "$(uname -m)" in
    x86_64|amd64)  rg_target=x86_64-unknown-linux-musl ;;
    aarch64|arm64) rg_target=aarch64-unknown-linux-musl ;;
    armv7l|armv7)  rg_target=armv7-unknown-linux-gnueabihf ;;
    *)             rg_target="" ;;
  esac
  if [ -z "$rg_target" ]; then
    echo "WARN: 未知架构 $(uname -m),跳过 ripgrep 二进制"
  elif ask "从 GitHub 下载 ripgrep($rg_target) 到 ~/.local/bin?" Y; then
    rg_tag="$(curl -fsSLI -o /dev/null -w '%{url_effective}' --connect-timeout 8 -m 30 https://github.com/BurntSushi/ripgrep/releases/latest 2>/dev/null | sed 's#.*/##')"
    rg_tmp="$(mktemp)"; rg_dir="$(mktemp -d)"
    if [ -n "$rg_tag" ] && curl -fsSL --connect-timeout 8 -m 180 -o "$rg_tmp" \
         "https://github.com/BurntSushi/ripgrep/releases/download/${rg_tag}/ripgrep-${rg_tag}-${rg_target}.tar.gz"; then
      mkdir -p "$HOME/.local/bin"
      if tar -xzf "$rg_tmp" -C "$rg_dir" \
         && install -m 755 "$rg_dir/ripgrep-${rg_tag}-${rg_target}/rg" "$HOME/.local/bin/rg"; then
        echo "installed: $HOME/.local/bin/rg($rg_tag)"
      else
        echo "WARN: ripgrep 解压/安装失败"
      fi
    else
      echo "WARN: ripgrep 下载失败(检查代理)"
    fi
    rm -rf "$rg_tmp" "$rg_dir"
  fi
fi

# ---- 7. mihomo:按架构下二进制到 ~/.local/bin(不做全局安装) ----
if command -v mihomo >/dev/null 2>&1 || [ -x "$HOME/.local/bin/mihomo" ]; then
  echo "mihomo 已存在,跳过"
else
  case "$(uname -m)" in
    x86_64|amd64)  mh_arch=amd64 ;;  # 新 CPU 用 amd64;老 CPU 若 SIGILL 再换 amd64-compatible
    aarch64|arm64) mh_arch=arm64 ;;
    armv7l|armv7)  mh_arch=armv7 ;;
    i386|i686)     mh_arch=386 ;;
    riscv64)       mh_arch=riscv64 ;;
    ppc64le)       mh_arch=ppc64le ;;
    s390x)         mh_arch=s390x ;;
    *)             mh_arch="" ;;
  esac
  if [ -z "$mh_arch" ]; then
    echo "WARN: 未知架构 $(uname -m),跳过 mihomo"
  elif ask "下载 mihomo($mh_arch) 到 ~/.local/bin?" Y; then
    mh_tag="$(curl -fsSLI -o /dev/null -w '%{url_effective}' --connect-timeout 8 -m 30 https://github.com/MetaCubeX/mihomo/releases/latest 2>/dev/null | sed 's#.*/##')"
    mh_tmp="$(mktemp)"
    if [ -n "$mh_tag" ] && curl -fsSL --connect-timeout 8 -m 300 -o "$mh_tmp" \
         "https://github.com/MetaCubeX/mihomo/releases/download/${mh_tag}/mihomo-linux-${mh_arch}-${mh_tag}.gz"; then
      mkdir -p "$HOME/.local/bin"
      if gunzip -c "$mh_tmp" > "$HOME/.local/bin/mihomo" && chmod 755 "$HOME/.local/bin/mihomo"; then
        echo "installed: $HOME/.local/bin/mihomo($mh_tag)"
      else
        echo "WARN: mihomo 解压失败"
      fi
    else
      echo "WARN: mihomo 下载失败(检查代理)"
    fi
    rm -f "$mh_tmp"
  fi
fi

# ---- 8. LunarVim(需 nvim>=0.9;用户级安装,但属「装软件」,无提权则跳过) ----
if [ -x "$HOME/.local/bin/lvim" ]; then
  echo "lvim 已存在,跳过安装"
elif [ "$can_install" -eq 0 ]; then
  echo "跳过 LunarVim 安装(无提权;拿到 sudo 后重跑)"
elif ! command -v nvim >/dev/null 2>&1; then
  echo "WARN: 未找到 nvim,跳过 LunarVim(需要 Neovim>=0.9)"
elif ! nvim --headless -u NONE -c 'if !has("nvim-0.9") | cquit | endif | q' 2>/dev/null; then
  echo "WARN: 系统 nvim < 0.9(apt 版常过旧),LunarVim 1.4 需 0.9.x,跳过"
  echo "      先装新版 nvim 再重跑: https://github.com/neovim/neovim/releases"
elif ask "安装 LunarVim(release-1.4/neovim-0.9,联网拉插件,较慢)?"; then
  lv_sh="$(mktemp)"
  if curl -fsSL --connect-timeout 8 -m 60 -o "$lv_sh" \
       https://raw.githubusercontent.com/LunarVim/LunarVim/release-1.4/neovim-0.9/utils/installer/install.sh; then
    LV_BRANCH='release-1.4/neovim-0.9' bash "$lv_sh" --yes \
      || echo "WARN: LunarVim 安装器退出码非 0(可手动重跑)"
  else
    echo "WARN: LunarVim 安装脚本下载失败(检查代理)"
  fi
  rm -f "$lv_sh"
fi

# LunarVim 配置部署(无 sudo;须在安装之后——安装器会重建 ~/.config/lvim)
if [ -x "$HOME/.local/bin/lvim" ] || [ -d "$HOME/.config/lvim" ]; then
  if ask "部署 lvim 配置到 ~/.config/lvim(原文件存 .bak)?" Y; then
    mkdir -p "$HOME/.config/lvim"
    for f in config.lua lv-settings.lua lazy-lock.json my_config.lua my_keymap.lua my_onedark.lua my_playground.lua my_surround.lua; do
      dest="$HOME/.config/lvim/$f"
      tmp="$(mktemp)"
      if dlto "$RAW/lvim/$f" "$tmp"; then _commit "$tmp" "$dest"; else echo "WARN: lvim/$f 拉取失败"; fi
      rm -f "$tmp"
    done
    if [ -x "$HOME/.local/bin/lvim" ]; then
      "$HOME/.local/bin/lvim" --headless -c 'Lazy! sync' -c 'qa' >/dev/null 2>&1 \
        || echo "WARN: lvim 插件同步未完成,首次启动 lvim 时会自动补"
    fi
  fi
fi

# ---- 完成 ----
echo ""
echo "== done. 注意事项 =="
echo "1. ~/.func 含 <YOUR_*> 占位符(已加引号,可直接 source;填真实值后 set_claude_env 才可用)"
echo "2. exec zsh 或重新登录生效;.zshrc 会自动 source ~/.aliases 和 ~/.func"
echo "3. opencode 三件套(claude-mem/magic-context/ponytail/notify): 用 brilliantrough/agent-skills 仓库的 opencode-setup.sh"
echo "4. ripgrep / mihomo / lvim 装在 ~/.local/bin(.zshrc 已加进 PATH);mihomo 首次运行前需自备 config.yaml"
echo "5. LunarVim 需 nvim>=0.9;apt 版过旧会跳过,自行装新版 nvim 后重跑即可"
