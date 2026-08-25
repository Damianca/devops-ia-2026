# Imagen base: Alpine es una distro minimalista (~5MB), ideal para contenedores livianos
FROM alpine:3.20

# Instala el cliente de Docker (docker-cli) y bash (Alpine trae "ash" por defecto, no bash)
# --no-cache evita guardar el índice de paquetes descargado, para no dejar basura en la imagen
RUN apk add --no-cache docker-cli bash

# Copia el script del menú desde tu máquina hacia la raíz del contenedor
COPY menu.sh /menu.sh

# Le da permiso de ejecución al script dentro de la imagen
RUN chmod +x /menu.sh

# ENTRYPOINT define qué se ejecuta automáticamente al arrancar el contenedor
ENTRYPOINT ["/menu.sh"]
