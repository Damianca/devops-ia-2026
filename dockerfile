FROM docker:cli

RUN apk update && \
    apk add --no-cache bash curl

WORKDIR /datos

COPY ./menu.sh /datos/menu.sh

ENV DOCKER_HOST=unix:///var/run/docker.sock

CMD ["bash", "menu.sh"]
