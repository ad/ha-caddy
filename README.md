# Home Assistant Add-on: Caddy reverse proxy

Reverse proxy на [Caddy](https://caddyserver.com) с автоматическим выпуском
TLS-сертификатов от Let's Encrypt. Альтернатива
[Nginx Proxy Manager](https://github.com/hassio-addons/addon-nginx-proxy-manager)
без UI и БД — конфиг описывается прямо в опциях аддона.

## Установка

1. В Home Assistant: **Settings → Add-ons → Add-on Store → ⋮ → Repositories**.
2. Добавить URL этого репозитория.
3. Установить **Caddy** из появившегося раздела.
4. Открыть вкладку **Configuration**, задать `email` и список `proxies`.
5. Запустить аддон.

## Минимальный пример конфигурации

```yaml
email: you@example.com
proxies:
  - domain: home.example.com
    upstream: 192.168.1.10:8123
  - domain: grafana.example.com
    upstream: 192.168.1.20:3000
```

## Требования

- Домен с A-записью на ваш публичный IP.
- На роутере проброшены 80/tcp и 443/tcp на хост с HA.

Подробности — см. вкладку **Documentation** аддона или
[`caddy/DOCS.md`](caddy/DOCS.md).
