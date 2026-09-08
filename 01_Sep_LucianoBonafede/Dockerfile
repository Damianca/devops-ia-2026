FROM debian:bookworm-slim
LABEL maintainer="Luciano"
RUN apt-get update && apt-get install -y --no-install-recommends apache2 && rm -rf /var/lib/apt/lists/*
COPY . /var/www/html/
EXPOSE 80
CMD ["apachectl", "-D", "FOREGROUND"]
