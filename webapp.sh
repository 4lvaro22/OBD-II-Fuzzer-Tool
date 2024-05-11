#!/bin/bash

reset_all_env_variables(){
    for env_variables in "${analysis_comm}"; do
        unset $env_variables
    done
}

web_scrapping(){
    if  [ "$1" == "obd" ] ; then 
        python3 script/web/obd_web_scrapper.py
    elif [ "$1" == "can" ] ; then 
        echo "can"
    else
        echo "NO"
    fi
}

compiling_simulator() {
    actual_dir="$(pwd)"

    if [[ -d "$1" ]] ; then
        cd "$1";
        eval "$(echo "$2")"
    elif [[ -f "$1" ]] ; then
        cd "$(dirname "$1")"
        eval "$(echo "$2")"
    else
        exit -1
    fi

    cd "$actual_dir"
}

executing_fuzzing(){
    eval "$(echo "$1")" 
    chmod -R 777 outputs/
}

web_scrapper="$1"
path_sim="$2"
conf_comp="$3"
conf_fuzz="$4"
dirs_errs="$5"
description="$6"
name="$7"

analysis_comm=("" "AFL_USE_ASAN" "AFL_USE_MSAN" "AFL_USE_UBSAN" "AFL_USE_CFISAN" "AFL_USE_TSAN")
reset_all_env_variables

web_scrapping "$web_scrapper"

compiling_simulator "$path_sim" "$conf_comp"

executing_fuzzing "$conf_fuzz"

python3 script/data_modifier.py "$web_scrapper" "$path_sim" "$conf_comp" "$conf_fuzz" "$dirs_errs" "$description" "$name"



