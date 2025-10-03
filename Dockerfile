# syntax=registry.docker.com/docker/dockerfile:1

ARG ALPINE_VERSION=3.22.1
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
        export HEADSCALE_VERSION=0.26.1; \
        case "$(arch)" in \
        x86_64) \
            export \
                HEADSCALE_ARCH=amd64 \
                HEADSCALE_SHA256=5012577e6fc5d4234aab7b4be0d6e271ea1a4ec38521a8aa472f80ea1fe81cba \
            ; \
            ;; \
        aarch64) \
            export \
                HEADSCALE_ARCH=arm64 \
                HEADSCALE_SHA256=98981ea52a96260f310433c73927935bf7628eedcc4c3f747059506154edba78 \
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
COPY ./container/litestream.yml /etc/litestream.yml
COPY ./container/entrypoint.sh /entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/app/data/headscale.db", "/usr/local/bin/headscale", "serve"]
