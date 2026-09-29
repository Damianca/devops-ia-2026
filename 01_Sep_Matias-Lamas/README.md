# Tarea 01-Sep-26 - Servidor Apache con volumen

## Descripción

Contenedor con Apache que sirve el archivo `index.html` mediante un volumen.

El archivo HTML se encuentra en la carpeta `html/` del proyecto y se monta dentro del contenedor en `/var/www/html`.

## Estructura

```text
01_Sep_Matias-Lamas/
├── Dockerfile
├── README.md
└── html/
    └── index.html
```

## Requisitos

* Docker instalado.
* Puerto `8080` libre.

## Build

Parado en esta carpeta:

```bash
docker build -t web_matialamas .
```

Este comando construye la imagen `web_matialamas` utilizando el `Dockerfile`.

## Run

Crear y ejecutar el contenedor:

```bash
docker run -d -p 8080:80 -v $(pwd)/html:/var/www/html --name servidor_web_matialamas web_matialamas
```

### Explicación del volumen

```bash
-v $(pwd)/html:/var/www/html
```

Monta la carpeta `html/` de la computadora en `/var/www/html` dentro del contenedor.

De esta manera, Apache sirve el archivo `index.html` directamente desde la carpeta `html/`.

Los cambios realizados en `html/index.html` se reflejan en el navegador sin necesidad de reconstruir la imagen.

## Verificar

Comprobar que el contenedor esté ejecutándose:

```bash
docker ps
```

Abrir en el navegador:

```text
http://localhost:8080
```

También se puede verificar desde la terminal:

```bash
curl http://localhost:8080
```

## Detener

Para detener el contenedor:

```bash
docker stop servidor_web_matialamas
```

## Volver a levantar

Para volver a iniciar el contenedor detenido:

```bash
docker start servidor_web_matialamas
```

Luego acceder nuevamente desde el navegador:

```text
http://localhost:8080
```

