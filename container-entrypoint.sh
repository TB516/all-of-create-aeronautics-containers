#!/usr/bin/env bash
set -euo pipefail

DATA_DIR=/data
TEMPLATE_DIR=/opt/aoc-template

if [[ "${EULA:-}" != "TRUE" ]]; then
  cat >&2 <<'EOF'
EULA=TRUE is required to start the Minecraft server.
Set it only if you accept the Minecraft EULA: https://aka.ms/MinecraftEULA
EOF
  exit 1
fi

mkdir -p "${DATA_DIR}"

if [[ ! -f "${DATA_DIR}/start.sh" ]]; then
  echo "Initializing All Of Create - Aeronautics server files in ${DATA_DIR}"
  cp -a "${TEMPLATE_DIR}/." "${DATA_DIR}/"
fi

printf 'eula=true\n' > "${DATA_DIR}/eula.txt"
chmod +x "${DATA_DIR}/start.sh"

cd "${DATA_DIR}"
exec ./start.sh
