#!/usr/bin/env sh

set -e

check_config_files() {
	local headscale_config_path=/etc/headscale/config.yaml
	local headscale_config_template=/usr/local/share/headscale/config.template.yaml
	local headscale_private_key_path=/data/private.key
	local headscale_noise_private_key_path=/data/noise_private.key

	local abort_config=0

	# abort if needed variables are missing
	if [ -z "$HEADSCALE_SERVER_URL" ]; then
		echo "ERROR: Required environment variable 'HEADSCALE_SERVER_URL' is missing." >&2
		abort_config=1
	fi

	if [ -z "$HEADSCALE_BASE_DOMAIN" ]; then
		echo "ERROR: Required environment variable 'HEADSCALE_BASE_DOMAIN' is missing." >&2
		abort_config=1
	fi

	if [ $abort_config -ne 0 ]; then
		return $abort_config
	fi

	if [ ! -f $headscale_private_key_path ]; then
		if [ ! -z "$HEADSCALE_PRIVATE_KEY" ]; then
			echo -n "$HEADSCALE_PRIVATE_KEY" > $headscale_private_key_path
		fi
	fi

	if [ ! -f $headscale_noise_private_key_path ]; then
		if [ ! -z "$HEADSCALE_NOISE_PRIVATE_KEY" ]; then
			echo -n "$HEADSCALE_NOISE_PRIVATE_KEY" > $headscale_noise_private_key_path
		fi
	fi
}

check_socket_directory() {
	mkdir -p /var/run/headscale
}

if ! check_config_files; then
	exit 1
fi

if ! check_socket_directory; then
	exit 1
fi

echo "INFO: Attempt to restore Headscale database if missing..."
litestream restore -if-db-not-exists -if-replica-exists /data/headscale.sqlite3

echo "INFO: Starting Headscale using Litestream..."
exec litestream replicate -exec 'headscale serve'
