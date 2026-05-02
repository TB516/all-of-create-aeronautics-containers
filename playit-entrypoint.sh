#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${SECRET_KEY:-}" ]]; then
  cat >&2 <<'EOF'
SECRET_KEY is required for the playit agent.
Create $HOME/aoc-aeronautics/secrets/playit.env from playit.env.example.
EOF
  exit 1
fi

exec playit -s --secret "${SECRET_KEY}" --platform_docker start
