
#!/usr/bin/env bash
set -Eeuo pipefail
umask 027

# ============================================================
# CloudRecover application-server provisioning
# OS: Ubuntu Server 26.04 LTS
# App: NestJS + Prisma + PostgreSQL on Amazon RDS
# Author: Ebong Valentine
# ============================================================

APP_REPO="https://github.com/Val242/CloudRecover.git"
APP_BRANCH="main"
APP_SUBDIR="cloudrecover-api"

APP_DIR="/opt/cloudrecover-api"
APP_USER="cloudrecover"
APP_GROUP="cloudrecover"
APP_SERVICE="cloudrecover-api"

NODE_EXPORTER_VERSION="1.10.2"
NODE_EXPORTER_SERVICE="node-exporter"
NODE_EXPORTER_USER="prometheus"
NODE_EXPORTER_BIN="/usr/local/bin/node_exporter"

RDS_CA_DIR="/etc/ssl/certs/rds"
RDS_CA_BUNDLE="${RDS_CA_DIR}/global-bundle.pem"
RDS_CA_URL="https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem"

# Match this to the actual VPC CIDR configured in Terraform.
VPC_CIDR="${VPC_CIDR:-172.40.0.0/16}"

ENV_FILE="${APP_DIR}/.env"
WORK_DIR="$(mktemp -d /tmp/cloudrecover-setup.XXXXXX)"

cleanup() {
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

on_error() {
    local exit_code=$?
    echo "ERROR: Provisioning failed near line ${BASH_LINENO[0]} (exit ${exit_code})." >&2
    echo "Review the preceding output and system logs before retrying." >&2
    exit "$exit_code"
}
trap on_error ERR

log() {
    printf '\n[%s] %s\n' "$(date '+%F %T')" "$*"
}

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

# ------------------------------------------------------------
# 0. Validate operating system and execution context
# ------------------------------------------------------------

[[ $EUID -eq 0 ]] || fail "Run this script with sudo or as root."
[[ -r /etc/os-release ]] || fail "Cannot identify the operating system."

source /etc/os-release

[[ "${ID:-}" == "ubuntu" ]] || fail "Ubuntu is required."
[[ "${VERSION_ID:-}" == "26.04" ]] || fail "This script targets Ubuntu 26.04 only."

case "$(dpkg --print-architecture)" in
    amd64)
        EXPORTER_ARCH="amd64"
        ;;
    arm64)
        EXPORTER_ARCH="arm64"
        ;;
    *)
        fail "Unsupported architecture: $(dpkg --print-architecture)"
        ;;
esac

log "Ubuntu ${VERSION_ID}; architecture $(dpkg --print-architecture)"
log "Application directory: ${APP_DIR}"
log "VPC CIDR for host firewall rules: ${VPC_CIDR}"

# ------------------------------------------------------------
# 1. Base operating-system packages
# ------------------------------------------------------------

log "Updating packages and installing prerequisites"

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get upgrade -y

apt-get install -y \
    ca-certificates \
    curl \
    wget \
    git \
    rsync \
    zip \
    unzip \
    gnupg \
    stress \
    stress-ng \
    ufw

install -d -m 0755 /etc/apt/keyrings

# ------------------------------------------------------------
# 2. Install Node.js 24 LTS
# ------------------------------------------------------------

log "Installing Node.js 24 LTS"

if ! command -v node >/dev/null 2>&1 ||
   ! node --version | grep -Eq '^v24\.'; then

    curl -fsSL https://deb.nodesource.com/setup_24.x \
        -o "${WORK_DIR}/nodesource_setup.sh"

    bash "${WORK_DIR}/nodesource_setup.sh"
    apt-get install -y nodejs
fi

node --version
npm --version

node --version | grep -Eq '^v24\.' ||
    fail "Node.js 24 was not installed successfully."

# ------------------------------------------------------------
# 3. Install Node Exporter
# ------------------------------------------------------------

log "Installing Node Exporter ${NODE_EXPORTER_VERSION}"

if ! getent group "${NODE_EXPORTER_USER}" >/dev/null; then
    groupadd --system "${NODE_EXPORTER_USER}"
fi

if ! id "${NODE_EXPORTER_USER}" >/dev/null 2>&1; then
    useradd \
        --system \
        --gid "${NODE_EXPORTER_USER}" \
        --no-create-home \
        --shell /usr/sbin/nologin \
        "${NODE_EXPORTER_USER}"
