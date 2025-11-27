#!/bin/bash
# ------------------------
# Archivo: script_ejercicio1.sh
# Descripcion: Ejercicio 1 de practica Programacion en bash
# Materia: Administraciòn de Sistemas para la Cloud
# Autor: Miguel Angel Garcia
# Fecha 25/11/2025

desc+="#"$'\n'
desc+="#"$'\n'
desc+="# Script que permite cambiar los nombres de"$'\n'
desc+="# los archivos de un directorio especificado"$'\n'
desc+="# por el usuario"$'\n'
desc+="#"$'\n'
desc+="#"$'\n'

echo "$desc"

# Colores que se usan para diferentes mensajes que se envian al usuario por consola
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# solicitamos al usuario la captura del directorio
# read -p "Ingrese el nombre del directorio: " directorio

# definimos una variable para controlar la validez del directorio, 0 es invalido, 1 es valido
directorioValido="0"

# funcion para verificar si un directorio contiene al menos un archivo
tiene_archivos() {
    local dir="$1"
    
    if [ ! -d "$dir" ]; then
        echo -e "${RED}Error: '$dir' no es un directorio"
        return 2
    fi
    
    if find "$dir" -maxdepth 1 -type f -print -quit | grep -q .; then
        echo "Info: '$dir' SI tiene archivos"
        return 0  # Tiene archivos
    else
        echo "Info: '$dir' NO tiene archivos"
        return 1  # No tiene archivos
    fi
}

# Solicitamos al usuario que ingrese un directorio existente y que contenga al menos un archivo
while [ -z "$directorio" ] || [ "$directorioValido" != "1" ]; do
    echo -e "${GREEN}El nombre del directorio es obligatorio${NC}"
    read -p "Ingrese el nombre del directorio: " directorio

    if tiene_archivos "$directorio"; then
        directorioValido="1"
    else
        directorioValido="0"
    fi
done


# mostramos lo que existe dentro del directorio
contenido=$(ls -1 $directorio)
echo "Contenido del directorio:"$'\n'
echo "$contenido"

# Solicitamos al usuario que ingrese un prefijo de 3 caracteres 
while true; do
    read -p "Ingresa una cadena de 3 caracteres: " prefijo
    # Verificar longitud exacta de 3 caracteres
    if [ ${#prefijo} -eq 3 ]; then
        echo "Prefijo válido: '$prefijo'"
        break
    else
        echo -e "${RED}Error: El prefijo debe tener exactamente 3 caracteres (ingresaste ${#prefijo})"
    fi
done

echo "Prefijo almacenado: $prefijo"$'\n'

# verificamos que elementos dentro de directorio son archivos y cuales son directorios
echo "=== CLASIFICACIÓN DE ELEMENTOS ==="
ls -1 "$directorio" | while read elemento; do
    ruta_completa="$directorio/$elemento"

    if [ -d "$ruta_completa" ]; then
        echo "$elemento - DIRECTORIO"
    else
        echo "$elemento - ARCHIVO/OTRO"
        nombre_original=$(basename "$elemento")
        nuevo_nombre="${prefijo}_${nombre_original}"

        echo "Renombrando: $nombre_original a  $nuevo_nombre"
		mv "$ruta_completa" "$directorio/$nuevo_nombre"

    fi
done

