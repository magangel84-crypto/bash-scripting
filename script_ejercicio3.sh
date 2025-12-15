#!/usr/bin/env bash
#
# script_ejercicio3.sh
# Ejercicio 3 — Monitoreo de procesos en ejecución
#
# Funcionalidades:
#  - Mostrar todos los procesos en ejecución
#  - Buscar procesos por nombre (case-insensitive)
#  - Finalizar procesos solicitando el nombre y permitiendo escoger el/los PID(s)
#  - Menú interactivo
#
# Materia: Administraciòn de Sistemas para la Cloud
# Autor: Miguel Angel Garcia
# Fecha 25/11/2025

set -o errexit
set -o pipefail
set -o nounset

# funcion que limpia la pantalla para imprimir el menu
clear_screen() {
  printf "\033c"
}

# funcion que se invoca despues que el usuario selecciona una opcion del menu diferente de salir y refrescar pantalla
pause() {
  read -r -p "Presiona Enter para continuar..."
}

# funcion que pinta la primer linea de texto como encabezado del menu
print_header() {
  printf "\n====== Monitoreo de procesos (%s) ======\n\n" "$(date '+%Y-%m-%d %H:%M:%S')"
}


# funcion que lista los procesos que se estan ejecutando
list_processes() {
  print_header
  echo "Listando procesos (ps aux) ordenados por uso de CPU (desc):"
  printf "\n%8s %-8s %-6s %6s %6s %-6s %s\n" "PID" "USER" "CPU%" "VSZ" "RSS" "STAT" "COMMAND"
  ps aux --sort=-%cpu |
    awk 'NR>1 { printf("%8s %-8s %5s %6s %6s %-6s %s\n",$2,$1,$3,$5,$6,$8,substr($0,index($0,$11))) }'
  echo
  pause
}

