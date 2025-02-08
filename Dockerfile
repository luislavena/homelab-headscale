FROM alpine:3.21.2

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
        export HEADSCALE_VERSION=0.24.3; \
        case "$(arch)" in \
        x86_64) \
            export \
                HEADSCALE_ARCH=amd64 \
                HEADSCALE_SHA256=d6dcb26502cde796f3d7ccf3c250b29bb71b4dc6074fc3a58d719feb07d5d63c \
            ; \
            ;; \
        aarch64) \
            export \
                HEADSCALE_ARCH=arm64 \
                HEADSCALE_SHA256=d381a6f75775ce7c71da326a68e556305af4c50babf55b47770cb03f92a5d7eb \
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
        export LITESTREAM_VERSION=0.3.13; \
        case "$(arch)" in \
        x86_64) \
            export \
                LITESTREAM_ARCH=amd64 \
                LITESTREAM_SHA256=eb75a3de5cab03875cdae9f5f539e6aedadd66607003d9b1e7a9077948818ba0 \
            ; \
            ;; \
        aarch64) \
            export \
                LITESTREAM_ARCH=arm64 \
                LITESTREAM_SHA256=9585f5a508516bd66af2b2376bab4de256a5ef8e2b73ec760559e679628f2d59 \
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
