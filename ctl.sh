#!/usr/bin/env bash

CONTAINER_NAME='client'
FORMAT_OUTPUT='table'
SHELL=/bin/bash

logger(){
    echo -e "[`date "+%Y.%m.%d-%H:%M:%S %Z"`] - ${1} - ${2}"
}

yes_or_no() {
  while true; do
    read -p "[data] input 'yes' o 'no': " input
    case "$input" in
      [Yy]|[Yy][Ee][Ss]) return 0 ;;
      [Nn]|[Nn][Oo]) return 1 ;;
      *) echo "[data] please, input 'yes' o 'no'" ;;
    esac
  done
}

if [[ ! $(which docker) ]]; then
    logger ERROR "docker is not installed"
    exit 1
fi

if [[ $(docker ps -a --format '{{.Names}}' | grep -E "${CONTAINER_NAME}") ]]; then
    eval "docker exec -it ${CONTAINER_NAME} etcdctl $@" < /dev/tty
else
    logger WARN 'not found container client'
    logger INFO 'probe `docker-compose up -d`'
    logger "launch docker-compose ? (yes/no)"
    if yes_or_no; then
        docker-compose up -d
        logger INFO 'relaunch the command'
    fi
fi