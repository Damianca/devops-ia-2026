```bash
#!/bin/bash

while true
do
    echo "=========================="
    echo "       MENU DOCKER"
    echo "=========================="
    echo "A. Listar imágenes"
    echo "B. Contenedores en ejecución"
    echo "C. Todos los contenedores"
    echo "D. Ingresar a un contenedor"
    echo "E. Salir"
    echo "=========================="

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
            read -p "Ingrese el ID o nombre del contenedor: " contenedor
            docker exec -it "$contenedor" /bin/sh
            ;;

        E|e)
            echo "Saliendo del programa..."
            break
            ;;

        *)
            echo "Opción inválida."
            ;;
    esac

    echo ""
    read -p "Presione ENTER para continuar..."
    clear
done
```
