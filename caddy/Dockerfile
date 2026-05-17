ARG BUILD_FROM=ghcr.io/hassio-addons/base:18.2.0
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG CADDY_VERSION="2.10.2"

# hadolint ignore=DL3018,DL3003
RUN \
    apk add --no-cache \
        ca-certificates \
        openssl \
        wget \
    \
    && apk add --no-cache --virtual .build \
        go \
        git \
    \
    && export GOPATH=/tmp/go \
    && export PATH="${GOPATH}/bin:${PATH}" \
    && go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest \
    && cd /tmp \
    && xcaddy build "v${CADDY_VERSION}" \
        --with github.com/mholt/caddy-ratelimit \
        --output /usr/bin/caddy \
    \
    && apk del --purge .build \
    && rm -rf /tmp/* /root/.cache \
    && /usr/bin/caddy version \
    \
    && mkdir -p /etc/caddy /data /opt/ha-caddy/web

ENV \
    XDG_CONFIG_HOME=/data \
    XDG_DATA_HOME=/data

COPY rootfs /

EXPOSE 80 443 443/udp

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD pidof caddy >/dev/null || exit 1

ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION

LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version="${BUILD_VERSION}" \
    maintainer="ad <unsecuredregister@gmail.com>" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.source="${BUILD_REPOSITORY}" \
    org.opencontainers.image.revision="${BUILD_REF}" \
    org.opencontainers.image.created="${BUILD_DATE}" \
    org.opencontainers.image.version="${BUILD_VERSION}"
