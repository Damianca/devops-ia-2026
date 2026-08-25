#!/bin/bash
while true; do
    echo "===================="
    echo "   MENU DOCKER      "
    echo "===================="
    echo "A. Listar imágenes"
    echo "B. Listar contenedores corriendo"
    echo "C. Listar todos los contenedores"
    echo "D. Ingresar a un contenedor ingresando su ID"
    echo "E. Salir"
    read -p "Seleccione una opción: " opcion

    case $opcion in
        [Aa])
            docker images
            ;;
        [Bb])
            docker ps
            ;;
        [Cc])
            docker ps -a
            ;;
        [Dd])
            read -p "Ingrese el ID del contenedor: " id
            docker exec -it $id sh || docker exec -it $id bash
            ;;
        [Ee])
            echo "Saliendo..."
            exit 0
            ;;
        *)
            echo "Opción inválida. Intente de nuevo."
            ;;
    esac
    echo ""
done
