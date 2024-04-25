#!/bin/bash

black_color="\e[0;30m"
red_color="\e[0;31m"
green_color="\e[0;32m"
yellow_color="\e[0;33m"
blue_color="\e[0;34m"
purple_color="\e[0;35m"
cyan_color="\e[0;36m"
grey_color="\e[0;37m"
white_color="\e[0;38m"
reset_color="\e[0;39m"

reset_all_env_variables () {
    for env_variables in analisys; do
        unset $env_variables
    done
}

ask_build_system () {
    while true; do
        echo -e "\n[+] Selecciona el system build que usa la aplicación."
        counter=1
        for build_system in "${build_systems[@]}"; do
            echo "$counter) $build_system"
            counter=$((counter+1))
        done
        echo -ne "\n[?] Selecciona una opción: " && read reply_build_system
        if [ "$reply_build_system" -gt "$counter" ]; then
            echo -e "\n$red_color[!]$reset_color Opcion no encontrada." 
        else
            break
        fi
    done
}

compiling_simulator () {
    while true; do
        case $reply_build_system in
            1)
            cd "${path}"; CC=afl-gcc-fast CXX=afl-g++-fast ./configure --disable-shared
            ;;

            2)
                cd "${path}"; 
                sudo rm -r build -f; 
                mkdir build; 
                cd build;
                echo -e "[+] Compilando la aplicación. Esto puede tardar varios minutos...";
                cmake -DCMAKE_C_COMPILER=afl-gcc-fast -DCMAKE_CXX_COMPILER=afl-g++-fast .. > /dev/null 2>&1; 
                echo -e "$green_color[✓]$grey_color Aplicación compilada!!";
                echo -e "[+] Instalando la aplicación. Esto puede tardar varios minutos...";
                sudo make install > /dev/null 2>&1;
                echo -e "$green_color[✓]$grey_color Aplicación instalada!!";
                echo -e "[+] Verifica su instalación en el directorio bin de su usuario.";
            ;;

            3)
            cd "${path}"; CC=afl-gcc-fast CXX=afl-g++-fast meson
            ;;
        esac
    
        # Condition to exit the loop
        if [ $? -eq 0 ]; then
            break
        fi
    done
}

execute_fuzzer() { 
    cd $original_path;
    rm -r output/ -f
    echo -e "[+] Ejecutando análisis..."
    current_date=$(date +"%d%m%Y-%H%M%S")
    afl-fuzz -V $execution_time -i inputs/ -o "results/result-"$current_date"" -- $1 -t /dev/stdin > /dev/null 2>&1
    chmod -R $(stat -c %a inputs) results/

    echo -e "$green_color[✓]$grey_color Todo ha funcionado correctamente. Tiene los resultados en el directorio output."
    python3 script/data_modifier.py $original_path AFLPlusPlus $execution_time $current_date
    
    echo -ne "\n$yellow_color[?]$grey_color Quiere realizar otra prueba fuzzing? (s/N): "
    read loop
    if  [ "$loop" == "S" ] || [ "$loop" == "s" ]; then 
        clear
        main
    fi
}

execute_web_app(){
    npm start -s &
    printf "\n$blue_color[+]$grey_color Tiene los datos listos para su visualización en $cyan_color\e]8;;http://localhost:3000\ahttp://localhost:3000\e]8;;\a$grey_color.\n"
}

main() {
    # Existing build systems
    build_systems=("Configure build system" "CMake build system" "Meson build system")
    # Existing compilers (probably not used)
    compilers=("AFLPlusPlus + afl-clang-lto/afl-clang-lto++" "AFLPlusPlus + afl-clang-fast/afl-clang-fast++" "AFLPlusPlus + afl-gcc-fast/afl-g++-fast" "AFLPlusPlus + afl-gcc/afl-g++" "AFLPlusPlus + afl-clang/afl-clang++")
    analisys=("" "AFL_USE_ASAN" "AFL_USE_MSAN" "AFL_USE_UBSAN" "AFL_USE_CFISAN" "AFL_USE_TSAN")
    execution_time=100

    original_path=$(pwd);

    echo -ne "\n$yellow_color[?]$grey_color Introduce el directorio raíz donde se encuentra la aplicación: "
    read path

    ask_build_system
    compiling_simulator

    echo -ne "\n$yellow_color[?]$grey_color Introduce el directorio del archivo binario del simulador: "
    read path_sim
    execute_fuzzer "${path_sim}"
}

cleanup() {
    pkill -P $$
    clear
    exit 0
}


if  [ $(id -u) -ne 0 ]; then 
    echo -e "\n$red_color[!]$reset_color Debes ser usuario root para ejecutar el análisis."
    echo -e "[+] Prueba ejecutando$purple_color sudo bash $0"
    exit -1
fi

trap 'cleanup' SIGINT SIGTERM
clear
cat tool_logo.txt

echo -ne "\n[?] Quieres desplegar la visualización de datos mediante una aplicación web? (s/N): "
read app_web

if [ "$app_web" == "s" ] || [ "$app_web" == "S" ]; then 
    execute_web_app
fi

main