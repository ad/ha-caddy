#!/usr/bin/with-contenv bashio
# ==============================================================================
# Generates /opt/ha-caddy/web/index.html — status page served via HA Ingress.
# ==============================================================================
set -e

WEB_DIR="/opt/ha-caddy/web"
HTML="${WEB_DIR}/index.html"
mkdir -p "${WEB_DIR}"

cert_info() {
    local domain="$1"
    local crt
    crt=$(find /data/caddy -path "*/${domain}/${domain}.crt" 2>/dev/null | head -n1)
    if [[ -z "${crt}" ]]; then
        echo "не выписан"
        return
    fi
    local enddate issuer
    enddate=$(openssl x509 -in "${crt}" -noout -enddate 2>/dev/null | cut -d= -f2)
    issuer=$(openssl x509 -in "${crt}" -noout -issuer 2>/dev/null \
        | sed 's/.*CN *= *//; s/,.*//')
    [[ -z "${enddate}" ]] && enddate="?"
    [[ -z "${issuer}" ]] && issuer="?"
    printf 'до %s (%s)' "${enddate}" "${issuer}"
}

esc() {
    # minimal HTML escape
    local s="$1"
    s="${s//&/&amp;}"
    s="${s//</&lt;}"
    s="${s//>/&gt;}"
    s="${s//\"/&quot;}"
    echo "${s}"
}

CADDY_VERSION=$(caddy version 2>/dev/null | awk '{print $1}')
GENERATED_AT=$(date -u '+%Y-%m-%d %H:%M:%S UTC')

PATH_ROUTES_RAW=""
if bashio::config.has_value 'path_routes'; then
    PATH_ROUTES_RAW=$(bashio::config 'path_routes')
fi

routes_for_domain() {
    local d="$1"
    [[ -z "${PATH_ROUTES_RAW}" ]] && return
    printf '%s\n' "${PATH_ROUTES_RAW}" | awk -v d="${d}" '
        /^[[:space:]]*$/ { next }
        /^[[:space:]]*#/ { next }
        { if ($1 == d && NF >= 3) printf "%s\t%s\n", $2, $3 }
    '
}

{
    cat <<HEAD
<!doctype html>
<html lang="ru">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Caddy — статус</title>
<style>
  :root { color-scheme: light dark; }
  body { font-family: -apple-system, system-ui, sans-serif; max-width: 960px;
         margin: 1.5rem auto; padding: 0 1rem; line-height: 1.45; }
  h1 { margin: 0 0 .25rem; font-size: 1.4rem; }
  .meta { color: #888; font-size: .85rem; margin-bottom: 1.25rem; }
  table { width: 100%; border-collapse: collapse; font-size: .9rem; }
  th, td { padding: .5rem .6rem; border-bottom: 1px solid rgba(127,127,127,.25);
           text-align: left; vertical-align: top; }
  th { font-weight: 600; background: rgba(127,127,127,.08); }
  code { font-family: ui-monospace, Menlo, Consolas, monospace; font-size: .85em; }
  .tag { display: inline-block; padding: .05rem .35rem; border-radius: 4px;
         font-size: .75rem; background: rgba(127,127,127,.15); }
  .ok { color: #2a8f3a; }
  .warn { color: #b86b00; }
  details { margin-top: 1rem; }
  summary { cursor: pointer; color: #888; }
  pre { background: rgba(127,127,127,.1); padding: .6rem; overflow-x: auto;
        border-radius: 4px; font-size: .8rem; }
</style>
</head>
<body>
<h1>Caddy reverse proxy</h1>
<div class="meta">${CADDY_VERSION} · обновлено $(esc "${GENERATED_AT}")</div>

<table>
<thead>
<tr><th>Домен</th><th>Куда проксирует</th><th>Сертификат</th><th>Флаги</th></tr>
</thead>
<tbody>
HEAD

    if bashio::config.has_value 'proxies'; then
        for index in $(bashio::config 'proxies|keys'); do
            domain=$(bashio::config "proxies[${index}].domain")
            [[ -z "${domain}" ]] && continue

            default_upstream=$(bashio::config "proxies[${index}].upstream" || true)
            cert=$(cert_info "${domain}")

            # build upstream cell
            upstream_cell=""
            routes_text=$(routes_for_domain "${domain}")
            if [[ -n "${routes_text}" ]]; then
                while IFS=$'\t' read -r rpath rup; do
                    [[ -z "${rpath}" ]] && continue
                    upstream_cell+="<code>$(esc "${rpath}")</code> → <code>$(esc "${rup}")</code><br>"
                done <<< "${routes_text}"
                if bashio::var.has_value "${default_upstream}"; then
                    upstream_cell+="<code>/*</code> → <code>$(esc "${default_upstream}")</code>"
                fi
            else
                upstream_cell="<code>$(esc "${default_upstream}")</code>"
            fi

            # flags
            flags=""
            if bashio::config.true "proxies[${index}].security_headers"; then
                flags+='<span class="tag">security headers</span> '
            fi
            if bashio::config.has_value "proxies[${index}].rate_limit_events" \
                && bashio::config.has_value "proxies[${index}].rate_limit_window"; then
                rl_events=$(bashio::config "proxies[${index}].rate_limit_events")
                rl_window=$(bashio::config "proxies[${index}].rate_limit_window")
                flags+="<span class=\"tag\">rate-limit $(esc "${rl_events}")/$(esc "${rl_window}")</span> "
            fi
            if bashio::config.exists "proxies[${index}].tls" \
                && bashio::config.false "proxies[${index}].tls"; then
                flags+='<span class="tag warn">tls internal</span> '
            fi

            cert_class="ok"
            [[ "${cert}" == "не выписан" ]] && cert_class="warn"

            printf '<tr><td><code>%s</code></td><td>%s</td><td class="%s">%s</td><td>%s</td></tr>\n' \
                "$(esc "${domain}")" "${upstream_cell}" "${cert_class}" "$(esc "${cert}")" "${flags}"
        done
    else
        echo '<tr><td colspan="4"><em>Нет настроенных прокси.</em></td></tr>'
    fi

    cat <<'TAIL'
</tbody>
</table>

<details>
<summary>Где лежат сертификаты и логи</summary>
<pre>
сертификаты: /data/caddy/certificates/
access-логи: /data/logs/&lt;domain&gt;.log (JSON, ротация)
конфиг:      /etc/caddy/Caddyfile (auto-generated)
</pre>
</details>
</body>
</html>
TAIL
} > "${HTML}"

bashio::log.info "Status page generated at ${HTML}"
