#!/usr/bin/env bash
# linux-setup.sh — 一键 zsh + oh-my-zsh + 插件 + tmux + 配置文件(仅面向 Debian/Ubuntu 系,apt)
# 用法:bash linux-setup.sh   (交互确认 + 幂等;已存在的配置覆盖前存 .bak)
# 询问默认:装缺的软件/插件、部署配置 → [Y/n](回车即装);覆盖已有配置、配置免密 sudo、
#          无代理或仍是默认源下继续 → [y/N](回车即跳过);非交互环境按各自默认执行
#
# 干什么:
#   启动时始终配置 HF_ENDPOINT / HF_HUB_DISABLE_XET,不受后续步骤跳过影响
#   0. mihomo:每次检查程序、配置和数据文件;缺失则设置,本次退出,手动启动并 export 代理后重跑
#      配置链接可回车跳过,但文件未齐全时不会继续后续安装
#   0.1 代理提醒(大小写的 http(s)_proxy/all_proxy 都查;未设则探测直连,透明代理不拦)
#   0.5 提权检查:root 可直接跑;普通用户检测 sudo 免密,可选一键写入 /etc/sudoers.d 配置 NOPASSWD
#   0.6 apt 源检查:仍是官方默认源则提醒换清华/南大镜像(不代改,只给网址)
#   1. 系统包:zsh tmux git wget(必需)+ vim neovim autojump make python3-pip ca-certificates(可选,缺才装)
#   1.5 openssh:缺 sshd 则装 openssh-server 并尝试设为开机自启(部分发行版/镜像默认不装)
#   1.6 用户级运行时:uv(+Python 3.9~3.13、自升级、清华 PyPI 镜像)、fnm(+Node LTS)、bun(无需 sudo;提前装好,opencode-setup.sh 即可直接通过)
#   2. oh-my-zsh(--unattended) + 默认 shell 切 zsh
#   3. omz 插件:zsh-syntax-highlighting、zsh-autosuggestions
#   4. 配置文件:~/.zshrc ~/.aliases ~/.func ~/.tmux.conf ~/.tmux.conf.local ~/.condarc(清华源)
#      (.func 含 <YOUR_*> 占位符,装完记得填,见文末清单)
#   4.1 模型下载:uv 隔离安装 hf/modelscope;准备 /data、缓存、dl 与 bash/zsh 环境(不装训练框架)
#   5. tmux 插件管理器 tpm(+插件)
#   6. ripgrep:有 sudo 走 apt,否则 GitHub 二进制到 ~/.local/bin
#   7. LunarVim(需 nvim>=0.9)+ 部署 lvim 配置到 ~/.config/lvim
#      — mihomo 只动用户目录,无需提权;LunarVim 无提权(can_install=0)时跳过
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

# HF 镜像默认值始终配置,不依赖数据盘或工具安装;已有环境变量保留。
setup_hf_mirror() {
  local rc line existed
  export HF_ENDPOINT="${HF_ENDPOINT:-https://hf-mirror.com}"
  export HF_HUB_DISABLE_XET="${HF_HUB_DISABLE_XET:-1}"
  for rc in "$HOME/.bashrc" "${ZDOTDIR:-$HOME}/.zshrc"; do
    mkdir -p -- "$(dirname "$rc")" || return 1
    if { [ -e "$rc" ] || [ -L "$rc" ]; } && [ ! -f "$rc" ]; then
      echo "ERROR: $rc 不是有效配置文件,无法写入必需的 HF 镜像变量" >&2
      return 1
    fi
    existed=0
    [ -f "$rc" ] && existed=1
    for line in 'export HF_ENDPOINT="${HF_ENDPOINT:-https://hf-mirror.com}"' \
                'export HF_HUB_DISABLE_XET="${HF_HUB_DISABLE_XET:-1}"'; do
      if ! grep -Fxq "$line" "$rc" 2>/dev/null; then
        if [ "$existed" -eq 1 ] && [ ! -e "$rc.bak.hf-mirror" ] && [ ! -L "$rc.bak.hf-mirror" ]; then
          cp -pL -- "$rc" "$rc.bak.hf-mirror" || return 1
        fi
        printf '\n%s\n' "$line" >> "$rc" || return 1
      fi
    done
  done
}

