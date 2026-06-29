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
  python3 \
  git
msg_ok "Installed Dependencies"

NODE_VERSION="22" setup_nodejs

fetch_and_deploy_gh_release "omniroute" "diegosouzapw/OmniRoute" "tarball"

msg_info "Building OmniRoute"
cd /opt/omniroute
$STD npm ci --no-audit --no-fund || $STD npm install --no-audit --no-fund
NEXT_TELEMETRY_DISABLED=1 NODE_OPTIONS="--max-old-space-size=3584" $STD npm run build
mkdir -p /opt/omniroute/data
msg_ok "Built OmniRoute"

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
ExecStart=/usr/bin/npm start
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
