FROM nginx:alpine

# Copia el index.html a la carpeta que sirve nginx
COPY index.html /usr/share/nginx/html/index.html

# Declara esa carpeta como volumen
VOLUME /usr/share/nginx/html

EXPOSE 80
