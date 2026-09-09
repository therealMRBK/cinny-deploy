# Baut config.json direkt ins offizielle Cinny-Image statt es per Volume zu
# mounten -- ein Bind-Mount von config.json scheiterte bei diesem Git-Stack-
# Deployment zuverlaessig ("not a directory", vermutlich ein Checkout-
# Timing-Problem bei Portainers Git-Stacks mit einzelnen Dateien statt
# ganzen Verzeichnissen). Ein eigenes, gebautes Image umgeht das komplett.
FROM ajbura/cinny:latest
COPY config.json /app/config.json
