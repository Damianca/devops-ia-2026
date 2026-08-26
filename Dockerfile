FROM docker:cli

RUN apk add --no-cache bash curl

WORKDIR /datos

COPY ./menu.sh /datos/menu.sh

CMD ["bash", "menu.sh"]
