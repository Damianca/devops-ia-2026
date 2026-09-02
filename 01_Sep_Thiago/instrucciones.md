#Instrucciones de ejecucion

##1) docker build -t mi-servidor-web

##2) docker run -d -p 80:80 --name servidor_web -v $(pwd):/var/www/html mi-servidor-web

##3) Ingresar a http://localhost:80
