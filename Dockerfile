FROM alpine:latest

# Instalamos bash y el cliente de docker en Alpine
RUN apk update && apk add --no-cache bash docker-cli

WORKDIR /app
COPY menu.sh /app/menu.sh
RUN chmod +x /app/menu.sh

CMD ["/bin/bash", "/app/menu.sh"]
