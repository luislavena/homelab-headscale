#!/usr/bin/env sh

set -e

# Capture DB_FILE, APP, and possible arguments from command line
DB_FILE=$1
APP=$2
shift 2
APP_ARGS="$@"

# Validate that both arguments are provided
if [ -z "$DB_FILE" ] || [ -z "$APP" ]; then
    echo "ERROR: Both DB_FILE and APP arguments are required" >&2
    echo "Usage: $0 <db_file_path> <app_path> [app_args...]"
    echo "Example: $0 /data/headscale.sqlite3 /usr/local/bin/headscale serve"
    exit 1
fi

DB_PATH=$(dirname ${DB_FILE})

export APP_NAME=$(basename ${APP})
export DB_FILE

# running user
PUID=${PUID:-1000}
PGID=${PGID:-1000}

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

check_database_directory() {
	if [ ! -d "${DB_PATH}" ]; then
		echo "INFO: Creating database directory ${DB_PATH}..."
		mkdir -p "${DB_PATH}"
	fi

	echo "INFO: Ensure correct ownership of database directory..."
	find "${DB_PATH}" \( ! -group "${PGID}" -o ! -user "${PUID}" \) -exec chown "${PUID}:${PGID}" {} +
}

check_socket_directory() {
	mkdir -p /var/run/headscale

	echo "INFO: Ensure correct ownership of socket directory..."
	find "/var/run/${APP_NAME}" \( ! -group "${PGID}" -o ! -user "${PUID}" \) -exec chown "${PUID}:${PGID}" {} +
}

if ! check_config_files; then
	exit 1
fi

if ! check_database_directory; then
	exit 1
fi

if ! check_socket_directory; then
	exit 1
fi

echo "INFO: Attempting to restore database if missing..."
su-exec "$PUID:$PGID" litestream restore -if-db-not-exists -if-replica-exists ${DB_FILE}

if [ -z "$DISABLE_REPLICATION" ]; then
	echo "INFO: Starting application using Litestream..."
	exec su-exec "$PUID:$PGID" litestream replicate -exec "${APP} ${APP_ARGS}"
else
	echo "INFO: Replication disabled, starting application directly..."
	exec su-exec "$PUID:$PGID" ${APP} ${APP_ARGS}
fi
