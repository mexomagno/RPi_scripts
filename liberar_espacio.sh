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
# Elimina cosas de apt-get
echo -e "${amarillo}Borrando archivos de apt-get..."
logWrite "Ejecutando funciones de apt-get"
logWrite "apt-get autoremove"
apt-get autoremove 2>&1 /dev/null
logWrite "apt-get clean"
apt-get clean 2>&1 /dev/null
# Borrar logs antiguos
echo -e "${amarillo}Borrando logs antiguos..."
logWrite "Borrando logs comprimidos"
rm /var/log/*.gz -r 2>&1 /dev/null
logWrite "Borrando logs del estilo <nombre>.<número>"
rm /var/log/*.{0..9} -r 2>&1 /dev/null
echo -e "${verde_claro}Listo!${no_color}"
salir 0
