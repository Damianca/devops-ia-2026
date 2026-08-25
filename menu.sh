#!/bin/bash
# Menú interactivo para gestionar contenedores Docker del host

while true; do
    echo "===================="
    echo " MENÚ DOCKER"
    echo "===================="
    echo "A. Listar imágenes"
    echo "B. Listar contenedores corriendo"
    echo "C. Listar todos los contenedores"
    echo "D. Ingresar a un contenedor por ID"
    echo "E. Salir"
    echo "===================="
    read -p "Elegí una opción: " opcion

    case $opcion in
        A|a)
            docker images
            ;;
        B|b)
            docker ps
            ;;
        C|c)
            docker ps -a
            ;;
        D|d)
            read -p "Ingresá el ID del contenedor: " id
            docker exec -it "$id" sh   # "sh" en vez de "bash": muchas imágenes base no traen bash instalado
            ;;
        E|e)
            echo "Saliendo..."
            break
            ;;
        *)
            echo "Opción inválida"
            ;;
    esac
    echo ""
done
