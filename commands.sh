#!/bin/bash
# 维护者用:从本机抓取配置回仓库(反方向;部署方向是 linux-setup.sh)
cp "$HOME/.tmux.conf" tmux
cp "$HOME/.tmux.conf.local" tmux
cp "$HOME/.config/nvim/init.vim" nvim
cp "$HOME/.config/nvim/coc-settings.json" nvim
cp /etc/squid/squid.conf squid
cp /etc/proxychains.conf proxychains
cp "$HOME/.condarc" python
cp -r "$HOME/.config/lvim/." lvim/
rm -f lvim/README.md
