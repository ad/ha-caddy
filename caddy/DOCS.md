# Home Assistant Add-on: Caddy

Reverse proxy на Caddy с автоматическим выпуском TLS-сертификатов
от Let's Encrypt.

## Что делает аддон

1. Слушает порты 80, 443 (TCP) и 443 (UDP / HTTP-3).
2. Для каждого описанного домена сам получает сертификат через ACME
   (HTTP-01 / TLS-ALPN-01) и продлевает его.
3. Проксирует запросы на указанный внутренний `host:port`.

Сертификаты и аккаунт ACME хранятся в `/data/caddy/` и переживают
перезапуски и обновления аддона.

## Что нужно до установки

- Публичный домен с A-записью на ваш внешний IP (например, DuckDNS).
- На роутере проброшены порты **80/tcp** и **443/tcp** на хост с
  Home Assistant. 80 нужен для ACME HTTP-01 challenge.

## Опции

### `email` (необязательно)

Email для аккаунта ACME. Let's Encrypt рекомендует указывать — на него
приходят уведомления об истекающих сертификатах. Без email используется
ZeroSSL по умолчанию.

### `log_level`

Уровень логирования Caddy: `debug`, `info` (по умолчанию), `warn`,
`error`.

### `access_log` / `access_log_roll_size_mb` / `access_log_roll_keep`

Если `true` (по умолчанию) — на каждый прокси создаётся access-лог в
`/data/logs/<domain>.log` в формате JSON. Ротация по размеру:
`access_log_roll_size_mb` MiB (10 по умолчанию), хранится последних
`access_log_roll_keep` файлов (5 по умолчанию).

### `proxies` (список)

Каждый элемент:

| Поле | Тип | Описание |
|------|-----|----------|
| `domain` | string | Публичный домен (например, `home.example.com`). |
| `upstream` | string | Куда проксировать: `host:port` (например, `192.168.1.10:8123`). |
| `tls` | bool, optional | `false` → выписать самоподписанный сертификат (`tls internal`) вместо Let's Encrypt. Полезно для локального тестирования. По умолчанию `true`. |
| `security_headers` | bool, optional | Добавить базовые security-заголовки: HSTS (1 год + subdomains), X-Content-Type-Options, Referrer-Policy. Также скрывает заголовок `Server`. По умолчанию `false`. Включайте только если бэкенд сам не ставит эти заголовки или совместим с HSTS. |

### `extra_caddyfile` (необязательно)

Произвольный фрагмент Caddyfile, который дописывается в конец
сгенерированного конфига. Используйте для продвинутых сценариев
(matchers, headers, basic auth и т.п.).

## Пример

```yaml
email: you@example.com
log_level: info
proxies:
  - domain: home.example.com
    upstream: 192.168.1.10:8123
  - domain: grafana.example.com
    upstream: 192.168.1.20:3000
  - domain: dev.local
    upstream: 127.0.0.1:8000
    tls: false
extra_caddyfile: |
  files.example.com {
      root * /share
      file_server browse
  }
```

## Проверка работы

1. После старта в логах должна появиться строка
   `serving initial configuration`.
2. При первом запросе на `https://домен` Caddy запросит сертификат —
   в логах появится `obtained certificate`.
3. После перезапуска аддона сертификат **не** запрашивается заново
   (он лежит в `/data/caddy/...`).

## Известные ограничения

- Только HTTP/HTTPS-проксирование. TCP/UDP stream (например, SSH или
  MQTT через TLS-SNI) не поддерживается.
- Только HTTP-01 / TLS-ALPN-01 challenges. DNS-01 (для wildcard
  и закрытых сетей) не поддерживается в текущей версии.
