#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: hakeero
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/diegosouzapw/OmniRoute

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y \
  build-essential \
  python3
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

msg_info "Installing OmniRoute (pre-built npm package)"
$STD npm install -g omniroute
OMNIROUTE_BIN="$(command -v omniroute)"
if [[ -z "$OMNIROUTE_BIN" ]]; then
  msg_error "omniroute binary not found after npm install -g"
  exit 1
fi
mkdir -p /opt/omniroute/data
msg_ok "Installed OmniRoute"

msg_info "Configuring OmniRoute"
cat <<EOF >/opt/omniroute/.env
PORT=20128
DATA_DIR=/opt/omniroute/data
REQUIRE_API_KEY=false
NODE_ENV=production
EOF
msg_ok "Configured OmniRoute"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/omniroute.service
[Unit]
Description=OmniRoute AI Gateway
After=network.target

[Service]
Type=simple
EnvironmentFile=/opt/omniroute/.env
WorkingDirectory=/opt/omniroute
ExecStart=${OMNIROUTE_BIN} serve
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now omniroute
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
