
#!/usr/bin/env bash
# Script para encriptar y desencriptar archivos usando GPG
# Autor: Miguel Angel Garcia
# Fecha: 2024-06-15
# Materia: Programacion bash

show_menu() {
  echo "Seleccione una opción:"
  echo "1) Encriptar archivo"
  echo "2) Desencriptar archivo"
  echo "3) Salir"
}

# recupera el nombre del archivo y la contraseña para encriptar o desencriptar
# la funcion usa gpg para realizar el cifrado y descifrado simetrico usando el algoritmo AES256
encrypt_file() {
  read -p "Nombre del archivo a encriptar: " file
  if [ ! -f "$file" ]; then
    echo "El archivo '$file' no existe."
    return 1
  fi
  read -s -p "Ingrese la contraseña para encriptar: " pass
  echo
  printf "%s\n" "$pass" | gpg --batch --yes --passphrase-fd 0 --symmetric --cipher-algo AES256 -o "${file}.gpg" "$file"
  ret=$?
  unset pass
  # Verifica si la encriptación fue exitosa y notifica al usuario
  # mostrando el nombre del archivo encriptado
  if [ $ret -eq 0 ]; then
    echo "Encriptación completada: ${file}.gpg"
  else
    echo "Error en la encriptación."
  fi
}

decrypt_file() {
  read -p "Nombre del archivo a desencriptar (ej: archivo.txt.gpg): " file
  if [ ! -f "$file" ]; then
    echo "El archivo '$file' no existe."
    return 1
  fi
  read -s -p "Ingrese la contraseña para desencriptar: " pass
  echo
  out="${file%.gpg}"
  if [ "$out" = "$file" ]; then
    out="${file}.decrypted"
  fi
  printf "%s\n" "$pass" | gpg --batch --yes --passphrase-fd 0 --decrypt -o "$out" "$file"
  ret=$?
  unset pass
  if [ $ret -eq 0 ]; then
    echo "Desencriptación completada: $out"
  else
    echo "Error en la desencriptación."
  fi
}

while true; do
  show_menu
  read -p "Opción: " opt
  case "$opt" in
    1) encrypt_file ;;
    2) decrypt_file ;;
    3) exit 0 ;;
    *) echo "Opción inválida" ;;
  esac
  echo
done