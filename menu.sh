#!/bin/bash

while true; do
    echo -e "\n====================================="
    echo "          MENÚ DE DOCKER             "
    echo "====================================="
    echo "A. Listar imágenes"
    echo "B. Listar contenedores corriendo"
    echo "C. Listar todos los contenedores"
    echo "D. Ingresar a un contenedor (por ID)"
    echo "E. Salir"
    echo "====================================="
    read -p "Seleccione una opción [A-E]: " opcion

    case $opcion in
        [Aa])
            echo -e "\n--- Imágenes disponibles ---"
            docker images
            ;;
        [Bb])
            echo -e "\n--- Contenedores activos ---"
            docker ps
            ;;
        [Cc])
            echo -e "\n--- Todos los contenedores ---"
            docker ps -a
            ;;
        [Dd])
            read -p "Ingrese el ID del contenedor: " id_contenedor
            if [ -z "$id_contenedor" ]; then
                echo "ID inválido."
            else
                echo "Ingresando al contenedor $id_contenedor..."
                docker exec -it "$id_contenedor" /bin/bash || docker exec -it "$id_contenedor" /bin/sh
            fi
            ;;
        [Ee])
            echo "Saliendo del menú..."
            exit 0
            ;;
        *)
            echo "Opción incorrecta. Intente de nuevo."
            ;;
    esac
    
    echo -e "\nPresione ENTER para continuar..."
    read
done
