FROM debian:bookworm-slim
LABEL maintainer="Tomas"
RUN apt-get update && apt-get install -y --no-install-recommends apache2 && rm -rf /var/lib/apt/lists/*
EXPOSE 80
CMD ["apachectl", "-D", "FOREGROUND"]