echo "== linux 环境一键配置(zsh / oh-my-zsh / tmux)=="
setup_hf_mirror

# ---- 0. mihomo(在代理检查前准备;已有文件跳过,不自动启动) ----
mkdir -p "$HOME/.local/bin" "$HOME/.config/mihomo"
export PATH="$HOME/.local/bin:$PATH"

# mihomo_fetch <url> <目标> [.gz] — 缺失才下载;临时目录内完成下载/解压再落盘
mihomo_fetch() (
  local url="$1" dest="$2" suffix="${3:-}" tmp file
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    echo "已存在,跳过: $dest"
    return 0
  fi
  umask 077
  tmp="$(mktemp -d "$(dirname "$dest")/.mihomo-download.XXXXXX")"
  file="$tmp/${dest##*/}"
  echo "下载: $dest"
  if dlto "$url" "$file$suffix" && [ -s "$file$suffix" ]; then
    if [ "$suffix" = .gz ]; then
      if ! gzip -d "$file.gz" || ! chmod +x "$file"; then
        echo "WARN: mihomo 解压或授权失败,可重跑脚本" >&2
        rm -rf "$tmp"
        return 0
      fi
    fi
    if mv -n "$file" "$dest"; then
      echo "installed: $dest"
    else
      echo "WARN: 写入失败: $dest" >&2
    fi
  else
    echo "WARN: 下载失败: $dest(检查网络或链接是否失效,可重跑脚本)" >&2
  fi
  rm -rf "$tmp"
)

# 程序须可执行,配置及数据文件须非空;只检查文件,不自动启动代理。
mihomo_ready() {
  local bin file
  bin="$(command -v mihomo)" || return 1
  [ -f "$bin" ] && [ -s "$bin" ] && [ -x "$bin" ] || return 1
  for file in mihomo.yaml Country.mmdb geoip.dat; do
    [ -f "$HOME/.config/mihomo/$file" ] && [ -s "$HOME/.config/mihomo/$file" ] || return 1
  done
}

mh_setup_needed=0
mihomo_ready || mh_setup_needed=1

if command -v mihomo >/dev/null 2>&1 || [ -e "$HOME/.local/bin/mihomo" ] || [ -L "$HOME/.local/bin/mihomo" ]; then
  echo "mihomo 已存在,跳过二进制下载"
else
  mh_arch="$(dpkg --print-architecture 2>/dev/null || uname -m)"
  case "$mh_arch" in
    arm64|aarch64) mh_url='https://box.nju.edu.cn/seafhttp/f/471e33b95b6c411998be/?op=view' ;;
    amd64|x86_64)  mh_url='https://box.nju.edu.cn/seafhttp/f/c89f0d5d264542e9aab8/?op=view' ;;
    *)            mh_url=""; echo "WARN: 未提供 $mh_arch 的 mihomo 二进制,仅支持 arm64/amd64" >&2 ;;
  esac
  if [ -n "$mh_url" ]; then
    mihomo_fetch "$mh_url" "$HOME/.local/bin/mihomo" .gz
  fi
fi
mihomo_fetch 'https://box.nju.edu.cn/seafhttp/f/acf92c8fad9c4a5fbb41/?op=view' "$HOME/.config/mihomo/Country.mmdb"
mihomo_fetch 'https://box.nju.edu.cn/seafhttp/f/85a69447a51e4ec09819/?op=view' "$HOME/.config/mihomo/geoip.dat"

if [ -e "$HOME/.config/mihomo/mihomo.yaml" ] || [ -L "$HOME/.config/mihomo/mihomo.yaml" ]; then
  echo "mihomo.yaml 已存在,跳过配置下载"
else
  mh_config_url=""
  printf 'mihomo 配置文件下载链接(回车跳过): ' >&2
  if { read -r mh_config_url < /dev/tty; } 2>/dev/null && [ -n "$mh_config_url" ]; then
    case "$mh_config_url" in
      http://?*|https://?*) mihomo_fetch "$mh_config_url" "$HOME/.config/mihomo/mihomo.yaml" ;;
      *) echo "WARN: 配置链接须为 http:// 或 https://,跳过配置下载" >&2 ;;
    esac
  else
    echo "跳过 mihomo 配置下载(回车或无交互终端)"
  fi
