#!/usr/bin/env sh

set -e

echo "---> Attempt to restore headscale database if missing..."
litestream restore -if-replica-exists /data/headscale.sqlite3

echo "---> Starting Headscale using Litestream..."
exec litestream replicate -exec 'headscale serve'
