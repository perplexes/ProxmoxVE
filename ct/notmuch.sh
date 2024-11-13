#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/perplexes/ProxmoxVE/main/misc/build.func)

function header_info {
clear
cat <<"EOF"
    _   __      __                      __  
   / | / /___  / /_____ ___  __  ______/ /_ 
  /  |/ / __ \/ __/ __ `__ \/ / / / __  / / 
 / /|  / /_/ / /_/ / / / / / /_/ / /_/ / /  
/_/ |_/\____/\__/_/ /_/ /_/\__,_/\__,_/_/   
                                            
EOF
}
header_info
echo -e "Loading..."
APP="Notmuch"
var_disk="4"
var_cpu="1"
var_ram="512"
var_os="debian"
var_version="12"
variables
color
catch_errors

function default_settings() {
  CT_TYPE="1"
  PW=""
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr0"
  NET="dhcp"
  GATE=""
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIP6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="no"
  VERB="no"
  echo_default
}

function update_script() {
header_info
if [[ ! -f /usr/bin/notmuch ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Updating ${APP} LXC"
apt-get update &>/dev/null
apt-get -y upgrade &>/dev/null
msg_ok "Updated ${APP} LXC"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} web interface should be reachable by going to the following URL.
             ${BL}http://${IP}:8080${CL}\n"