fi
if ! mihomo_ready; then
  echo "ERROR: mihomo 尚未配置完整:程序须可执行,mihomo.yaml、Country.mmdb、geoip.dat 须非空。" >&2
  echo "本次退出,不执行后续安装。请处理上方错误或补齐 ~/.config/mihomo/mihomo.yaml 后重跑。" >&2
  exit 1
fi
if [ "$mh_setup_needed" -eq 1 ]; then
  echo "mihomo 设置完成。本次到此退出,请先启动代理,再重新运行本脚本。"
  echo "1. 在另一个终端或 tmux 中启动 mihomo(保持运行):"
  printf '   "%s" -d "%s" -f "%s"\n' "$(command -v mihomo)" "$HOME/.config/mihomo" "$HOME/.config/mihomo/mihomo.yaml"
  echo "2. 确认配置的 HTTP 或 mixed 端口是 7890,在运行本脚本的终端执行:"
  echo '   export http_proxy=http://localhost:7890 && export https_proxy=http://localhost:7890'
  echo "3. 重新运行 linux-setup.sh,继续后续安装。"
  exit 0
fi
echo "mihomo 程序、配置和数据文件已就绪,继续检查代理。"

# ---- 0.1 代理提醒 ----
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

# uv 自升级 + PyPI 镜像(国内;uv 按语义化版本读 ~/.config/uv/uv.toml)
if [ -n "${uv_bin:-}" ]; then
  uv_cur="$("$uv_bin" --version 2>/dev/null | awk '{print $2}' || true)"
  uv_latest="$(curl -fsSL --connect-timeout 5 -m 8 https://api.github.com/repos/astral-sh/uv/releases/latest 2>/dev/null \
    | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4 || true)"
  if [ -z "$uv_latest" ]; then
    echo "跳过 uv 自升级:查不到最新版本(检查网络/代理)"
  elif [ "$uv_latest" != "$uv_cur" ]; then
    if ask "uv ${uv_cur:-未知} → $uv_latest,升级(uv self update)?" Y; then
      "$uv_bin" self update || echo "WARN: uv 自升级失败(系统包管理器装的请用系统方式升级)" >&2
    fi
  else
    echo "uv 已是最新(${uv_cur:-未知})"
  fi
  uv_cfg="${XDG_CONFIG_HOME:-$HOME/.config}/uv/uv.toml"
  if grep -q 'pypi.tuna' "$uv_cfg" 2>/dev/null; then
    echo "uv PyPI 镜像已配置(清华),跳过"
  elif [ -e "$uv_cfg" ] || [ -L "$uv_cfg" ]; then
    echo "跳过 uv 镜像:$uv_cfg 已存在,保留本机配置"
  elif ask "配置 uv 用清华 PyPI 镜像($uv_cfg)?" Y; then
    mkdir -p "$(dirname "$uv_cfg")"
    printf '%s\n' 'index-url = "https://pypi.tuna.tsinghua.edu.cn/simple"' > "$uv_cfg"
    echo "wrote: $uv_cfg"
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
# 保留本地 .zshrc(上一步选了不覆盖)时提醒:里面没有 dot_file 的 PATH 块,uv/fnm/bun/pi 可能找不到
if [ -f "$HOME/.zshrc" ] && ! grep -q '>>> dot_file PATH >>>' "$HOME/.zshrc"; then
  echo "提示: $HOME/.zshrc 不含 dot_file 的 PATH 块——用仓库版本覆盖它,或把块粘进去(uv/fnm/bun/pnpm/pi/cargo/go)"
fi
fetch zsh/.aliases "$HOME/.aliases"
fetch zsh/.func "$HOME/.func"
fetch tmux/.tmux.conf "$HOME/.tmux.conf"
fetch tmux/.tmux.conf.local "$HOME/.tmux.conf.local"
fetch python/.condarc "$HOME/.condarc"
# 上面的 shell 配置可能被安装器或仓库模板替换,无条件补回镜像变量。
setup_hf_mirror

