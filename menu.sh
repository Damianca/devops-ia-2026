#!/bin/bash

while true
do
    echo "======================"
    echo "A. Listar imágenes"
    echo "B. Contenedores corriendo"
    echo "C. Todos los contenedores"
    echo "D. Entrar a un contenedor"
    echo "E. Salir"
    echo "======================"

    read -p "Opción: " opcion

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
            read -p "ID del contenedor: " id
            docker exec -it "$id" bash
            ;;
        E|e)
            exit
            ;;
    esac
done
