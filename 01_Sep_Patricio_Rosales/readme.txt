# Docker Apache - Córdoba

## Requisitos

- Docker instalado.
- Puerto 8080 disponible.

## Construir la imagen

Desde esta carpeta ejecutar:

```bash
sudo docker build -t mi-apache:latest .

sudo docker volume create mi_volumen

sudo docker run -d \
    --name mi-apache \
    -p 8080:80 \
    -v mi_volumen:/var/www/html \
    mi-apache:latest


hay un menu para cambiar el html desde el host

