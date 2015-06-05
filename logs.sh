#!/bin/bash

# Importar colores
source "$COLORS_SH"
# Nombre del archivo de logs del script que logeará
nombre=$(basename $0)
logfile="$LOGS_MAX/${nombre%.*}.log"
# logInit Marca inicio de ejecución del programa
function logInit(){
	logWrite "${verde_claro}Comienza ejecución el ${amarillo}$(date +%A\ %e\ de\ %B\ de\ %Y)${no_color}"
}
# logWrite <string> escribe una entrada en el log
function logWrite(){
	now=$(date +%T)
	echo -e "[ $now ]: $1" >> $logfile
}
# logEnd marca fin ejecución del programa
function logEnd(){
	# Verificar si recibe código de error
	rc=0
	rcmsg=""
	if (($#>=1)); then
		rc=$1
	fi
	if ((rc!=0)); then
		rcmsg=" con código ${blanco}$rc${no_color}"
	fi
	logWrite "${rojo_claro}Finaliza ejecución el ${amarillo}$(date +%A\ %e\ de\ %B\ de\ %Y)${no_color}$msg"
}
