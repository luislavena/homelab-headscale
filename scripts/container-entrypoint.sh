#!/usr/bin/env sh

set -e

check_config_files() {
	local headscale_config_path=/etc/headscale/config.yaml
	local headscale_config_template=/usr/local/share/headscale/config.template.yaml
	local headscale_private_key_path=/data/private.key
	local headscale_noise_private_key_path=/data/noise_private.key

	local abort_config=0

	# check for Headscale config file
	if [ ! -f $headscale_config_path ]; then
		echo "INFO: No Headscale configuration file found, creating one using environment variables..."

		# abort if needed variables are missing
		if [ -z "$HEADSCALE_SERVER_URL" ]; then
			echo "ERROR: Required environment variable 'HEADSCALE_SERVER_URL' is missing." >&2
			abort_config=1
		fi

		if [ -z "$HEADSCALE_BASE_DOMAIN" ]; then
			echo "ERROR: Required environment variable 'HEADSCALE_BASE_DOMAIN' is missing." >&2
			abort_config=1
		fi

		if [ $abort_config -eq 0 ]; then
			mkdir -p /etc/headscale
			cp $headscale_config_template $headscale_config_path
			sed -i "s@\$HEADSCALE_SERVER_URL@$HEADSCALE_SERVER_URL@" $headscale_config_path
			sed -i "s@\$HEADSCALE_BASE_DOMAIN@$HEADSCALE_BASE_DOMAIN@" $headscale_config_path
			echo "INFO: Headscale configuration file created."
		else
			return $abort_config
		fi
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
litestream restore -v -if-db-not-exists -if-replica-exists /data/headscale.sqlite3

echo "INFO: Starting Headscale using Litestream..."
exec litestream replicate -exec 'headscale serve'
