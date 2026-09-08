FROM debian:bookworm-slim
LABEL maintainer="yo"
RUN apt-get update \
  && apt-get install -y --no-install-recommends apache2 \
  && rm -rf /var/lib/apt/lists/*
COPY web_data/index.html /var/www/html/index.html
COPY web_data/cordoba.jpg /var/www/html/cordoba.jpg
EXPOSE 80
CMD ["apachectl", "-D", "FOREGROUND"]
