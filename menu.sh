#!/bin/bash

while true; do
    echo "===== MENU DOCKER ====="
    echo "A. Listar imágenes"
    echo "B. Listar contenedores corriendo"
    echo "C. Listar todos los contenedores"
    echo "D. Ingresar a un contenedor ingresando su ID"
    echo "E. Salir"
    echo "========================"
    read -p "Elegí una opción: " opcion

    case $opcion in
        A|a) docker images ;;
        B|b) docker ps ;;
        C|c) docker ps -a ;;
        D|d)
            read -p "Ingresá el ID del contenedor: " id_contenedor
            docker exec -it "$id_contenedor" sh
            ;;
        E|e) echo "Saliendo..."; break ;;
        *) echo "Opción inválida" ;;
    esac
    echo ""
done
