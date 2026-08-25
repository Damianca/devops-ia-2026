FROM ubuntu:latest

RUN apt update && apt install -y docker.io

WORKDIR /app

COPY menu.sh /app/menu.sh

RUN chmod +x /app/menu.sh

CMD ["/bin/bash", "/app/menu.sh"]
