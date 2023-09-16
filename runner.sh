#!/usr/bin/env bash

INI_FILE="config.ini"
SECTION_NAME="$1"
LOG_LEVEL='INFO'

logger(){
    if [[ $1 == 'DEBUG' ]]; then
        if [[ $LOG_LEVEL == 'DEBUG' ]]; then
            echo -e "[`date "+%Y.%m.%d-%H:%M:%S %Z"`] - ${1} - ${2}"
        fi
    else
        echo -e "[`date "+%Y.%m.%d-%H:%M:%S %Z"`] - ${1} - ${2}"
    fi
}

pause_control() {
    #read -n 1 -s -r -p "[${name}] Press any key to continue......" < /dev/tty
    read -n 1 -s -r -p "Press any key to continue......" < /dev/tty
    echo -e ""
}

pause_time() {
    time="$1"
    if [[ -z $time ]]; then
        time="3"
    fi
    #echo -e "[${name}] Sleeping $time seconds..."
    echo -n "Sleeping $time seconds..."
    sleep $time
}

run_step_with_pause() {
    step="$1"; name="$2"
    #logger DEBUG "CMD: ${step}"
    echo -e "\n[${name}]\n"
    eval "$step" < /dev/tty;
    echo ""
}

execute_pipeline() {
    logger DEBUG 'invoke execute_pipeline'
    in_section=false
    while IFS=' = ' read -r key value; do
        if [[ $key == \[*] ]]; then
            if [[ $key == "[$SECTION_NAME]" ]]; then
            in_section=true
            else
            in_section=false
            fi
        fi

        if [[ $in_section == true && $key != \[* && $key != "" ]]; then
            run_step_with_pause "$value" $key
        fi
    done < "$INI_FILE"
}

# main

if [[ -z $SECTION_NAME ]]; then
    logger ERROR 'not found param section'
    logger INFO 'sections:'
    awk -F '[][]' '/^\[.*\]/{print " - " $2}' "$INI_FILE"
    exit 0
fi

if [ ! -f "$INI_FILE" ]; then
  echo "El archivo $INI_FILE no existe."
  exit 1
fi

execute_pipeline