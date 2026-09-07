# Tarea 01-Sep-26 - Servidor Apache con volumen

## Descripción
Contenedor con Apache que sirve el index.html mediante un volumen.

## Requisitos
- Docker instalado.
- Puerto 8080 libre (si está ocupado, cambiar el 8080 del `-p` en el paso de Run).

## Build
Parado en esta carpeta:
```bash
docker build -t web_galleguillo .
```

## Run
```bash
docker run -d -p 8080:80 \
  -v $(pwd)/html:/var/www/html \
  --name servidor_web_galleguillo \
  web_galleguillo
```
`-v $(pwd)/html:/var/www/html` monta la carpeta `html/` como volumen dentro
del contenedor — el HTML se sirve desde ahí, no desde la imagen.

## Verificar
```bash
docker ps
curl http://localhost:8080
```

## Detener / volver a levantar
```bash
docker stop servidor_web_galleguillo
docker start servidor_web_galleguillo
```
