FROM ubuntu:22.04

# Evita prompts interactivos al instalar paquetes
ENV DEBIAN_FRONTEND=noninteractive

# Instalar algo básico (opcional, según lo que pida el ejercicio)
RUN apt-get update && apt-get install -y nano curl && rm -rf /var/lib/apt/lists/*

# Crear el directorio donde vamos a persistir datos
RUN mkdir /data

# Definir el volumen (indica que esa ruta se puede montar externamente)
VOLUME /data

# Mantener el contenedor corriendo
# CMD ["tail", "-f", "/dev/null"]
RUN apt-get update && apt-get install -y docker.io && rm -rf /var/lib/apt/lists/*

COPY menu.sh /menu.sh
RUN chmod +x /menu.sh

CMD ["/menu.sh"]
