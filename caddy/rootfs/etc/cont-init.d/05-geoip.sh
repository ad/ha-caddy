#!/usr/bin/with-contenv bashio
if bashio::config.true 'geoip' && [[ ! -s /data/geoip/DBIP-City-Lite.mmdb ]]; then
    geoip-update || bashio::log.warning "GeoIP database unavailable, geoip2.* placeholders stay empty."
fi
