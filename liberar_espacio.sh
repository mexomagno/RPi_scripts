#!/bin/bash
#################################################
# Este script es ejecutado por crontab una vez a la semana
#################################################


# Obtener paths globales
source "<path de .paths_globales>"
## Para escribir en ~/logs/
source "$LOGGER_SH"
logInit
function salir(){
	logWrite "Código de ejecución: $1"
	logEnd
	exit $1
}
# comprobar si es sudo
usuario=$(whoami)
if [ "$usuario" != "root" ]
then
	logWrite "No ejecutado como 'sudo'"
	echo -e "${rojo_claro}ERROR:${amarillo} Debes ejecutar como ${cafe}sudo${no_color}"
	salir 1
fi
# Guarda espacio libre antes de ejecución
FREESPACE_BEFORE="$(df / | tail -1 | awk '{print $4}')"

# Elimina cosas de apt-get
echo -e "${amarillo}Borrando archivos de apt-get..."
logWrite "Ejecutando funciones de apt-get"
logWrite "apt-get autoremove"
apt-get autoremove 2>&1 /dev/null
logWrite "apt-get clean"
apt-get clean 2>&1 /dev/null
# Borrar logs antiguos
echo -e "${amarillo}Borrando logs antiguos..."
logWrite "Borrando logs comprimidos, terminados con numero, terminados con .old..."
find /var/log -regex "\(.*\.gz\'\|.*\.[0-9]+\'\\|.*\.old\'\)" | xargs rm
#logWrite "Borrando logs comprimidos"
#rm /var/log/*.gz -r 2>&1 /dev/null
#logWrite "Borrando logs del estilo <nombre>.<número>"
#rm /var/log/*.{0..9} -r 2>&1 /dev/null
FREESPACE_AFTER="$(df / | tail -1 | awk '{print $4}')"
FREED_SPACE="$(($FREESPACE_AFTER - $FREESPACE_BEFORE))"
human() {
	sufixes="BKMGTPE"
	temp_size=$1
	exp=0
	factor=1
	while [ "$temp_size" -ge "1024" ]; do
		exp=$((exp+1))
		factor=$((factor*1024))
		temp_size="$(($1/$factor))"
	done
	echo "$temp_size""${sufixes:$exp:1}"
}
HUMAN_FREED_SPACE="$(human $FREED_SPACE)"
echo -e "${azul_claro}Se liberaron $HUMAN_FREED_SPACE"
echo -e "${verde_claro}Listo!${no_color}"
salir 0
