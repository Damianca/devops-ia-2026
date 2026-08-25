FROM alpine:latest

# Instalamos bash y el cliente de docker
RUN apk update && apk add --no-cache bash docker-cli

# Creamos la carpeta de trabajo y el directorio para persistir datos
WORKDIR /app
RUN mkdir -p /app/datos_persistentes

# Copiamos nuestro script de menú
COPY menu.sh /app/menu.sh
RUN chmod +x /app/menu.sh

# Comando por defecto para arrancar
CMD ["/bin/bash", "/app/menu.sh"]

