# cinny-deploy

Deployment-Konfiguration für [Cinny](https://github.com/cinnyapp/cinny) —
ein unabhängiger, schlanker Matrix-Web-Client (Alternative zu Element/Riot).
Verbindet sich direkt per Matrix-Client-Server-API mit dem eigenen
Homeserver unter `matrix.bravokilo.cloud`, kein eigener Backend-Prozess.

Kein Websocket-Bedarf: das Matrix-Sync-Protokoll (`GET /_matrix/client/*/sync`)
ist von Grund auf HTTP-Long-Polling, nicht WebSocket-basiert — das gilt für
jeden Standard-Matrix-Client (Element, Cinny, ...), nicht nur für dieses
Deployment.

## Deployment

Wie die anderen Docker-Projekte: über Portainer auf dem Docker-Host
(`192.168.40.251`), dahinter Nginx Proxy Manager für die öffentliche Domain
(`charlie.bravokilo.cloud`).

```bash
docker compose up -d
```

`config.json` legt `matrix.bravokilo.cloud` als Standard-Homeserver fest
(Login mit anderem Server bleibt über `allowCustomHomeservers` weiterhin
möglich).