# ---- 4.1 模型 / 数据集下载(通用,不修改系统或训练环境里的 Python 包) ----
install_model_tools() {
  local package cli
  if [ -z "${uv_bin:-}" ]; then
    echo "WARN: 未安装 uv,跳过 hf/modelscope;装好 uv 后重跑" >&2
    return 0
  fi
  export PATH="${UV_TOOL_BIN_DIR:-$HOME/.local/bin}:$PATH"
  for package in huggingface_hub modelscope-hub; do
    if [ "$package" = huggingface_hub ]; then cli=hf; else cli=modelscope; fi
    if command -v "$cli" >/dev/null 2>&1; then
      echo "$cli 已存在,保留: $(command -v "$cli")"
    else
      UV_TOOL_BIN_DIR="${UV_TOOL_BIN_DIR:-$HOME/.local/bin}" \
        "$uv_bin" tool install --python 3.11 --managed-python "$package" \
        || echo "WARN: $package 安装失败,可重跑;不使用 pip 修改当前环境" >&2
    fi
  done
}

# 只接受与根盘不同的持久文件系统;不分区、不格式化、不修改 fstab。
model_data_disk() {
  [ -d "$1" ] || return 1
  [ "$(stat -Lc %d -- "$1")" != "$(stat -Lc %d /)" ] || return 1
  case "$(findmnt -n -o FSTYPE -T "$1")" in
    ''|tmpfs|ramfs|devtmpfs|squashfs|overlay) return 1 ;;
  esac
}

