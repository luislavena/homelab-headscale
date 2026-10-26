#!/usr/bin/env sh

# End-to-end check: boot Headscale, join Tailscale nodes, verify they talk.
#
# Usage: test/run.sh [FROM_REF]
#
#   no FROM_REF  test the image built from the working tree
#   FROM_REF     build FROM_REF (Eg. main, v0.7.0), create users and nodes,
#                upgrade the server to the working tree and verify again

set -eu

cd "$(dirname "$0")"
ROOT=$(cd .. && pwd)
FROM_REF=${1:-}
TMP=

export COMPOSE_PROJECT_NAME=headscale-test
export SERVER_IMAGE=headscale-test:current TS_AUTHKEY= TS_AUTHKEY_LATE=

log() { printf '==> %s\n' "$*"; }

fail() {
	printf 'FAIL: %s\n' "$*" >&2
	docker compose --profile late logs --tail 30 >&2 || true
	exit 1
}

hs() { docker compose exec -T server headscale "$@"; }

cleanup() {
	docker compose --profile late down -v >/dev/null 2>&1 || true
	[ -z "$TMP" ] || rm -rf "$TMP"
}

# wait_for <description> <command...>
wait_for() {
	desc=$1
	shift
	i=0
	until "$@" >/dev/null 2>&1; do
		i=$((i + 1))
		[ $i -lt 30 ] || fail "timeout waiting for $desc"
		sleep 2
	done
}

nodes_online() { [ "$(hs nodes list -o json | grep -c '"online": true')" -eq "$1" ]; }

start_server() {
	docker compose up -d server >/dev/null 2>&1
	wait_for "server health" hs health
	log "Server running $(hs version | head -1)"
	if docker compose logs server | grep -qE ' (ERR|FTL) |panic'; then
		fail "errors in server logs"
	fi
}

# key [extra flags...]: print a new pre-auth key for user 1
key() {
	hs preauthkeys create --user 1 --expiration 1h -o json "$@" |
		sed -n 's/.*"key": "\(.*\)".*/\1/p'
}

check_mesh() {
	for pair in "node1 node2" "node2 node1"; do
		set -- $pair
		# online in headscale comes before the WireGuard path is up
		wait_for "tailscale ping $1 -> $2" docker compose exec -T "$1" tailscale ping -c 1 "$2"
		ip=$(docker compose exec -T "$2" tailscale ip -4)
		docker compose exec -T "$1" ping -c 2 -W 2 "$ip" >/dev/null ||
			fail "ping $1 -> $2 ($ip)"
		docker compose exec -T "$1" sh -c 'command -v ssh >/dev/null || apk add -q openssh-client'
		out=$(docker compose exec -T "$1" tailscale ssh "root@$2" hostname) ||
			fail "tailscale ssh $1 -> $2"
		[ "$out" = "$2" ] || fail "ssh $1 -> $2 returned '$out'"
		log "$1 -> $2: ping, tailscale ping, ssh OK"
	done
}

# snapshot <file>: fields that must survive an upgrade
snapshot() {
	{
		hs users list -o json | grep -E '"(id|name)"'
		hs nodes list -o json | grep -E '"(id|name|machine_key|node_key)"|"(100\.|fd7a)'
	} >"$1"
}

trap cleanup EXIT
cleanup
TMP=$(mktemp -d)

log "Building image from working tree"
docker build -q -t headscale-test:current "$ROOT" >/dev/null
if [ -n "$FROM_REF" ]; then
	log "Building image from $FROM_REF"
	git -C "$ROOT" archive "$FROM_REF" | docker build -q -t headscale-test:base - >/dev/null
	SERVER_IMAGE=headscale-test:base
fi

start_server
hs users create alice >/dev/null
TS_AUTHKEY=$(key --reusable)
[ -n "$TS_AUTHKEY" ] || fail "could not create pre-auth key"

log "Joining node1 and node2"
docker compose up -d node1 node2 >/dev/null 2>&1
wait_for "node1 and node2 online" nodes_online 2
check_mesh
snapshot "$TMP/before"

if [ -n "$FROM_REF" ]; then
	log "Upgrading server to working tree"
	SERVER_IMAGE=headscale-test:current
	start_server

	# Tailscale only dials TLS on 443 after a failed control connection,
	# so these plain HTTP clients never reconnect alone. A restart keeps
	# their state, so they must come back without a new login.
	docker compose restart node1 node2 >/dev/null 2>&1
	wait_for "node1 and node2 online after upgrade" nodes_online 2
	check_mesh
	snapshot "$TMP/after"
	diff "$TMP/before" "$TMP/after" || fail "users or nodes changed after upgrade"
	log "Users and nodes unchanged after upgrade"
fi

log "Joining node3 with a new ephemeral key"
TS_AUTHKEY_LATE=$(key --ephemeral)
docker compose up -d node3 >/dev/null 2>&1
wait_for "node3 online" nodes_online 3
wait_for "tailscale ping node3 -> node1" docker compose exec -T node3 tailscale ping -c 1 node1
log "node3 -> node1: tailscale ping OK"

log "PASS"
