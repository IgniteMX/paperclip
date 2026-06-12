#!/bin/sh
set -e

# Capture runtime UID/GID from environment variables, defaulting to 1000
PUID=${USER_UID:-1000}
PGID=${USER_GID:-1000}

# Adjust the node user's UID/GID if they differ from the runtime request
if [ "$(id -u node)" -ne "$PUID" ]; then
echo "Updating node UID to $PUID"
usermod -o -u "$PUID" node
fi

if [ "$(id -g node)" -ne "$PGID" ]; then
echo "Updating node GID to $PGID"
groupmod -o -g "$PGID" node
usermod -g "$PGID" node
fi

# Always ensure the mounted volume root is owned by node.
# Railway (and other platforms) mount persistent volumes root-owned, which
# masks the build-time chown and breaks the app running as the node user.
# Always chown recursively to fix stale root-owned files (e.g. .env created
# during root-run debugging).
chown node:node /paperclip || true
if [ -d /paperclip/instances ]; then
    chown -R node:node /paperclip/instances || true
    chmod -R u+rwX /paperclip/instances || true
fi

exec gosu node "$@"
