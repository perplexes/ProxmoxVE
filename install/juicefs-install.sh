#!/usr/bin/env bash

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y curl
$STD apt-get install -y sudo
$STD apt-get install -y mc
$STD apt-get install -y wget
$STD apt-get install -y nfs-common
$STD apt-get install -y nfs-kernel-server
msg_ok "Installed Dependencies"

msg_info "Installing Redis"
$STD apt-get install -y redis-server
# Configure Redis to listen on all interfaces
$STD sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf
# Start Redis and enable on boot
$STD systemctl enable redis-server
$STD systemctl start redis-server
msg_ok "Installed and Configured Redis"

msg_info "Installing JuiceFS"
$STD curl -sSL https://d.juicefs.com/install | sh -
msg_ok "Installed JuiceFS"

msg_info "Installing JuiceFS FUSE dependencies"
$STD apt-get install -y fuse
msg_ok "Installed FUSE"

# Create mount directories
mkdir -p /mnt/source
mkdir -p /mnt/jfs
mkdir -p /srv/nfs/media

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get autoremove >/dev/null
$STD apt-get autoclean >/dev/null
msg_ok "Cleaned" 