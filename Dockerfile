FROM alpine:latest

# Instala bash (Alpine trae por defecto solo /bin/sh = ash)
RUN apk add --no-cache bash

# Directorio para persistir datos con el volumen
RUN mkdir -p /data
WORKDIR /data

# Copiamos el script del menú
COPY menu.sh /app/menu.sh
RUN chmod +x /app/menu.sh

# Ejecuta el menú al iniciar el contenedor
CMD ["bash", "/app/menu.sh"]
