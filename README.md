# cinny-deploy

Deployment configuration for [Cinny](https://github.com/cinnyapp/cinny) —
an independent, lightweight Matrix web client (an alternative to
Element/Riot). Talks straight to a Matrix homeserver over the
Client-Server API; no backend process of its own.

No WebSocket needed anywhere: Matrix's sync protocol
(`GET /_matrix/client/*/sync`) is HTTP long-polling by design, not
WebSocket-based — true for every standard Matrix client (Element, Cinny,
...), not something specific to this deployment.

This repo is generic — it doesn't hardcode anyone's server, domain, or IP.
Point it at whichever homeserver you run.

## Which homeserver does it use?

Resolved once, at container startup, by `entrypoint.sh`, in this order:

1. **`HOMESERVER_URL` env var**, if you set one — always wins, skips
   auto-detection entirely. Set it in `docker-compose.yml` or a `.env`
   file alongside it to whatever your homeserver's domain is (e.g.
   `matrix.example.com`).
2. **Auto-detect via the Docker socket** (only if you keep the
   `docker.sock` volume mount in `docker-compose.yml`): looks at sibling
   containers on the same Docker host for a well-known homeserver image
   (Synapse, Dendrite, Conduit/Conduwuit) and reads its
   `SYNAPSE_SERVER_NAME` environment variable — the official
   `matrixdotorg/synapse` image's own config knob for this. Matrix's
   `.well-known/matrix/client` discovery means the bare server name is
   enough; Cinny/matrix-js-sdk resolves the real API endpoint itself.
3. **Neither**: ships with an empty homeserver list. Cinny's own login
   screen still lets anyone type in a homeserver by hand
   (`allowCustomHomeservers` stays on) — a startup script has no one to
   prompt, so this is the manual fallback for whoever opens the page.

Mounting the Docker socket is a real privilege to hand a container, even
read-only — it's optional, off by default is also a legitimate choice.
Without it, auto-detection just doesn't run; `HOMESERVER_URL` or the
in-app login screen work exactly the same either way.

## Deploy

```bash
cp .env.example .env   # set HOST_PORT / HOMESERVER_URL if you want the manual path
docker compose up -d --build
```

Reachable at `http://<docker-host>:<HOST_PORT>` (default `8095`), until you
put a reverse proxy in front of it for a real domain.
