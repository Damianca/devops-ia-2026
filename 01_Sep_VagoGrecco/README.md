# Tarea 01-Sep-26 - Servidor Apache con volumen

## Requisitos
- Docker instalado. Comando:
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```
- Puerto 8080 libre (si está ocupado, cambiar el 8080 en el paso de Run).

## Build
Parado en esta carpeta:
```bash
docker build -t mi-web-app .
```

## Run
```bash
docker run -d -p 8080:80 \
  -v $(pwd)/web_data:/var/www/html \
  --name mi-web \
  mi-web-app
```

## Verificar
```bash
docker ps
curl http://localhost:8080
```

## Detener
```bash
docker stop mi-web
```

## Eliminar el contenedor
```bash
docker rm mi-web
```
