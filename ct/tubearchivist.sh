#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/perplexes/ProxmoxVE/main/misc/build.func)

function header_info {
clear
cat <<"EOF"
    ______      __           ___              __    _      _      __ 
   /_  __/_  __/ /_  ___    /   |  __________/ /_  (_)    / /_____/ /_
    / / / / / / __ \/ _ \  / /| | / ___/ ___/ __ \/ /    / __/ ___/ __/
   / / / /_/ / /_/ /  __/ / ___ |/ /  / /__/ / / / /    / /_/ /  / /_  
  /_/  \__,_/_.___/\___/ /_/  |_/_/   \___/_/ /_/_/     \__/_/   \__/  
                                                                    
EOF
}
header_info
echo -e "Loading..."
APP="TubeArchivist"
var_disk="32"
var_cpu="2"
var_ram="4096"
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
  SSH="yes"
  VERB="no"
  echo_default
}

function update_script() {
header_info
if [[ ! -f /usr/local/bin/tubearchivist ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
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
echo -e "${APP} has been installed. You can access the web interface at:
${BL}http://${IP}:8000${CL}

Default credentials:
${BL}Username: tubearchivist
Password: verysecret${CL}

Media files are stored in: ${BL}/youtube${CL}
Cache directory: ${BL}/cache${CL}

For full documentation, visit: ${BL}https://github.com/tubearchivist/tubearchivist${CL}\n" 