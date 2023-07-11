FROM alpine:3.18.0

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
            HEADSCALE_VERSION=0.22.3 \
            HEADSCALE_SHA256=41eb475ba94d2f4efdd5b90ca76d3926a0fc0b561baabf6190ca32335c9102d2; \
        wget -q -O headscale https://github.com/juanfont/headscale/releases/download/v${HEADSCALE_VERSION}/headscale_${HEADSCALE_VERSION}_linux_amd64; \
        echo "${HEADSCALE_SHA256} *headscale" | sha256sum -c - >/dev/null 2>&1; \
        chmod +x headscale; \
        mv headscale /usr/local/bin/; \
    }; \
    # Litestream
    { \
        export \
            LITESTREAM_VERSION=0.3.9 \
            LITESTREAM_SHA256=7c19a583f022680a14f530fe0950e621bedb59666a603770cbc16ec5d920c54b; \
        wget -q -O litestream.tar.gz https://github.com/benbjohnson/litestream/releases/download/v${LITESTREAM_VERSION}/litestream-v${LITESTREAM_VERSION}-linux-amd64-static.tar.gz; \
        echo "${LITESTREAM_SHA256} *litestream.tar.gz" | sha256sum -c - >/dev/null 2>&1; \
        tar -xf litestream.tar.gz; \
        mv litestream /usr/local/bin/; \
        rm -f litestream.tar.gz; \
    }; \
    # smoke tests
    [ "$(command -v headscale)" = '/usr/local/bin/headscale' ]; \
    [ "$(command -v litestream)" = '/usr/local/bin/litestream' ]; \
    headscale version; \
    litestream version

# ---
# copy configuration and templates
COPY ./templates/headscale.template.yaml /usr/local/share/headscale/config.template.yaml
COPY ./templates/acls.template.hjson /usr/local/share/headscale/acls.template.hjson
COPY ./templates/litestream.template.yml /etc/litestream.yml
COPY ./scripts/container-entrypoint.sh /container-entrypoint.sh

ENTRYPOINT ["/container-entrypoint.sh"]
