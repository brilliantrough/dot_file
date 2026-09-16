# docker/Dockerfile — 在项目方 base 镜像上叠加「系统级」软件
#
# 设计原则(重要):
#   运行容器时会用 `-v <持久目录>:$HOME` 覆盖家目录来做持久化 → 镜像里任何写在 $HOME 下的
#   东西在启动时都会被挂载**遮蔽(mask)**掉,等于白装(已实测:见 README)。
#   所以镜像只装到 /usr、/usr/local;凡是天然住在 $HOME 的(oh-my-zsh / tpm / LunarVim /
#   各类 dotfiles)都留到容器**启动后**再装,装进被挂载的家目录里,自然持久化。
#
# 用法:
#   1) 把本文件内容粘到你的项目 Dockerfile(或直接 docker build 本目录)
#   2) 构建:docker build -t myserver .
#   3) 启动(家目录持久化):docker run -d --name srv -v /你的持久目录:/root myserver sleep infinity
#   4) 首次在容器里做「家目录配置」:
#        docker exec -it srv zsh -lc 'bash <(curl -fsSL https://raw.githubusercontent.com/brilliantrough/dot_file/master/linux-setup.sh)'
#      镜像里已装好的软件会被 linux-setup.sh 自动识别并跳过 → 它只做 $HOME 内的配置。
#      opencode 三件套同理,在容器内跑 agent-skills 的 opencode-setup.sh。

# 改成你的项目 base 镜像(例:ubuntu:24.04 / pytorch/pytorch:2.4.0-cuda12.1-cudnn9-runtime ...)
ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

# 构建期代理(仅构建用,不会写进镜像):docker build --build-arg https_proxy=http://host:7890 .
ARG http_proxy
ARG https_proxy
ARG no_proxy

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-lc"]

# ---- 1) apt:换国内源(仅构建期需要,按需删) + 装系统包 ----
RUN set -euxo pipefail; \
    if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then \
      sed -i -e 's@//[^ ]*archive.ubuntu.com@//mirrors.tuna.tsinghua.edu.cn@g' \
             -e 's@//[^ ]*security.ubuntu.com@//mirrors.tuna.tsinghua.edu.cn@g' \
             /etc/apt/sources.list.d/ubuntu.sources; \
    elif [ -f /etc/apt/sources.list ]; then \
      sed -i -e 's@//[^ ]*archive.ubuntu.com@//mirrors.tuna.tsinghua.edu.cn@g' \
             -e 's@//[^ ]*security.ubuntu.com@//mirrors.tuna.tsinghua.edu.cn@g' \
             /etc/apt/sources.list; \
    fi; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      zsh tmux git wget curl ca-certificates openssh-server \
      vim neovim make autojump ripgrep python3 python3-pip unzip tar; \
    rm -rf /var/lib/apt/lists/*; \
    ssh-keygen -A; \
    git config --system --add safe.directory '*'   # 挂载进来的仓库属主常与容器不同

# ---- 2) 用户级运行时:装到 /usr/local(而非 $HOME,避免被挂载覆盖) ----
# fnm 的 Node 版本目录也必须在 $HOME 之外,否则同样被遮蔽
ENV FNM_DIR=/usr/local/share/fnm
ENV BUN_INSTALL=/usr/local
ENV UV_PYTHON_INSTALL_DIR=/usr/local/share/uv/python

RUN set -euxo pipefail; \
    tmp="$(mktemp -d)"; \
    curl -fsSL -o "$tmp/uv.sh" https://astral.sh/uv/install.sh; \
    UV_INSTALL_DIR=/usr/local/bin UV_NO_MODIFY_PATH=1 sh "$tmp/uv.sh"; \
    curl -fsSL -o "$tmp/bun.sh" https://bun.sh/install; \
    bash "$tmp/bun.sh"; \
    curl -fsSL -o "$tmp/fnm.sh" https://fnm.vercel.app/install; \
    bash "$tmp/fnm.sh" --install-dir /usr/local/bin --skip-shell; \
    rm -rf "$tmp"; \
    fnm install --lts; fnm default lts-latest; \
    fnm exec --using=lts-latest -- node --version; \
    uv python install 3.9 3.10 3.11 3.12 3.13; \
    uv --version; bun --version; fnm --version; uv python list --only-installed

# ---- 3) mihomo(按架构下二进制到 /usr/local/bin;不全局起服务) ----
RUN set -euxo pipefail; \
    case "$(dpkg --print-architecture)" in \
      amd64) mh=amd64 ;; arm64) mh=arm64 ;; armhf) mh=armv7 ;; \
      *) echo "unsupported arch: $(dpkg --print-architecture)" >&2; exit 1 ;; \
    esac; \
    tag="$(curl -fsSLI -o /dev/null -w '%{url_effective}' https://github.com/MetaCubeX/mihomo/releases/latest | sed 's#.*/##')"; \
    curl -fsSL -o /tmp/mihomo.gz "https://github.com/MetaCubeX/mihomo/releases/download/${tag}/mihomo-linux-${mh}-${tag}.gz"; \
    gunzip -c /tmp/mihomo.gz > /usr/local/bin/mihomo; \
    chmod 755 /usr/local/bin/mihomo; rm -f /tmp/mihomo.gz; \
    mihomo -v

# 容器里没有 systemd,sshd 需手动起(ssh-keygen -A 已在上方生成主机密钥)
EXPOSE 22
# CMD/ENTRYPOINT 用你 base 镜像原来的;保持 sleep infinity 只是为了方便 docker exec 进去配置
