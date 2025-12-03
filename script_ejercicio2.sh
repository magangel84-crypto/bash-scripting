#!/bin/bash

# intervalo de tiempo de ejecucion del comando free
intervalo=5
umbral_critico=30 # % maximo de memoria en uso
directorioValido="0"

# Solicitamos al usuario que ingrese un directorio existente y que contenga al menos un archivo
while [ -z "$directorio" ] || [ "$directorioValido" != "1" ]; do
    echo -e "El nombre del directorio es obligatorio"
    read -p "Ingrese el nombre del directorio: " directorio
      if [ ! -d "$directorio" ]; then
        echo -e "$Error: '$directorio' no es un directorio"
        directorioValido="0"
      else
        directorioValido="1"
      fi
done


monitoreo_memoria(){
        while true; do
                used_memory=$(free -m | awk 'NR==2{print $3}')
                total_memory=$(free -m | awk 'NR==2{print $2}')
                percent_used=$(($(($used_memory * 100)) / $(($total_memory))))
        echo "used: memory: $used_memory"
        echo "total_memory: $total_memory"
        echo "porcentaje de memoria utilizado: $percent_used"
        if [ "$percent_used" -gt "$umbral_critico" ];then
              timestamp=$(date '+%Y-%m-%d_%H-%M-%S')
              archivo_log="${directorio}/${timestamp}_memory_report.log"
              echo "-- Se ha generado el archivo: ${archivo_log}" 

              salida=$(ps aux --sort=-%mem | head -11)

              if [ -f "$archivo_log" ]; then
               echo "$salida" >> "$archivo_log"
              else
               echo "$salida" > "$archivo_log"
              fi
        fi

        sleep $intervalo
        done
}

monitoreo_memoria
