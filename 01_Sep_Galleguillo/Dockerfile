FROM debian:bookworm-slim
LABEL maintainer="Lucas Galleguillo"

RUN apt-get update \
    && apt-get install -y --no-install-recommends apache2 \
    && rm -rf /var/lib/apt/lists/*

VOLUME ["/var/www/html"]

EXPOSE 80
CMD ["apachectl", "-D", "FOREGROUND"]
