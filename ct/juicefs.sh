#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/perplexes/ProxmoxVE/main/misc/build.func)

function header_info {
clear
cat <<"EOF"
     __         _            ______  _____ 
    / /_  __  _(_)________ _/ __/ /_/ ___/
   / / / / / / / / ___/ _ `/ /_/ __/\__ \ 
  / / /_/ / / / / /__/  __/ __/ /_ ___/ / 
 /_/\__,_/_/ /_/\___/\___/_/  \__//____/  
                                          
EOF
}
header_info
echo -e "Loading..."
APP="JuiceFS"
var_disk="8"
var_cpu="2"
var_ram="2048"
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
if [[ ! -f /usr/local/bin/juicefs ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
msg_info "Updating ${APP} LXC"
curl -sSL https://d.juicefs.com/install | sh -
apt-get update &>/dev/null
apt-get -y upgrade &>/dev/null
msg_ok "Updated ${APP} LXC"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} has been installed. You can start using it with 'juicefs' command.
Redis is running on port 6379 for metadata storage.

To mount your NFS share and configure JuiceFS:
${BL}1. Mount source: mount -t nfs thebigdrive.local:/volume1/Video /mnt/source
2. Format JuiceFS: juicefs format --storage file --path /var/lib/juicefs/data redis://localhost:6379/1 mediajfs
3. Mount JuiceFS: juicefs mount --cache-dir /var/lib/juicefs/cache --cache-size 102400 redis://localhost:6379/1 /mnt/jfs
4. Warm cache: cp -r /mnt/source/* /mnt/jfs/${CL}

The JuiceFS mount will be available as an NFS share at: ${BL}${IP}:/mnt/jfs${CL}

For full documentation, visit: ${BL}https://juicefs.com/docs/community/getting-started${CL}\n" 