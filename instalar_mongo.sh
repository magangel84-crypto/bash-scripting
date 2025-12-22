#!/bin/bash

set -e # activa la bandera que indica salir del script en caso de que algun comando falle

echo "iniciando instalacion de mongodb"
while getopts ":u:p:n:h" OPCION
do
  case ${OPCION} in
        u ) USUARIO=$OPTARG
                echo "Parametro USUARIO establecido con '${USUARIO}'";;
        p ) PASSWORD=$OPTARG
                echo "Parametro PASSWORD establecido.";;
        n ) PUERTO_MONGOD=$OPTARG
                echo "Parametro PUERTO_MONGOD establecido con '${PUERTO_MONGOD}'";;
        h ) ayuda; exit 0;;
        : ) ayuda "Falta el parametro para -$OPTARG"; exit 1;;
        \?) ayuda "La opcion no existe: $OPTARG"; exit 1;;
  esac
done

if [ -z ${USUARIO} ]
then
        ayuda "El usuario(-u) debe ser especificado"; exit 1
fi 

if [ -z ${PASSWORD} ]
then 
        ayuda "El password (-p) debe ser especificado;" exit 1
fi

if [ -z ${PUERTO_MONGOD} ]
then
        PUERTO_MONGOD=27017
fi

echo "continuamos con la instalación, parametros minimos seteados correctamente..."


if [[ -z "$(mongosh --version 2> /dev/null)" ]]
then
        # instalar paquetes comunes, servidor, shell de mongo, balanceador de shards y herramientas 
         rm -f /etc/apt/sources.list.d/mongodb-org-*.list

        # Instalación de dependencias y llave GPG
        apt-get update && apt-get install -y gnupg curl \
        && curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor --yes \
        && echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc>      && sudo apt-get update \
        && sudo apt-get install -y \
                mongodb-org \
                mongodb-org-server \
                mongodb-org-shell \
                mongodb-org-mongos \
                mongodb-org-tools \
        && sudo rm -rf /var/lib/apt/lists/* \
        && sudo pkill -u mongodb || true \
        && sudo pkill -f mongod || true \
        && sudo rm -rf /var/lib/mongodb
fi
echo "mongodb se instalo con exito"