fi

EXPORTER_ARCHIVE="node_exporter-${NODE_EXPORTER_VERSION}.linux-${EXPORTER_ARCH}.tar.gz"
EXPORTER_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/${EXPORTER_ARCHIVE}"

curl -fL "${EXPORTER_URL}" -o "${WORK_DIR}/${EXPORTER_ARCHIVE}"

tar -xzf "${WORK_DIR}/${EXPORTER_ARCHIVE}" -C "${WORK_DIR}"

install -o root -g root -m 0755 \
    "${WORK_DIR}/node_exporter-${NODE_EXPORTER_VERSION}.linux-${EXPORTER_ARCH}/node_exporter" \
    "${NODE_EXPORTER_BIN}"

cat > /etc/systemd/system/${NODE_EXPORTER_SERVICE}.service <<EOF
[Unit]
Description=Prometheus Node Exporter
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${NODE_EXPORTER_USER}
Group=${NODE_EXPORTER_USER}
ExecStart=${NODE_EXPORTER_BIN} --web.listen-address=:9100
Restart=on-failure
RestartSec=5
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now "${NODE_EXPORTER_SERVICE}"

# ------------------------------------------------------------
# 4. Fetch and build the NestJS application
# ------------------------------------------------------------

log "Checking out CloudRecover"

git clone \
    --depth 1 \
    --filter=blob:none \
    --sparse \
    --branch "${APP_BRANCH}" \
    "${APP_REPO}" \
    "${WORK_DIR}/repo"

git -C "${WORK_DIR}/repo" sparse-checkout set "${APP_SUBDIR}"

SOURCE_DIR="${WORK_DIR}/repo/${APP_SUBDIR}"

[[ -f "${SOURCE_DIR}/package.json" ]] ||
    fail "package.json was not found in ${SOURCE_DIR}"

[[ -f "${SOURCE_DIR}/src/database/database.service.ts" ]] ||
    fail "Expected database service was not found."

# Verify that runtime PrismaPg uses the expected trusted CA.
grep -Fq "${RDS_CA_BUNDLE}" \
    "${SOURCE_DIR}/src/database/database.service.ts" ||
    fail "DatabaseService does not reference ${RDS_CA_BUNDLE}"

grep -Eq 'rejectUnauthorized:[[:space:]]*true' \
    "${SOURCE_DIR}/src/database/database.service.ts" ||
    fail "DatabaseService must verify the RDS server certificate."

if ! getent group "${APP_GROUP}" >/dev/null; then
    groupadd --system "${APP_GROUP}"
fi

if ! id "${APP_USER}" >/dev/null 2>&1; then
    useradd \
        --system \
        --gid "${APP_GROUP}" \
        --home-dir "${APP_DIR}" \
        --no-create-home \
        --shell /usr/sbin/nologin \
        "${APP_USER}"
fi

install -d -o "${APP_USER}" -g "${APP_GROUP}" -m 0750 "${APP_DIR}"

# Stop the current service before replacing application files.
systemctl stop "${APP_SERVICE}" 2>/dev/null || true

# Preserve .env; replace tracked application files without deleting secrets.
rsync -a --delete \
    --exclude='.env' \
    --exclude='node_modules/' \
    "${SOURCE_DIR}/" "${APP_DIR}/"

chown -R "${APP_USER}:${APP_GROUP}" "${APP_DIR}"

log "Installing production dependencies and building NestJS"

runuser -u "${APP_USER}" -- bash -c "
    set -Eeuo pipefail
    cd '${APP_DIR}'
    npm ci
    npx prisma generate
    npm run build
"

[[ -f "${APP_DIR}/dist/src/main.js" ]] ||
    fail "Expected build output dist/src/main.js was not created."

# ------------------------------------------------------------
# 5. Install the RDS CA bundle and configure DATABASE_URL
# ------------------------------------------------------------

log "Installing the Amazon RDS CA bundle"

install -d -m 0755 "${RDS_CA_DIR}"

curl -fL "${RDS_CA_URL}" -o "${RDS_CA_BUNDLE}.tmp"

grep -q -- '-----BEGIN CERTIFICATE-----' "${RDS_CA_BUNDLE}.tmp" ||
    fail "Downloaded RDS CA bundle does not look like a certificate bundle."

install -o root -g root -m 0644 \
    "${RDS_CA_BUNDLE}.tmp" "${RDS_CA_BUNDLE}"

