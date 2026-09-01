#!/bin/bash

while true
do
    echo "=========================="
    echo "       MENU DOCKER"
    echo "=========================="
    echo "A. Listar imágenes"
    echo "B. Listar contenedores corriendo"
    echo "C. Listar todos los contenedores"
    echo "D. Ingresar a un contenedor"
    echo "E. Salir"
    echo "=========================="

    read -p "Elegí una opción: " opcion

    case $opcion in

        A|a)
            sudo docker images
            ;;

        B|b)
            sudo docker ps
            ;;

        C|c)
            sudo docker ps -a
            ;;

        D|d)
            read -p "Ingresá el ID del contenedor: " id
            sudo docker exec -it "$id" /bin/sh
            ;;

        E|e)
            echo "Saliendo..."
            exit 0
            ;;

        *)
            echo "Opción inválida"
            ;;

    esac

    echo ""
    read -p "Presioná ENTER para continuar..."
    clear
done
