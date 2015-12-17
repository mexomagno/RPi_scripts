#!/bin/bash

#############################################################
# Este script toma los torrents descargados de transmission-daemon
# y los lleva a una carpeta designada por $DEST_DIR.
# Si el porcentaje de uso del disco es menor a $UMBRAL, no se hace nada.
# Si se ingresa la opción -f, se ignora el umbral y se mueven de todas formas.
# Si falla intentando mover un archivo, reintenta $RETRY veces.
#
# Se programó crontab para que ejecute este script todas las noches.
# Notar que sólo será ejecutado cuando el espacio del disco de torrents
# sea escaso.
#############################################################

# iniciar logs
source "<Path hacia archivo .paths_globales>"
source "$LOGGER_SH" # logger personalizado
function salir(){
	if (( $# == 0 )); then
		rc=0
	else
		rc=$1
	fi
	logEnd
	exit $rc
}
logInit
# Revisar que se inicia como root
if [ "$(whoami)" != "root" ]; then
	logWrite "No es root"
	echo "Debe iniciar como root. Abortando..."
	salir 1
fi
# Revisar que están los torrents
SRC_DIR="$TORRENTS"
if [ "$SRC_DIR" == "" ]; then
	#problemas con la variable global!
	echo "Problemas con las variables globales! Abortando..."
	salir 1
fi
ismounted=$(mount | grep $FS_TORRENTS)
if [ ismounted == "" ]; then
	logWrite "$TORRENTS no está montado"
	echo "El disco de Torrents no está montado. Abortando..."
	salir 1
fi
# Revisar el porcentaje de espacio ocupado del disco de torrents
if [ "$1" != "-f" ]; then 
	porcent=$(df $SRC_DIR | tail -1 | awk '{print $5}' | rev | cut -c 2- | rev )
	UMBRAL=80
	if (( porcent<UMBRAL )); then
		# no hacer nada
		logWrite "Suficiente espacio libre (ocupado: $porcent%). Abortando..."
		echo "Aún queda espacio libre. Abortando..."
		salir 0
	else
		logWrite "Queda poco espacio (ocupado: $porcent%). Comenzando..."
		echo "Queda poco espacio. Se comienza operación."
	fi
else
	logWrite "Opción -f: operación forzada."
	echo "Forzando movimiento de archivos (-f)"
fi
# Revisar que el disco de destino existe, está montado y tiene espacio
DEST_DIR="$FS_SOFTWARE/<carpeta donde guardar torrents listos>"
ismounted=$(mount | grep $FS_SOFTWARE)
if [ ismounted == "" ]; then
	logWrite "No se encuentra $DEST_DIR"
	echo "El disco de destino no está montado. Abortando..."
	salir 1
fi
cd $SRC_DIR
# Detener servicio de torrents
logWrite "Deteniendo transmission-daemon..."
echo "Deteniendo transmission-daemon..."
service transmission-daemon stop 2>&1 /dev/null
# iterar sobre cada archivo
RETRY=2
R=0
n_files=0
# Permitir copia de archivos ocultos
shopt -s dotglob nullglob
# Repara nombres de archivos para no tener problemas con espacios y otras cosas
#logWrite "Reparando nombres de archivos..."
#detox -r *
for f in *; do
#### copiar el archivo al destino
	logWrite "Moviendo $f..."
	echo "Moviendo $f..."
	rc=$(mv "$f" "$DEST_DIR")
	if (( RETRY >= 2 )); then
		while (( rc != 0 )); do
			R=$((R+1))
			logWrite "ERROR al mover. Reintentando... ($R de $RETRY)"
			echo "Ocurrió un error al mover '$f'. Reintento $R de $RETRY..."
			rc=$(mv "$f" "$DEST_DIR")
			# Superó máximo de reintentos?
			if (( R == RETRY )); then
				logWrite "ERROR. Se superó n° de reintentos. Abortando..."
				echo "Muchos reintentos. Abortando..."
				salir 1
			fi
		done
	fi
	if (( rc != 0 )); then
		logWrite "ERROR al mover. Abortando..."
		echo "Ocurrió un error al mover '$f'. Abortando..."
		salir 1
	else
		logWrite "Copia exitosa."
		echo "Copia exitosa."
		n_files=$((n_files+1))
	fi
	R=0
done
if ((n_files==0)); then
	logWrite "No habían descargas listas. Cerrando..."
	echo "No hay descargas listas. Reiniciando transmission y cerrando..."
	service transmission-daemon start 2>&1 /dev/null
	salir 0
fi
msg="$n_files descargas movidas"
rc=0
if [ "$(ls)" != "" ]; then
	msg+=" pero no son todas. Revise '$SRC_DIR'."
	rc=1
fi
logWrite $msg
echo $msg
space=$(df -h $FS_SOFTWARE | tail -1 | awk '{print $4}')
logWrite "Quedaron $space libres en $DEST_DIR"
echo "Le quedan $space libres en $DEST_DIR."
# Volver a iniciar servicio de torrents
logWrite "Reiniciando transmission-daemon..."
echo "Reiniciando transmission..."
service transmission-daemon start
# esperar a que el servicio esté efectivamente iniciado
running=$(ps -e | grep transmission)
while [ "$running" == "" ]; do
	sleep 1
done
# Eliminando torrents listos de transmission. La manera de identificarlos es viendo si tienen error de "No data found"
logWrite "Limpiando lista de descargas..."
echo "Limpiando lista de descargas..."
function rmTorrents(){
	# Usuario
	user="<transmission_user>"
	# pass
	pass="<transmission_pass>"
	lista_t=$(transmission-remote --auth="$user:$pass" -l | sed -e '1d;$d;s/^ *//' | cut --only-delimited --delimiter=' ' --fields=1 | cut --only-delimited --delimite='*' --fields=1)
	LISTOS=$(transmission-remote --auth="$user:$pass" -l)
	# borrar todos los completados
	for id in $lista_t; do
		listo=$(transmission-remote --auth="$user:$pass" -t $id -i | grep "Error: No data found")
		if [ "$listo" != "" ]; then
			echo "El torrent $id está listo. Borrando..."
			transmission-remote --auth="$user:$pass" -t $id -r 2>&1 /dev/null
		fi
	done
}
rmTorrents
echo "Adiós!"
salir $rc
