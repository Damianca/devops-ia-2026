#!/bin/bash

while true; do
    echo "========================================"
    echo "         MENÚ DOCKER"
    echo "========================================"
    echo "A. Listar imágenes"
    echo "B. Listar contenedores corriendo"
    echo "C. Listar todos los contenedores"
    echo "D. Ingresar a un contenedor"
    echo "E. Salir"
    echo "========================================"
    read -p "Seleccione una opción: " opcion

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
            read -p "Ingrese el ID del contenedor: " id_contenedor
            docker exec -it "$id_contenedor" /bin/bash
            ;;
        E|e)
            echo "Saliendo..."
            exit 0
            ;;
        *)
            echo "Opción inválida. Intente nuevamente."
            ;;
    esac
    echo ""
done
