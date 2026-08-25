#!/bin/bash

while true
do
        echo "A - Listar Imagenes"
        echo "B - Listar contenedores corriendo"
        echo "C - Listar todos los contenedores"
        echo "D - Ingresar a un contenedor ingresando su ID:"
        echo "E - Salir"

        read -p "Seleccione una opcion:" opc
        case "$opc" in
                A|a) docker images ;;
                B|b) docker ps ;;
                C|c) docker ps -a ;;
                D|d) read -p "Ingrese su ID" id
		   docker exec -it "$id" bash 
		   ;;
                E|e) exit ;;
		*)
		 echo "Opcion incorrecta"
		 ;; 
        esac
done
