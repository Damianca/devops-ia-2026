# Tarea 01-Sep - Despliegue con Volumen

1. Construir la imagen:
docker build -t web-volumen .

2. Correr el contenedor con el volumen montado:
docker run -d -p 8080:80 -v $(pwd)/index.html:/usr/share/nginx/html/index.html --name app-web-volumen web-volumen

3. Probar en el navegador:
http://localhost:8080
