#!/usr/bin/env bash
set -euo pipefail

DB=${1:?usage: geoip-download.sh <output.mmdb>}
mkdir -p "$(dirname "${DB}")"

year=$(date -u +%Y)
month=$((10#$(date -u +%m)))
# The current month's file appears a few days into the month.
for _ in 0 1 2; do
    ym=$(printf '%d-%02d' "${year}" "${month}")
    if curl -fsS --max-time 300 "https://download.db-ip.com/free/dbip-city-lite-${ym}.mmdb.gz" \
        | gunzip > "${DB}" 2>/dev/null && [[ $(wc -c < "${DB}") -gt 10000000 ]]; then
        echo "GeoIP database: ${ym}"
        exit 0
    fi
    month=$((month - 1))
    if [[ ${month} -eq 0 ]]; then month=12; year=$((year - 1)); fi
done
echo "GeoIP database download failed for the last three months" >&2
exit 1
