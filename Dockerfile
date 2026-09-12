# config.json is generated at container startup by entrypoint.sh, not baked
# in at build time -- that's what lets this image work for any homeserver
# without editing this repo. curl+jq are needed only for the optional
# Docker-socket auto-detection step; harmless if that path is never used.
FROM ajbura/cinny:latest

RUN apk add --no-cache curl jq

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
