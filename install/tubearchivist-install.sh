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

# Create and set permissions for Elasticsearch directories
msg_info "Setting up Elasticsearch directories"
mkdir -p /usr/share/elasticsearch/data
mkdir -p /usr/share/elasticsearch/logs
chown -R elasticsearch:elasticsearch /usr/share/elasticsearch
chmod -R 2750 /usr/share/elasticsearch
msg_ok "Set up Elasticsearch directories"

# Configure Elasticsearch
cat <<EOF > /etc/elasticsearch/elasticsearch.yml
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.client_authentication: required
xpack.security.transport.ssl.keystore.path: elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: elastic-certificates.p12
discovery.type: single-node
path.repo: /usr/share/elasticsearch/data/snapshot
network.host: 0.0.0.0
EOF

# Generate SSL certificates for Elasticsearch
msg_info "Generating SSL certificates"
cd /usr/share/elasticsearch
$STD /usr/share/elasticsearch/bin/elasticsearch-certutil ca --out elastic-stack-ca.p12 --pass ""
$STD /usr/share/elasticsearch/bin/elasticsearch-certutil cert --ca elastic-stack-ca.p12 --ca-pass "" --out elastic-certificates.p12 --pass ""
chown elasticsearch:elasticsearch elastic-certificates.p12
mv elastic-certificates.p12 /etc/elasticsearch/
cd -
msg_ok "Generated SSL certificates"

# Configure Java heap size
cat <<EOF > /etc/elasticsearch/jvm.options.d/heap.options
-Xms1g
-Xmx1g
EOF

# Reload systemd and start Elasticsearch
$STD systemctl daemon-reload
$STD systemctl enable elasticsearch
$STD systemctl start elasticsearch

# Wait for Elasticsearch to start
msg_info "Waiting for Elasticsearch to start..."
while ! curl -s localhost:9200 >/dev/null; do
    sleep 5
done

# Get and save the elastic password
ELASTIC_PASS=$(/usr/share/elasticsearch/bin/elasticsearch-setup-passwords auto | grep "elastic = " | cut -d' ' -f3)
echo "ELASTIC_PASSWORD=$ELASTIC_PASS" > /root/.elastic_credentials

msg_ok "Installed and Configured Elasticsearch"

msg_info "Configuring Redis"
# Configure Redis to listen on all interfaces
$STD sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf
$STD systemctl enable redis
$STD systemctl start redis
msg_ok "Configured Redis"

msg_info "Creating Directories"
mkdir -p /cache /youtube /app /app/cache
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
REDIS_PORT=6379
TA_USERNAME=tubearchivist
TA_PASSWORD=verysecret
ELASTIC_PASSWORD=$(cat /root/.elastic_credentials | cut -d'=' -f2)
HOST_UID=0
HOST_GID=0
DOWNLOAD_DIR=/youtube
CACHE_DIR=/app/cache
VIDEO_QUALITY=1080
CONCURRENT_DL=1
ENABLE_CAST=0
TZ=UTC
EOF

# Configure application settings
cat <<EOF > /app/ta_config.json
{
    "application": {
        "pagination": 50,
        "downloads": "pending",
        "default_view": "grid",
        "channel_size": "small",
        "channel_playlist_size": "small",
        "playlist_size": "small",
        "download_format": {
            "format": "bv*[height<=?1080][ext=mp4]+ba[ext=m4a]/bv*[height<=?1080]+ba/b[height<=?1080] / wv*+ba/w",
            "format_config": {
                "video_codec": "h264",
                "audio_codec": "aac",
                "container": "mp4"
            }
        }
    },
    "scheduler": {
        "enable_scheduler": true,
        "start_schedule_at": "02:00",
        "check_interval": 180,
        "download_interval": 60,
        "reindex_interval": 60,
        "reindex_time": "03:00",
        "backup_time": "04:00",
        "backup_interval": 1,
        "enable_backup": true
    }
}
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