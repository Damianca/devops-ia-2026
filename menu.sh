#!/bin/bash

while true; do
    echo "========================================="
    echo "          MENÚ DOCKER - TP               "
    echo "========================================="
    echo "A. Listar imágenes"
    echo "B. Listar contenedores corriendo"
    echo "C. Listar todos los contenedores"
    echo "D. Ingresar a un contenedor por su ID"
    echo "E. Salir"
    echo "========================================="
    read -p "Elige una opción: " opcion

    case $opcion in
        A|a) 
            echo "--- Imágenes Locales ---"
            docker images 
            ;;
        B|b) 
            echo "--- Contenedores Corriendo ---"
            docker ps 
            ;;
        C|c) 
            echo "--- Todos los Contenedores ---"
            docker ps -a 
            ;;
        D|d)
            read -p "Ingresa el ID del contenedor: " container_id
            docker exec -it $container_id /bin/sh
            ;;
        E|e)
            echo "Saliendo del menú..."
            break
            ;;
        *) 
            echo "Opción no válida. Intenta con A, B, C, D o E." 
            ;;
    esac
    echo "" 
done

