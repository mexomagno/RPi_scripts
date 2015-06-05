#!/bin/bash
####################################################
# Este script me permite montar discos duros con parámetros
# personalizados de permisos y usuarios y grupos. Esto permite 
# manejar Samba y torrents y otras cosas sin peligros ante
# usuarios inescrupulosos.
########################################################

# obtener paths globales
source "<directorio a .paths_globales>"
# Para escribir logs en ~/logs/
source "$LOGGER_SH"
logInit

disco=$1
_gid="100" # grupo "users"
_uid="1001" # mi usuario
_umask="027" # permisos rwxr-x--- la x es para poder hacer cd

if [ "$disco" == "disco1" ]
then
	dir_from="/dev/disk/by-label/Disco1-label"
	dir_to="$FS_DISCO1"
elif [ "$disco" == "disco2" ]
then
	dir_from="/dev/disk/by-label/Disco2-label"
	dir_to="$FS_DISCO2"
elif [ "$disco" == "Torrents" ]
then
	dir_from="/dev/disk/by-label/Disco-torrents-label"
	dir_to="$FS_TORRENTS"
	_gid="1001"
	_umask="077" # rwx------ miusuario miusuario
else
	echo -e "${amarillo}No conozco ese disco. Móntalo manualmente${no_color}."
	logWrite "Disco '$disco' desconocido."
	logEnd
	exit
fi
echo -e "${amarillo}Montando disco $disco en $dir_to...${no_color}"
# Aquí ocurre efectivamente el montado del disco
logWrite "Montando el disco $disco..."
_output="$(sudo ntfs-3g $dir_from $dir_to -o umask=$_umask,gid=$_gid,uid=$_uid)"
if [ "$_output" == "" ]
then
	logWrite "No hubo errores graves"
	echo -e "${verde}Listo! $1 montado en $dir_to.${no_color}"
else
	logWrite "Hubo error: $_output"
	echo -e "${rojo}ERROR:${amarillo} Algo anduvo mal. Lea la siguiente información${no_color}:"
	echo $_output
fi
logEnd
