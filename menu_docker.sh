#!/bin/bash
while true; do
  echo ""
  echo "===== MENÚ DOCKER ====="
  echo "A. Listar imágenes"
  echo "B. Listar contenedores en ejecución"
  echo "C. Listar todos los contenedores"
  echo "D. Ingresar a un contenedor"
  echo "E. Salir"
  read -p "Opción: " op
  case "${op,,}" in
    a) docker images ;;
    b) docker ps ;;
    c) docker ps -a ;;
    d) read -p "ID o nombre del contenedor: " c
       docker exec -it "$c" /bin/sh ;;
    e) echo "Saliendo..."; break ;;
    *) echo "Opción inválida" ;;
  esac
done
