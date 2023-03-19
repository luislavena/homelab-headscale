FROM alpine:3.17.1

# ---
# upgrade system and installed dependencies for security patches
RUN --mount=type=cache,sharing=private,target=/var/cache/apk \
    set -eux; \
    apk upgrade

# ---
# copy headscale
RUN --mount=type=cache,target=/var/cache/apk \
    --mount=type=tmpfs,target=/tmp \
    set -eux; \
    cd /tmp; \
    # Headscale
    { \
        export \
            HEADSCALE_VERSION=0.20.0 \
            HEADSCALE_SHA256=1553d776b915c897d15f86adec8648378610128fdad81a848443853691748e53; \
        wget -q -O headscale https://github.com/juanfont/headscale/releases/download/v${HEADSCALE_VERSION}/headscale_${HEADSCALE_VERSION}_linux_amd64; \
        echo "${HEADSCALE_SHA256} *headscale" | sha256sum -c - >/dev/null 2>&1; \
        chmod +x headscale; \
        mv headscale /usr/local/bin/; \
    }; \
    # smoke tests
    [ "$(command -v headscale)" = '/usr/local/bin/headscale' ]; \
    headscale version

# ---
# configuration
COPY ./config/headscale.yaml /etc/headscale/config.yaml

ENTRYPOINT ["/usr/local/bin/headscale", "serve"]
