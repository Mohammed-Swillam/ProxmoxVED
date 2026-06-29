#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVED/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: hakeero
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://github.com/diegosouzapw/OmniRoute

APP="OmniRoute"
var_tags="${var_tags:-ai;llm;gateway;proxy}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/omniroute ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "omniroute" "diegosouzapw/OmniRoute"; then
    msg_info "Stopping Service"
    systemctl stop omniroute
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp -r /opt/omniroute/data /opt/omniroute_data_backup
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "omniroute" "diegosouzapw/OmniRoute" "tarball"

    msg_info "Building ${APP}"
    cd /opt/omniroute
    $STD npm ci --no-audit --no-fund || $STD npm install --no-audit --no-fund
    $STD npm run build
    msg_ok "Built ${APP}"

    msg_info "Restoring Data"
    rm -rf /opt/omniroute/data
    cp -r /opt/omniroute_data_backup/. /opt/omniroute/data
    rm -rf /opt/omniroute_data_backup
    msg_ok "Restored Data"

    msg_info "Starting Service"
    systemctl start omniroute
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:20128${CL}"
