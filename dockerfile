FROM docker:dind

RUN apk add --no-cache bash

WORKDIR /datos

COPY menu.sh /datos/menu.sh


ENV DOCKER_TLS_CERTDIR=""
ENV DOCKER_HOST=tcp://127.0.0.1:2375


CMD ["sh", "-c", "dockerd --host=tcp://127.0.0.1:2375 & sleep 3 && bash /datos/menu.sh"]
