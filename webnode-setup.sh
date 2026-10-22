#!/bin/bash
#=============================================================
#  CloudRecover Application Server Setup Script
#-------------------------------------------------------------
#  Installs and configures:
#   1. Basic System Setup
#   2. Node.js LTS
#   3. Node Exporter
#   4. PostgreSQL
#   5. CloudRecover NestJS Application
#   6. CloudRecover systemd Service
#   7. Load Generation Scripts
#   8. UFW Firewall
#   9. Final Summary
#
#  Author: Ebong Valentine
#  Version: 3.0
#  Tested on: Ubuntu 22.04 LTS
#=============================================================

set -e

#-------------------------------------------------------------
# 1. Basic System Setup
#-------------------------------------------------------------
echo "===== [1/9] Setting up basic system configuration ====="

echo "Setting hostname to web01..."

echo "web01" > /etc/hostname
hostname web01

echo "Updating and upgrading system packages..."

apt update -y
apt upgrade -y

echo "Installing essential utilities..."

apt install -y \
    curl \
    wget \
    git \
    zip \
    unzip \
    ca-certificates \
    gnupg \
    stress \
    stress-ng

echo "Basic system setup completed."


#-------------------------------------------------------------
# 2. Install Node.js LTS
#-------------------------------------------------------------
echo "===== [2/9] Installing Node.js LTS ====="

curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -

apt install -y nodejs

echo "Node.js version:"
node --version

echo "NPM version:"
npm --version

echo "Node.js installation completed."


#-------------------------------------------------------------
# 3. Install and Configure Node Exporter
#-------------------------------------------------------------
echo "===== [3/9] Installing Prometheus Node Exporter ====="

NODE_EXPORTER_VERSION="1.10.2"

mkdir -p /tmp/node-exporter
cd /tmp/node-exporter

echo "Downloading Node Exporter v${NODE_EXPORTER_VERSION}..."

wget -q \
    "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"

echo "Extracting Node Exporter..."

tar xzf \
    "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"

echo "Installing Node Exporter..."

mkdir -p /var/lib/node

mv \
    "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter" \
    /var/lib/node/node_exporter

echo "Creating prometheus system user..."

groupadd --system prometheus 2>/dev/null || true

useradd \
    --system \
    --no-create-home \
    --shell /usr/sbin/nologin \
    --gid prometheus \
    prometheus 2>/dev/null || true

chown -R prometheus:prometheus /var/lib/node

chmod 755 /var/lib/node
chmod 755 /var/lib/node/node_exporter

echo "Creating Node Exporter systemd service..."

cat <<EOF > /etc/systemd/system/node-exporter.service
[Unit]
Description=Prometheus Node Exporter
Documentation=https://prometheus.io/docs/guides/node-exporter/
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=prometheus
Group=prometheus

ExecStart=/var/lib/node/node_exporter

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now node-exporter

echo "Checking Node Exporter status..."

systemctl status node-exporter --no-pager

echo "Node Exporter setup completed."


# #-------------------------------------------------------------
# # 4. Install PostgreSQL
# #-------------------------------------------------------------
# echo "===== [4/9] Installing PostgreSQL ====="

# apt install -y postgresql postgresql-contrib

# systemctl enable --now postgresql

# echo "Checking PostgreSQL status..."

# systemctl status postgresql --no-pager

# echo "PostgreSQL setup completed."


#-------------------------------------------------------------
# 5. Setup CloudRecover NestJS Application
#-------------------------------------------------------------
echo "===== [5/9] Setting up CloudRecover NestJS application ====="

mkdir -p /tmp/project

cd /tmp/project

rm -rf CloudRecover

echo "Cloning CloudRecover repository..."

git clone --no-checkout https://github.com/Val242/CloudRecover.git

cd CloudRecover

echo "Checking out cloudrecover-api only..."

git sparse-checkout init --cone
git sparse-checkout set cloudrecover-api
git checkout

echo "Repository checkout completed."


#-------------------------------------------------------------
# Move application to /opt
#-------------------------------------------------------------
echo "Installing CloudRecover application..."

rm -rf /opt/cloudrecover-api

mkdir -p /opt/cloudrecover-api

cp -r cloudrecover-api/. /opt/cloudrecover-api/

cd /opt/cloudrecover-api


#-------------------------------------------------------------
# Create CloudRecover system user
#-------------------------------------------------------------
echo "Creating cloudrecover system user..."

groupadd --system cloudrecover 2>/dev/null || true

useradd \
    --system \
    --no-create-home \
    --shell /usr/sbin/nologin \
    --gid cloudrecover \
    cloudrecover 2>/dev/null || true


#-------------------------------------------------------------
# Install Node dependencies
#-------------------------------------------------------------
echo "Installing Node.js dependencies..."

npm ci


#-------------------------------------------------------------
# Generate Prisma Client
#-------------------------------------------------------------
echo "Generating Prisma Client..."

npx prisma generate


#-------------------------------------------------------------
# Build NestJS application
#-------------------------------------------------------------
echo "Building cloudrecover application..."

npm run build


#-------------------------------------------------------------
# Create application environment file
#-------------------------------------------------------------
echo "Creating cloudrecover environment file..."

touch /opt/cloudrecover-api/.env

chown cloudrecover:cloudrecover /opt/cloudrecover-api/.env

chmod 600 /opt/cloudrecover-api/.env


#-------------------------------------------------------------
# Application permissions
#-------------------------------------------------------------
echo "Setting application permissions..."

chown -R cloudrecover:cloudrecover /opt/cloudrecover-api