rm -f "${RDS_CA_BUNDLE}.tmp"

if [[ ! -f "${ENV_FILE}" ]]; then
    install -o "${APP_USER}" -g "${APP_GROUP}" -m 0600 /dev/null "${ENV_FILE}"
fi

chown "${APP_USER}:${APP_GROUP}" "${ENV_FILE}"
chmod 0600 "${ENV_FILE}"

# Existing DATABASE_URL is preserved. If absent, ask for the RDS details.
if ! grep -qE '^DATABASE_URL=' "${ENV_FILE}"; then
    log "DATABASE_URL is missing; configure the existing RDS database."

    read -r -p "RDS endpoint hostname (without https://): " DB_HOST
    read -r -p "Database name [mydb]: " DB_NAME
    DB_NAME="${DB_NAME:-mydb}"
    read -r -p "Database username: " DB_USER
    read -r -s -p "Database password: " DB_PASSWORD
    printf '\n'

    [[ -n "${DB_HOST}" && -n "${DB_NAME}" && -n "${DB_USER}" ]] ||
        fail "RDS hostname, database name, and username are required."

    # Encode URL components without printing the password.
    DATABASE_URL_VALUE="$(
        DB_HOST="${DB_HOST}" \
        DB_NAME="${DB_NAME}" \
        DB_USER="${DB_USER}" \
        DB_PASSWORD="${DB_PASSWORD}" \
        node <<'NODE'
const enc = encodeURIComponent;
const host = process.env.DB_HOST;
if (host.includes("/") || host.includes("@") || host.includes("://")) {
  throw new Error("Enter only the RDS endpoint hostname.");
}
const db = enc(process.env.DB_NAME);
const user = enc(process.env.DB_USER);
const pass = enc(process.env.DB_PASSWORD);
process.stdout.write(
  `postgresql://${user}:${pass}@${host}:5432/${db}?schema=public`
);
NODE
    )"

    printf '\nDATABASE_URL="%s"\n' "${DATABASE_URL_VALUE}" >> "${ENV_FILE}"

    unset DB_HOST DB_NAME DB_USER DB_PASSWORD DATABASE_URL_VALUE
    chown "${APP_USER}:${APP_GROUP}" "${ENV_FILE}"
    chmod 0600 "${ENV_FILE}"
fi

# Validate the URL without printing its credentials.
runuser -u "${APP_USER}" -- \
    sh -c 'cd /opt/cloudrecover-api && exec env APP_ENV_FILE=/opt/cloudrecover-api/.env node' <<'NODE'
const dotenv = require("dotenv");
dotenv.config({ path: process.env.APP_ENV_FILE });

const value = process.env.DATABASE_URL;
if (!value) throw new Error("DATABASE_URL is missing.");

const url = new URL(value);
if (!["postgres:", "postgresql:"].includes(url.protocol)) {
  throw new Error("DATABASE_URL must use PostgreSQL.");
}
if (!url.hostname || !url.username || !url.pathname.slice(1)) {
  throw new Error("DATABASE_URL is missing required connection fields.");
}
if (url.searchParams.has("sslmode")) {
  throw new Error(
    "Remove sslmode from the persistent DATABASE_URL; runtime TLS is configured in PrismaPg."
  );
}
console.log("DATABASE_URL structure validated; credentials were not displayed.");
NODE

# Apply migrations using a temporary CLI-only sslmode=require.
# This is not written back to .env. Runtime TLS uses the explicit RDS CA
# configuration in DatabaseService.
log "Applying Prisma migrations"

runuser -u "${APP_USER}" -- \
    sh -c 'cd /opt/cloudrecover-api && exec env APP_ENV_FILE=/opt/cloudrecover-api/.env APP_DIR=/opt/cloudrecover-api node' <<'NODE'
const dotenv = require("dotenv");
const { spawnSync } = require("node:child_process");

dotenv.config({ path: process.env.APP_ENV_FILE });

if (!process.env.DATABASE_URL) {
  throw new Error("DATABASE_URL is missing.");
}

const url = new URL(process.env.DATABASE_URL);
url.searchParams.set("sslmode", "require");

const env = {
  ...process.env,
  DATABASE_URL: url.toString(),
};

const result = spawnSync(
  "npx",
  ["prisma", "migrate", "deploy"],
  {
    cwd: process.env.APP_DIR,
    env,
    stdio: "inherit",
  }
);

