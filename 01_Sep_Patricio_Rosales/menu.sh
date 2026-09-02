#!/bin/bash

VOLUMEN="/var/snap/docker/common/var-lib-docker/volumes/mi_volumen/_data/index.html"

while true
do
    clear

    echo "=============================="
    echo "       MENU HTML DOCKER"
    echo "=============================="
    echo "1. Editar HTML"
    echo "2. Ver HTML"
    echo "3. Restaurar HTML básico"
    echo "4. Salir"
    echo "=============================="

    read -p "Elegí una opción: " opcion

    case $opcion in

        1)
            sudo nano "$VOLUMEN"
            ;;

        2)
            clear
            sudo cat "$VOLUMEN"
            echo ""
            read -p "Presioná ENTER para continuar..."
            ;;

        3)
            sudo tee "$VOLUMEN" > /dev/null <<'EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Docker</title>
</head>
<body>
    <h1>Hola San Francisco 🌉</h1>
    <p>Esto es Docker.</p>
</body>
</html>
EOF

            echo "HTML restaurado."
            sleep 2
            ;;

        4)
            echo "Saliendo..."
            exit 0
            ;;

        *)
            echo "Opción inválida."
            sleep 2
            ;;

    esac
done
