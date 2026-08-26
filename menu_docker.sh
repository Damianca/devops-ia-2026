#!/bin/bash

while true; do
    echo "=============================="
    echo "       MENÚ DOCKER            "
    echo "=============================="
    echo "A. Listar imágenes"
    echo "B. Listar contenedores corriendo"
    echo "C. Listar todos los contenedores"
    echo "D. Ingresar a un contenedor por ID"
    echo "E. Salir"
    echo "------------------------------"
    read -p "Elija una opción: " opcion

    case $opcion in
        [Aa]) docker images ;;
        [Bb]) docker ps ;;
        [Cc]) docker ps -a ;;
        [Dd]) 
            read -p "Ingrese el ID o nombre del contenedor: " cont_id
            docker exec -it "$cont_id" /bin/sh 
            ;;
        [Ee]) 
            echo "Saliendo..."
            exit 0 
            ;;
        *) echo "Opción inválida. Intente de nuevo." ;;
    esac
    echo ""
done
