FROM debian:bookworm-slim
LABEL maintainer="yo"
RUN apt-get update && apt-get install -y --no-install-recommends apache2 && rm -rf /var/lib/apt/lists/*
COPY index.html /var/www/html/index.html
EXPOSE 80
CMD ["apachectl", "-D", "FOREGROUND"]
