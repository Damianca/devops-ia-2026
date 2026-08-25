FROM alpine:latest

# Instalar bash y cliente de Docker
RUN apk update && \
    apk add --no-cache bash docker-cli

# Crear directorio de trabajo
WORKDIR /app

# Crear directorio para persistencia de datos
RUN mkdir -p /data
VOLUME ["/data"]

# Copiar el menú al contenedor
COPY opciones.sh /app/opciones.sh
RUN chmod +x /app/opciones.sh

# Ejecutar el menú al iniciar el contenedor
ENTRYPOINT ["/app/opciones.sh"]
