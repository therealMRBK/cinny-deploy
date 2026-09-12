#!/bin/sh
# Builds config.json at container startup instead of baking it into the
# image at build time. This is what makes the deployment portable: no
# personal server name has to live in this repo at all.
#
# Homeserver resolution, in order:
#   1. HOMESERVER_URL env var, if set -- always wins, no auto-detection
#      attempted. This is the manual fallback.
#   2. Auto-detect: if the Docker socket is mounted read-only into this
#      container, scan sibling containers for a well-known Matrix
#      homeserver image (Synapse, Dendrite, Conduit/Conduwuit) and read
#      its SYNAPSE_SERVER_NAME env var (the official synapse image's own
#      config knob for this). Matrix client-server well-known discovery
#      (RFC: /.well-known/matrix/client) means the bare server name is
#      enough for matrix-js-sdk to find the real API endpoint -- no need
#      to guess a URL scheme/port here.
#   3. Neither available: ship an empty homeserverList. Cinny's login
#      screen still lets a real person type in any homeserver by hand
#      (allowCustomHomeservers stays on below) -- this is the "give me
#      the option to do it manually" path for whoever's watching the
#      screen, since a startup script has no one to prompt.
set -eu

CONFIG_PATH="/app/config.json"
DOCKER_SOCK="/var/run/docker.sock"
homeserver=""

log() { echo "[cinny-entrypoint] $*"; }

if [ -n "${HOMESERVER_URL:-}" ]; then
  homeserver="$HOMESERVER_URL"
  log "Using manually configured HOMESERVER_URL: $homeserver"
elif [ -S "$DOCKER_SOCK" ]; then
  log "HOMESERVER_URL not set -- trying to auto-detect a homeserver via the mounted Docker socket..."
  containers_json="$(curl -s --unix-socket "$DOCKER_SOCK" http://localhost/containers/json || true)"
  candidate_id="$(printf '%s' "$containers_json" \
    | jq -r '.[] | select(.Image | test("synapse|dendrite|conduit|conduwuit"; "i")) | .Id' \
    | head -n1)"
  if [ -n "$candidate_id" ]; then
    inspect_json="$(curl -s --unix-socket "$DOCKER_SOCK" "http://localhost/containers/${candidate_id}/json" || true)"
    server_name="$(printf '%s' "$inspect_json" \
      | jq -r '(.Config.Env // []) | .[] | select(startswith("SYNAPSE_SERVER_NAME=")) | sub("^SYNAPSE_SERVER_NAME="; "")')"
    if [ -n "$server_name" ] && [ "$server_name" != "null" ]; then
      homeserver="$server_name"
      log "Auto-detected homeserver from container $candidate_id (SYNAPSE_SERVER_NAME): $homeserver"
    else
      log "Found a homeserver-looking container ($candidate_id) but it has no SYNAPSE_SERVER_NAME env var to read -- set HOMESERVER_URL manually instead."
    fi
  else
    log "No Synapse/Dendrite/Conduit container visible on this Docker host -- set HOMESERVER_URL manually instead."
  fi
else
  log "Docker socket not mounted and HOMESERVER_URL not set -- skipping auto-detection."
  log "Mount /var/run/docker.sock:/var/run/docker.sock:ro to enable it, or set HOMESERVER_URL yourself."
fi

if [ -n "$homeserver" ]; then
  homeserver_list="[\"$homeserver\"]"
else
  log "No homeserver configured -- shipping an empty list. Anyone using this Cinny instance enters their own server on the login screen."
  homeserver_list="[]"
fi

cat > "$CONFIG_PATH" <<EOF
{
  "defaultHomeserver": 0,
  "homeserverList": $homeserver_list,
  "allowCustomHomeservers": true,

  "featuredCommunities": {
    "openAsDefault": false,
    "spaces": [],
    "rooms": [],
    "servers": []
  },

  "hashRouter": {
    "enabled": false,
    "basename": "/"
  }
}
EOF

log "Wrote $CONFIG_PATH:"
cat "$CONFIG_PATH"

# Chain into the base image's own entrypoint (nginx:alpine's standard
# docker-entrypoint.sh -- handles its own template/env-substitution setup)
# instead of replacing it, then run the original CMD.
exec /docker-entrypoint.sh nginx -g "daemon off;"
