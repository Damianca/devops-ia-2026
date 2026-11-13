# Tarea 01-Sep-26

## Construir la imagen
```bash
docker build -t mi-web .
```

## Ejecutar el contenedor (con volumen)
```bash
docker run -d --name mi_web -p 8080:80 -v html_data:/usr/share/nginx/html mi-web
```

## Verificar
Abrir en el navegador: http://localhost:8080

## Detener y limpiar
```bash
docker stop mi_web
docker rm mi_web
docker volume rm html_data
```
