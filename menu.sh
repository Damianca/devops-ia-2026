#!/bin/bash

while true
do
    echo "=============================="
    echo "       MENU DE DOCKER"
    echo "=============================="
    echo "A. Listar imágenes"
    echo "B. Listar contenedores corriendo"
    echo "C. Listar todos los contenedores"
    echo "D. Ingresar a un contenedor"
    echo "E. Salir"
    echo "=============================="

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
            read -p "Ingrese el ID del contenedor: " id
            docker exec -it "$id" sh
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
    read -p "Presione ENTER para continuar..."
    clear
done