# funcion que permite capturar el nombre o parte del nombre proceso a buscar 
search_processes() {
  read -r -p "Introduce el nombre (o parte) del proceso a buscar: " term
  if [[ -z "${term// }" ]]; then
    echo "Búsqueda vacía. Abortando."
    pause
    return
  fi

  print_header
  echo "Buscando procesos que coincidan con: '$term' (case-insensitive)"
  echo

  # pgrep -ifl muestra "pid full-command"
  mapfile -t results < <(pgrep -ifl -- "${term}" || true)

  if [[ ${#results[@]} -eq 0 ]]; then
    echo "No se encontraron procesos que coincidan con '$term'."
    pause
    return
  fi

  printf "%3s %8s %s\n" "#" "PID" "COMMAND"
  idx=1
  for r in "${results[@]}"; do
    pid=${r%% *}
    cmd=${r#* }
    printf "%3d %8s %s\n" "${idx}" "${pid}" "${cmd}"
    ((idx++))
  done
  echo
  pause
  }

  
# intenta terminar el PID con SIGTERM, si no responde en timeout, pregunta para SIGKILL
attempt_kill_pid() {
  local pid="$1"
  local timeout=${2:-5}  # segundos para esperar tras SIGTERM

  if ! kill -0 "$pid" 2>/dev/null; then
    echo "PID $pid no existe (ya finalizado)."
    return 0
  fi

  echo -n "Enviando SIGTERM a PID $pid... "
  if kill "$pid" 2>/dev/null; then
    echo "ok (SIGTERM enviado). Esperando ${timeout}s..."
    # esperar a que termine
    for ((i=0;i<timeout;i++)); do
      sleep 1
      if ! kill -0 "$pid" 2>/dev/null; then
        echo "PID $pid finalizó correctamente."
        return 0
      fi
    done
    
    echo "PID $pid sigue vivo después de ${timeout}s."
    read -r -p "¿Deseas forzar con SIGKILL a PID $pid? (s/N): " yn
    yn=${yn:-N}
    if [[ "$yn" =~ ^[Ss]$ ]]; then
      if kill -9 "$pid" 2>/dev/null; then
        echo "SIGKILL enviado a PID $pid."
        # breve espera
        sleep 1
        if ! kill -0 "$pid" 2>/dev/null; then
          echo "PID $pid eliminado."
          return 0
        else
          echo "No pudo eliminarse PID $pid tras SIGKILL."
          return 1
        fi
      else
        echo "Error al enviar SIGKILL (permiso o PID no válido)."
        return 1
      fi
    else
      echo "No se forzó el proceso."
      return 1
    fi
  else
    echo "no se pudo enviar SIGTERM (permiso o PID)."
    return 1
  fi
}

# recupera el nombre del proceso que se desea terminar
kill_by_name_interactive() {
  read -r -p "Introduce el nombre (o parte) del proceso a finalizar: " term
  if [[ -z "${term// }" ]]; then
    echo "Nombre vacío. Abortando."
    pause
    return
  fi

  # obtener coincidencias con pgrep -ifl
  mapfile -t results < <(pgrep -ifl -- "${term}" || true)

  if [[ ${#results[@]} -eq 0 ]]; then
    echo "No se encontraron procesos para '$term'."
    pause
    return
  fi
  printf "%3s %8s %s\n" "#" "PID" "COMMAND"
  idx=1
  for r in "${results[@]}"; do
    pid=${r%% *}
    cmd=${r#* }
    printf "%3d %8s %s\n" "${idx}" "${pid}" "${cmd}"
    ((idx++))
  done

  echo
  echo "Opciones:"
  echo "  - Ingresa el número (#) para finalizar ese PID específico."
  echo "  - Ingresa una lista de números separados por comas (ej. 1,3) para finalizar varios."
  echo "  - Ingresa 'a' para finalizar todos los listados (se pedirá confirmación)."
  echo "  - Ingresa 'c' para cancelar."
  read -r -p "Tu elección: " choice
  choice=${choice,,}  # lower
    if [[ "$choice" == "c" ]]; then
    echo "Operación cancelada."
    pause
    return
  fi

  if [[ "$choice" == "a" ]]; then
    read -r -p "CONFIRMA borrar TODOS los PIDs listados? (esto puede afectar al sistema) (s/N): " confirm
    confirm=${confirm:-N}
    if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
      echo "No confirmado. Abortando."
      pause
      return
    fi
    # recorrer todos
 for r in "${results[@]}"; do
       pid=${r%% *}
      echo "Procesando PID $pid..."
      attempt_kill_pid "$pid"
    done
    pause
    return
  fi

  # lista de números
  IFS=',' read -r -a nums <<<"$choice"
  for n in "${nums[@]}"; do
    n=$(echo "$n" | xargs)  # trim
    if ! [[ "$n" =~ ^[0-9]+$ ]]; then
      echo "Entrada inválida: '$n' (se esperaba un número)."
      continue
    fi
    # validar rango
    if (( n < 1 || n > ${#results[@]} )); then
      echo "Número fuera de rango: $n"
      continue
    fi
    selected="${results[$((n-1))]}"
    pid=${selected%% *}
    cmd=${selected#* }
    echo "Seleccionado: PID $pid -> $cmd"
    read -r -p "Confirmar finalizar PID $pid? (s/N): " c2
    c2=${c2:-N}
    if [[ "$c2" =~ ^[Ss]$ ]]; then
      attempt_kill_pid "$pid"
    else
      echo "Omitido PID $pid."
    fi
  done
  pause
}

# funcion que permite pintar el menu de opciones 
print_menu() {
  clear_screen
  print_header
  cat <<'MENU'
Seleccione una opción:
  1) Listar todos los procesos (ps aux)
  2) Buscar proceso por nombre
  3) Finalizar proceso por nombre (interactivo)
  4) Refrescar pantalla
  5) Salir
MENU
}

# funcion principal que pinta el menu y de acuerdo a la opcion seleccionada ejecuta la funcion correspondiente
main() {
  while true; do
    print_menu
    read -r -p "Opción [1-5]: " opt
    case "$opt" in
      1) list_processes ;;
      2) search_processes ;;
      3) kill_by_name_interactive ;;
      4) continue ;;
      5) echo "Saliendo..."; exit 0 ;;
      *) echo "Opción inválida."; pause ;;
    esac
  done
}


main