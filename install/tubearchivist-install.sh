#!/usr/bin/env bash

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
    nginx \
    python3-pip \
    python3-venv \
    build-essential \
    curl \
    git \
    ffmpeg \
    atomicparsley \
    redis
msg_ok "Installed Dependencies"

msg_info "Installing Elasticsearch"
# Add Elasticsearch repository
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" > /etc/apt/sources.list.d/elastic-8.x.list
$STD apt-get update
$STD apt-get install -y elasticsearch

# Configure Elasticsearch
cat <<EOF > /etc/elasticsearch/elasticsearch.yml
xpack.security.enabled: true
discovery.type: single-node
path.repo: /usr/share/elasticsearch/data/snapshot
network.host: 0.0.0.0
EOF

# Set Elasticsearch password
$STD /usr/share/elasticsearch/bin/elasticsearch-setup-passwords auto | tee /root/elastic_passwords.txt

# Configure Java heap size
cat <<EOF > /etc/elasticsearch/jvm.options.d/heap.options
-Xms1g
-Xmx1g
EOF

# Start and enable Elasticsearch
$STD systemctl enable elasticsearch
$STD systemctl start elasticsearch
msg_ok "Installed and Configured Elasticsearch"

msg_info "Configuring Redis"
# Configure Redis to listen on all interfaces
$STD sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf
$STD systemctl enable redis
$STD systemctl start redis
msg_ok "Configured Redis"

msg_info "Creating Directories"
mkdir -p /cache /youtube /app
msg_ok "Created Directories"

msg_info "Installing TubeArchivist"
# Clone the repository
$STD git clone https://github.com/tubearchivist/tubearchivist.git /tmp/tubearchivist

# Install Python requirements
$STD pip3 install -r /tmp/tubearchivist/tubearchivist/requirements.txt

# Copy application files
$STD cp -r /tmp/tubearchivist/tubearchivist/* /app/
$STD cp /tmp/tubearchivist/docker_assets/nginx.conf /etc/nginx/sites-available/default
$STD cp /tmp/tubearchivist/docker_assets/run.sh /app/
$STD cp /tmp/tubearchivist/docker_assets/uwsgi.ini /app/

# Configure nginx
$STD sed -i 's/^user www\-data\;$/user root\;/' /etc/nginx/nginx.conf

# Configure TubeArchivist environment
cat <<EOF > /app/.env
ES_URL=http://localhost:9200
REDIS_HOST=localhost
TA_USERNAME=tubearchivist
TA_PASSWORD=verysecret
ELASTIC_PASSWORD=$(grep "elastic = " /root/elastic_passwords.txt | cut -d' ' -f3)
TZ=UTC
EOF

# Make run script executable
$STD chmod +x /app/run.sh

# Clean up
$STD rm -rf /tmp/tubearchivist
msg_ok "Installed TubeArchivist"

msg_info "Setting up Services"
# Create systemd service for TubeArchivist
cat <<EOF > /etc/systemd/system/tubearchivist.service
[Unit]
Description=TubeArchivist
After=network.target elasticsearch.service redis.service

[Service]
Type=simple
User=root
WorkingDirectory=/app
EnvironmentFile=/app/.env
Environment=PYTHONUNBUFFERED=1
ExecStart=/app/run.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Enable and start services
$STD systemctl enable nginx
$STD systemctl enable tubearchivist
$STD systemctl start nginx
$STD systemctl start tubearchivist
msg_ok "Setup Services"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get autoremove >/dev/null
$STD apt-get autoclean >/dev/null
msg_ok "Cleaned" 