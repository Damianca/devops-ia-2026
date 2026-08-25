#!/bin/bash

mostrar_menu() {
    echo ""
    echo "===== MENU DOCKER ====="
    echo "A. Listar imagenes"
    echo "B. Listar contenedores corriendo"
    echo "C. Listar todos los contenedores"
    echo "D. Ingresar a un contenedor por ID"
    echo "E. Salir"
    echo "========================"
}

while true; do
    mostrar_menu
    read -rp "Elegi una opcion: " opcion
    case "$opcion" in
        A|a) docker images ;;
        B|b) docker ps ;;
        C|c) docker ps -a ;;
        D|d)
            read -rp "Ingresa el ID del contenedor: " id_contenedor
            docker exec -it "$id_contenedor" bash || docker exec -it "$id_contenedor" sh
            ;;
        E|e) echo "Saliendo..."; exit 0 ;;
        *) echo "Opcion invalida." ;;
    esac
done
