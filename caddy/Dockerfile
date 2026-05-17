# syntax=docker/dockerfile:1.7
ARG CADDY_VERSION=2.10.2
ARG RATELIMIT_VERSION=v0.1.0
ARG BUILD_FROM=ghcr.io/hassio-addons/base:20.1.1

# ---- Stage 1: build Caddy with plugins via official xcaddy image ----
FROM caddy:${CADDY_VERSION}-builder-alpine AS builder
ARG RATELIMIT_VERSION
RUN --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/go/pkg/mod \
    xcaddy build \
        --with github.com/mholt/caddy-ratelimit@${RATELIMIT_VERSION}

# ---- Stage 2: addon runtime ----
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3018
RUN apk add --no-cache --no-progress \
        ca-certificates \
        openssl \
    && mkdir -p /etc/caddy /data /opt/ha-caddy/web

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
COPY rootfs /

ENV \
    XDG_CONFIG_HOME=/data \
    XDG_DATA_HOME=/data

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
