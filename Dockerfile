FROM alpine:3.20.3

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
        export HEADSCALE_VERSION=0.22.3; \
        case "$(arch)" in \
        x86_64) \
            export \
                HEADSCALE_ARCH=amd64 \
                HEADSCALE_SHA256=41eb475ba94d2f4efdd5b90ca76d3926a0fc0b561baabf6190ca32335c9102d2 \
            ; \
            ;; \
        aarch64) \
            export \
                HEADSCALE_ARCH=arm64 \
                HEADSCALE_SHA256=c36b469a30e87efc6616abd7f8df429de2a11896d311037580ac0b9c2f6b53a6 \
            ; \
            ;; \
        esac; \
        wget -q -O headscale https://github.com/juanfont/headscale/releases/download/v${HEADSCALE_VERSION}/headscale_${HEADSCALE_VERSION}_linux_${HEADSCALE_ARCH}; \
        echo "${HEADSCALE_SHA256} *headscale" | sha256sum -c - >/dev/null 2>&1; \
        chmod +x headscale; \
        mv headscale /usr/local/bin/; \
    }; \
    # Litestream
    { \
        export LITESTREAM_VERSION=0.3.11; \
        case "$(arch)" in \
        x86_64) \
            export \
                LITESTREAM_ARCH=amd64 \
                LITESTREAM_SHA256=83b63dffb1ef5f3e54e9399dcf750a35a6a9b3b20a3ca5601653cce36146c51b \
            ; \
            ;; \
        aarch64) \
            export \
                LITESTREAM_ARCH=arm64 \
                LITESTREAM_SHA256=37be08622b91239ca1a4d417b37889cbac2c6aa83bfcfa6881bcaa7642fc8ee2 \
            ; \
            ;; \
        esac; \
        wget -q -O litestream.tar.gz https://github.com/benbjohnson/litestream/releases/download/v${LITESTREAM_VERSION}/litestream-v${LITESTREAM_VERSION}-linux-${LITESTREAM_ARCH}.tar.gz; \
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
COPY ./templates/litestream.template.yml /etc/litestream.yml
COPY ./scripts/container-entrypoint.sh /container-entrypoint.sh

ENTRYPOINT ["/container-entrypoint.sh"]
