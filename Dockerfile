FROM alpine:latest
 
# Instala bash (Alpine trae por defecto solo /bin/sh = ash)
RUN apk add --no-cache bash
 
# Directorio para persistir datos con el volumen
RUN mkdir -p /data
WORKDIR /data
 
# Mantiene el contenedor corriendo en segundo plano (si lo corres con -d)
CMD ["bash"]