setup_model_storage() {
  local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/dot_file" env_file model_root candidate dir tmp rc hook sudo_dirs=0
  env_file="$config_dir/model-env.sh"
  if [ -e "$env_file" ] || [ -L "$env_file" ]; then
    [ -f "$env_file" ] || { echo "WARN: $env_file 不是可读取的配置文件" >&2; return 1; }
    . "$env_file" || return 1
  fi
  model_root="${DL_DATA_ROOT:-/data}"
  case "$model_root" in /*) ;; *) echo "WARN: DL_DATA_ROOT 必须是绝对路径" >&2; return 1 ;; esac
  if ! model_data_disk "$model_root"; then
    echo "提醒: $model_root 不存在或不在独立数据盘上,不会把模型写到系统盘。"
    df -hT -x tmpfs -x devtmpfs || true
    printf '已挂载大盘的绝对目录(回车跳过数据布局): ' >&2
    candidate=""
    if ! { read -r candidate < /dev/tty; } 2>/dev/null || [ -z "$candidate" ]; then return 1; fi
    case "$candidate" in /*) ;; *) echo "WARN: 必须提供已存在的绝对目录" >&2; return 1 ;; esac
    if ! model_data_disk "$candidate"; then
      echo "WARN: $candidate 不是已挂载的持久数据盘目录,未修改磁盘" >&2
      return 1
    fi
    candidate="$(realpath -e -- "$candidate")" || return 1
    df -hT -- "$candidate"
    if [ "$model_root" = /data ] && [ ! -e /data ] && [ ! -L /data ] && [ "$can_install" -eq 1 ]; then
      ask "创建 /data -> $candidate 的软链接?(不修改现有挂载)" || return 1
      $SUDO ln -sT -- "$candidate" /data || return 1
    else
      echo "保留现有 /data 和权限;本次数据目录使用 $candidate"
      model_root="$candidate"
    fi
  fi
  if [ -f "$env_file" ] && [ "$model_root" != "${DL_DATA_ROOT:-/data}" ]; then
    echo "WARN: 已有 $env_file 保留;请先把其中 DL_DATA_ROOT 改为 $model_root 后重跑" >&2
    return 1
  fi
  for dir in models datasets hub hub/hf hub/ms hub/uv logs; do
    dir="$model_root/$dir"
    if [ ! -e "$dir" ] && [ ! -L "$dir" ]; then
      if [ -w "$(dirname "$dir")" ]; then
        mkdir -- "$dir" || return 1
      elif [ "$can_install" -eq 1 ]; then
        if [ "$sudo_dirs" -eq 0 ]; then
          ask "用提权为当前用户创建缺少的数据子目录?(不修改已有目录属主或权限)" || return 1
          sudo_dirs=1
        fi
        $SUDO install -d -m 755 -o "$(id -u)" -g "$(id -g)" -- "$dir" || return 1
      else
        echo "WARN: 无权创建 $dir,请管理员准备后重跑" >&2
        return 1
      fi
    fi
    if [ ! -d "$dir" ] || [ ! -w "$dir" ]; then
      echo "WARN: $dir 不可写;保留现有权限,请管理员授权后重跑" >&2
      return 1
    fi
  done
  mkdir -p "$config_dir" "$HOME/.local/bin" || return 1
  if [ -e "$env_file" ] || [ -L "$env_file" ]; then
    echo "已有环境配置,保留: $env_file"
  else
    tmp="$(mktemp)" || return 1
    printf '# dot_file 模型下载默认值;已有环境变量优先。\n[ -n "${DL_DATA_ROOT:-}" ] || export DL_DATA_ROOT=%q\n' "$model_root" > "$tmp"
    cat >> "$tmp" <<'MODEL_ENV'
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
case ":$PATH:" in *":${UV_TOOL_BIN_DIR:-$HOME/.local/bin}:"*) ;; *) export PATH="${UV_TOOL_BIN_DIR:-$HOME/.local/bin}:$PATH" ;; esac
export HF_ENDPOINT="${HF_ENDPOINT:-https://hf-mirror.com}"
# 保留原 token 位置,不把登录凭据搬到共享数据缓存。
export HF_TOKEN_PATH="${HF_TOKEN_PATH:-${HF_HOME:-${XDG_CACHE_HOME:-$HOME/.cache}/huggingface}/token}"
export HF_HOME="${HF_HOME:-$DL_DATA_ROOT/hub/hf}"
export MODELSCOPE_CACHE="${MODELSCOPE_CACHE:-$DL_DATA_ROOT/hub/ms}"
export UV_CACHE_DIR="${UV_CACHE_DIR:-$DL_DATA_ROOT/hub/uv}"
export HF_HUB_DISABLE_XET="${HF_HUB_DISABLE_XET:-1}"
MODEL_ENV
    _commit "$tmp" "$env_file" || { rm -f "$tmp"; return 1; }
    rm -f "$tmp"
  fi
  if [ -e "$HOME/.local/bin/dl" ] || [ -L "$HOME/.local/bin/dl" ]; then
    echo "已有 ~/.local/bin/dl,保留;请确认它使用相同目录约定"
  else
    tmp="$(mktemp)" || return 1
    cat > "$tmp" <<'MODEL_DL'
#!/usr/bin/env bash
# dl <hf|ms> <org/repo> [--type model|dataset] [--name NAME]
set -euo pipefail
usage() { echo '用法: dl <hf|ms> <org/repo> [--type model|dataset] [--name NAME]'; }
die() { echo "错误: $*" >&2; exit 1; }
if [ "${1:-}" = --help ] || [ "${1:-}" = -h ]; then usage; exit 0; fi
[ $# -ge 2 ] || { usage >&2; exit 1; }
src="$1"; repo="$2"; shift 2
case "$src" in hf|ms) ;; *) die '平台只能是 hf 或 ms' ;; esac
[[ "$repo" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] && [[ "$repo" != -* ]] || die 'repo_id 应为 org/repo'
type=model; name="${repo//\//__}"
while [ $# -gt 0 ]; do
  case "$1" in
    --type|--name)
      [ $# -ge 2 ] && [ -n "$2" ] || die "$1 缺少参数"
      if [ "$1" = --type ]; then type="$2"; else name="$2"; fi
      shift 2 ;;
    *) die "未知参数: $1" ;;
  esac
done
case "$type" in model|dataset) ;; *) die '--type 只能是 model 或 dataset' ;; esac
[[ "$name" =~ ^[A-Za-z0-9_.-]+$ ]] && [ "$name" != . ] && [ "$name" != .. ] || die '--name 必须是单个目录名,不能包含路径'
env_file="${XDG_CONFIG_HOME:-$HOME/.config}/dot_file/model-env.sh"
[ -f "$env_file" ] || die '请先运行 linux-setup.sh 完成模型存储配置'
. "$env_file"
root="${DL_DATA_ROOT:-/data}"
case "$root" in /*) ;; *) die 'DL_DATA_ROOT 必须是绝对路径' ;; esac
[ -d "$root" ] && [ "$(stat -Lc %d -- "$root")" != "$(stat -Lc %d /)" ] || die '数据盘未就绪,拒绝向系统盘下载;检查挂载或 DL_DATA_ROOT'
case "$(findmnt -n -o FSTYPE -T "$root")" in ''|tmpfs|ramfs|devtmpfs|squashfs|overlay) die '数据目录不是持久数据盘' ;; esac
base="$root/${type}s"
[ -d "$base" ] && [ -w "$base" ] || die "$base 不存在或不可写,请先完成目录初始化"
dest="$base/$name"
if [ "$src" = hf ]; then cli=hf; else cli=modelscope; fi
command -v "$cli" >/dev/null 2>&1 || die "未安装 $cli,请重跑 linux-setup.sh"
mkdir -p -- "$dest"
printf '下载: %s -> %s\n' "$repo" "$dest"
"$cli" download "$repo" --repo-type "$type" --local-dir "$dest"
printf '完成: %s\n使用该绝对路径加载模型或数据集。\n' "$dest"
MODEL_DL
    _commit "$tmp" "$HOME/.local/bin/dl" || { rm -f "$tmp"; return 1; }
    chmod +x "$HOME/.local/bin/dl" || { rm -f "$tmp"; return 1; }
    rm -f "$tmp"
  fi
  hook='[ ! -f "${XDG_CONFIG_HOME:-$HOME/.config}/dot_file/model-env.sh" ] || . "${XDG_CONFIG_HOME:-$HOME/.config}/dot_file/model-env.sh"'
  for rc in "$HOME/.bashrc" "${ZDOTDIR:-$HOME}/.zshrc"; do
    if [ -L "$rc" ]; then
      echo "跳过符号链接 $rc;请在其目标文件末尾添加: $hook"
    elif ! grep -Fxq "$hook" "$rc" 2>/dev/null; then
      if [ -f "$rc" ] && [ ! -e "$rc.bak.models" ]; then cp -p -- "$rc" "$rc.bak.models" || return 1; fi
      printf '\n# dot_file 模型下载环境\n%s\n' "$hook" >> "$rc" || return 1
    fi
  done
  export DL_DATA_ROOT="$model_root"
  . "$env_file" || return 1
  echo "模型: $model_root/models/<org>__<name>;数据集: $model_root/datasets/<org>__<name>"
  echo "缓存: HF=${HF_HOME:-未设置};ModelScope=${MODELSCOPE_CACHE:-未设置};uv=${UV_CACHE_DIR:-未设置};日志目录=$model_root/logs"
  echo "当前终端生效: source \"$env_file\";下载: dl hf org/repo 或 dl ms org/repo --type dataset"
}

if ask "初始化通用模型下载工具(hf/modelscope)、/data 布局和 dl 命令?" Y; then
  setup_model_storage || echo "WARN: 数据布局尚未完成;准备好数据盘/权限后重跑,不会自动格式化磁盘" >&2
  install_model_tools
fi

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

# ---- 7. LunarVim(需 nvim>=0.9;用户级安装,但属「装软件」,无提权则跳过) ----
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
echo '4. ripgrep / mihomo / lvim / uv 装在 ~/.local/bin,fnm 在 ~/.local/share/fnm,bun 在 ~/.bun(.zshrc 的 dot_file PATH 块已加进 PATH);mihomo 配置为 ~/.config/mihomo/mihomo.yaml,回车跳过者需自行补齐'
echo "5. LunarVim 需 nvim>=0.9;apt 版过旧会跳过,自行装新版 nvim 后重跑即可"
echo '6. 模型/数据集默认 /data/{models,datasets}/<org>__<name>;用 dl 下载,项目依赖用 uv venv/uv pip/uv run,不修改系统或硬件平台自带的 Python 环境'
echo '   私有仓库按需 hf auth login / modelscope login;脚本不索要、不写入 token,不自动下载模型权重'