chmod -R 755 /opt/cloudrecover-api

chmod 600 /opt/cloudrecover-api/.env


#-------------------------------------------------------------
# CloudRecover systemd service
#-------------------------------------------------------------
echo "Creating CloudRecover systemd service..."

cat <<EOF > /etc/systemd/system/cloudrecover-api.service
[Unit]
Description=CloudRecover NestJS API
Wants=network-online.target

[Service]
Type=simple

User=cloudrecover
Group=cloudrecover

WorkingDirectory=/opt/cloudrecover-api

EnvironmentFile=/opt/cloudrecover-api/.env
Environment=NODE_ENV=production

ExecStart=/usr/bin/node /opt/cloudrecover-api/dist/src/main.js

Restart=always
RestartSec=5

NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF


#-------------------------------------------------------------
# Reload systemd
#-------------------------------------------------------------
echo "Reloading systemd..."

systemctl daemon-reload


# #-------------------------------------------------------------
# # Prisma Database Migration
# #-------------------------------------------------------------
# echo "Running Prisma migrations..."

# if [ -n "${DATABASE_URL:-}" ]; then
#     sudo -u cloudrecover \
#         env DATABASE_URL="$DATABASE_URL" \
#         npx prisma migrate deploy
# else
#     echo "DATABASE_URL is not currently set."
#     echo "Skipping Prisma migration."
#     echo "Configure /opt/cloudrecover-api/.env before running migrations."
# fi


# #-------------------------------------------------------------
# # Start CloudRecover
# #-------------------------------------------------------------
# echo "Enabling CloudRecover service..."

# systemctl enable cloudrecover-api

# echo "Starting CloudRecover service..."

# systemctl start cloudrecover-api

# echo "Checking CloudRecover service..."

# systemctl status cloudrecover-api --no-pager

# echo "CloudRecover application setup completed."


#-------------------------------------------------------------
# 6. Verify Application
#-------------------------------------------------------------
echo "===== [6/9] Verifying CloudRecover application ====="

echo "Waiting for CloudRecover to start..."

sleep 5

if curl -f http://localhost:3000/health/live; then
    echo ""
    echo "CloudRecover liveness check passed."
else
    echo ""
    echo "WARNING: CloudRecover liveness check failed."
    echo "Check logs with:"
    echo "journalctl -u cloudrecover-api -n 100 --no-pager"
fi

echo ""
echo "Checking application metrics endpoint..."

if curl -f http://localhost:3000/metrics > /dev/null; then
    echo "CloudRecover metrics endpoint is available."
else
    echo "WARNING: /metrics endpoint is not available."
fi


#-------------------------------------------------------------
# 7. Load Generation Scripts
#-------------------------------------------------------------
echo "===== [7/9] Setting up load generation scripts ====="

echo "Downloading load scripts..."

wget -q \
    -P /usr/local/bin/ \
    https://raw.githubusercontent.com/hkhcoder/vprofile-project/refs/heads/monitoring/load.sh

wget -q \
    -P /usr/local/bin/ \
    https://raw.githubusercontent.com/hkhcoder/vprofile-project/refs/heads/monitoring/generate_multi_logs.sh

chmod +x \
    /usr/local/bin/load.sh \
    /usr/local/bin/generate_multi_logs.sh

echo "Load generation scripts installed."


#-------------------------------------------------------------
# 8. Configure UFW Firewall
#-------------------------------------------------------------
echo "===== [8/9] Configuring UFW Firewall ====="

apt install -y ufw

echo "Configuring firewall rules..."

ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000/tcp
ufw allow 9100/tcp

echo "Enabling UFW..."

echo "y" | ufw enable

echo "Firewall status:"

ufw status verbose

echo "UFW firewall configured."


#-------------------------------------------------------------
# 9. Final Summary
#-------------------------------------------------------------
echo ""
echo "============================================================="
echo "       CloudRecover Application Server Setup Complete"
echo "============================================================="

echo ""

echo "Node.js:"
node --version

echo ""

echo "NPM:"
npm --version

echo ""

echo "Services:"

echo -n "Node Exporter : "
systemctl is-active node-exporter

# echo -n "PostgreSQL    : "
# systemctl is-active postgresql

echo -n "CloudRecover API: "
systemctl is-active cloudrecover-api

echo ""

echo "Application:"
echo "  Internal: http://<APPLICATION_PRIVATE_IP>:3000"

echo ""

echo "Health:"
echo "  Liveness: http://<APPLICATION_PRIVATE_IP>:3000/health/live"
echo "  Readiness: http://<APPLICATION_PRIVATE_IP>:3000/health/ready"

echo ""

echo "Metrics:"
echo "  Application: http://<APPLICATION_PRIVATE_IP>:3000/metrics"
echo "  System:      http://<APPLICATION_PRIVATE_IP>:9100/metrics"

echo ""

echo "PostgreSQL:"
echo "  Internal only: localhost:5432"

echo ""

echo "Monitoring:"
echo "  Prometheus should scrape:"
echo "    - APPLICATION_PRIVATE_IP:3000/metrics"
echo "    - APPLICATION_PRIVATE_IP:9100/metrics"

echo ""

echo "CloudRecover installation:"
echo "  /opt/cloudrecover-api"

echo ""

echo "Useful commands:"
echo "  systemctl status cloudrecover-api"
echo "  journalctl -u cloudrecover-api -f"
echo "  systemctl status node-exporter"
echo "  journalctl -u node-exporter -f"

echo ""

echo "============================================================="
echo "              Setup completed successfully!"
echo "============================================================="