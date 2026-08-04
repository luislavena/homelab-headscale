# syntax=registry.docker.com/docker/dockerfile:1

ARG ALPINE_VERSION=3.24.1
FROM registry.docker.com/library/alpine:${ALPINE_VERSION}

# ---
# system tools & non-root user (1000)
RUN --mount=type=cache,target=/var/cache/apk \
    set -eux; \
    { \
        apk add \
            su-exec \
        ; \
    }; \
    # non-root user and group
    { \
        addgroup -g 1000 headscale; \
        adduser -u 1000 -G headscale -h /app -s /bin/sh -D headscale; \
        # cleanup backup copies
        rm /etc/group- /etc/passwd- /etc/shadow-; \
    }

# ---
# litestream
RUN --mount=type=tmpfs,target=/tmp \
    set -eux; \
    cd /tmp; \
    { \
        export LITESTREAM_VERSION=0.3.14; \
        case "$(arch)" in \
        x86_64) \
            export \
                LITESTREAM_ARCH=amd64 \
                LITESTREAM_SHA256=880ccafc9514650c4a2a0cc78eb1e61aaad95dd3e86e877c8694f955c9095436 \
            ; \
            ;; \
        aarch64) \
            export \
                LITESTREAM_ARCH=arm64 \
                LITESTREAM_SHA256=4d375a66653e4a9b27a5b38ce9cb73681c39893ba0485f81ab860d4cd427e642 \
            ; \
            ;; \
        esac; \
        wget -q -O litestream.tar.gz https://github.com/benbjohnson/litestream/releases/download/v${LITESTREAM_VERSION}/litestream-v${LITESTREAM_VERSION}-linux-${LITESTREAM_ARCH}.tar.gz; \
        echo "${LITESTREAM_SHA256} *litestream.tar.gz" | sha256sum -c - >/dev/null 2>&1; \
        tar -xf litestream.tar.gz; \
        mv litestream /usr/local/bin/; \
        rm -f litestream.tar.gz; \
    }; \
    # smoke test
    [ "$(command -v litestream)" = '/usr/local/bin/litestream' ]; \
    litestream version

# ---
# headscale
RUN --mount=type=cache,target=/var/cache/apk \
    --mount=type=tmpfs,target=/tmp \
    set -eux; \
    mkdir -p /app; \
    cd /tmp; \
    # Headscale
    { \
        export HEADSCALE_VERSION=0.29.3; \
        case "$(arch)" in \
        x86_64) \
            export \
                HEADSCALE_ARCH=amd64 \
                HEADSCALE_SHA256=8dc183758024ed7095cf610fedea0790233613c71353bc8be2715d82ba29b92c \
            ; \
            ;; \
        aarch64) \
            export \
                HEADSCALE_ARCH=arm64 \
                HEADSCALE_SHA256=ecf0099f9aa1efb56e7c74718342a493f7d44a840626a2877ca526e675040f4e \
            ; \
            ;; \
        esac; \
        wget -q -O headscale https://github.com/juanfont/headscale/releases/download/v${HEADSCALE_VERSION}/headscale_${HEADSCALE_VERSION}_linux_${HEADSCALE_ARCH}; \
        echo "${HEADSCALE_SHA256} *headscale" | sha256sum -c - >/dev/null 2>&1; \
        chmod +x headscale; \
        mv headscale /usr/local/bin/; \
    }; \
    # smoke test
    [ "$(command -v headscale)" = '/usr/local/bin/headscale' ]; \
    headscale version

# ---
# copy configuration and templates
COPY ./container/headscale.yaml /etc/headscale/config.yaml
COPY ./container/policy.json /etc/headscale/policy.json
COPY ./container/litestream.yml /etc/litestream.yml
COPY ./container/entrypoint.sh /entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/app/data/headscale.db", "/usr/local/bin/headscale", "serve"]