if (result.error) throw result.error;
process.exit(result.status ?? 1);
NODE

# ------------------------------------------------------------
# 6. Create and start the application systemd service
# ------------------------------------------------------------

log "Configuring ${APP_SERVICE}.service"

cat > "/etc/systemd/system/${APP_SERVICE}.service" <<EOF
[Unit]
Description=CloudRecover NestJS API
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${APP_USER}
Group=${APP_GROUP}
WorkingDirectory=${APP_DIR}
EnvironmentFile=${ENV_FILE}
Environment=NODE_ENV=production
ExecStart=/usr/bin/node ${APP_DIR}/dist/src/main.js
Restart=on-failure
RestartSec=5
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
UMask=0027

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now "${APP_SERVICE}"

# ------------------------------------------------------------
# 7. Install the load-testing and log-generation scripts
# ------------------------------------------------------------

log "Installing load and log-generation scripts"

curl -fL \
    "https://raw.githubusercontent.com/hkhcoder/vprofile-project/monitoring/load.sh" \
    -o "${APP_DIR}/load.sh"

curl -fL \
    "https://raw.githubusercontent.com/hkhcoder/vprofile-project/monitoring/generate_multi_logs.sh" \
    -o "${APP_DIR}/generate_multi_logs.sh"

chmod 0750 "${APP_DIR}/load.sh" "${APP_DIR}/generate_multi_logs.sh"
chown "${APP_USER}:${APP_GROUP}" \
    "${APP_DIR}/load.sh" "${APP_DIR}/generate_multi_logs.sh"

# ------------------------------------------------------------
# 8. Configure the host firewall
# ------------------------------------------------------------

log "Configuring UFW"

ufw default deny incoming
ufw default allow outgoing

# SSH access. Restrict the source in the EC2 security group.
ufw allow 22/tcp comment 'SSH'

# App and node metrics are available only from the configured VPC CIDR.
ufw allow from "${VPC_CIDR}" to any port 3000 proto tcp comment 'CloudRecover API'
ufw allow from "${VPC_CIDR}" to any port 9100 proto tcp comment 'Node Exporter'

# No HTTP/HTTPS rules are added because this host does not configure a
# reverse proxy. Add them only if the architecture requires them.
ufw --force enable

# ------------------------------------------------------------
# 9. Verify services and endpoints
# ------------------------------------------------------------

log "Checking Node Exporter"

systemctl is-active --quiet "${NODE_EXPORTER_SERVICE}" ||
    fail "Node Exporter is not active."

curl -fsS http://127.0.0.1:9100/metrics >/dev/null ||
    fail "Node Exporter metrics endpoint failed."

log "Waiting for the API readiness endpoint"

READY=0

for attempt in $(seq 1 60); do
    if curl -fsS http://127.0.0.1:3000/health/ready >/dev/null; then
        READY=1
        break
    fi
    sleep 2
done

[[ "${READY}" -eq 1 ]] ||
    fail "API did not become ready. Inspect journalctl for ${APP_SERVICE}."

curl -fsS http://127.0.0.1:3000/health/live
printf '\n'

curl -fsS http://127.0.0.1:3000/health/ready
printf '\n'

curl -fsS http://127.0.0.1:3000/metrics >/dev/null ||
    fail "Application metrics endpoint failed."

systemctl is-active --quiet "${APP_SERVICE}" ||
    fail "CloudRecover service is not active."

log "Provisioning completed successfully"

printf '\n'
printf '%s\n' \
    "Hostname:          $(hostname)" \
    "OS:                Ubuntu ${VERSION_ID}" \
    "Node.js:           $(node --version)" \
    "App directory:     ${APP_DIR}" \
    "App service:       ${APP_SERVICE}" \
    "Node Exporter:     ${NODE_EXPORTER_VERSION} on port 9100" \
    "API port:          3000" \
    "RDS CA bundle:     ${RDS_CA_BUNDLE}" \
    "Firewall VPC CIDR: ${VPC_CIDR}" \
    "Database:          Amazon RDS PostgreSQL (no local PostgreSQL)"

printf '\nUseful diagnostics:\n'
printf '  systemctl status %s\n' "${APP_SERVICE}"
printf '  journalctl -u %s -n 100 --no-pager\n' "${APP_SERVICE}"
printf '  systemctl status %s\n' "${NODE_EXPORTER_SERVICE}"
printf '  ufw status verbose\n'
