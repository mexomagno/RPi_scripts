#!/bin/bash
################################################################
# Este script permite a la raspberry hablar! 
# La idea principal está sacada de internet. ojo.
# Requiere tener instalado "mplayer"
################################################################

# obtener paths globales
source "<directorio de .paths_globales>"
# Para hacer logs
source "$LOGGER_SH"
logInit
# Listado de idiomas soportados
INPUT1=$1 # texto a hablar
INPUT2=$2 # idioma. Debe empezar con i= y luego un idioma
INPUT3=$3 # pitch. Debe empezar con p= y luego un número del 0.5 al 1.0
IDIOMA="es"
INDICE_IDIOMA=0
PITCH=0.9
idiomas_validos=( "espanol" "ingles" "portugues" "japones" "frances" "italiano" "britanico" "australiano" "chino" "koreano" "espana" "ruso" "aleman" "hindi" )
codigos_idioma=( "es" "en" "pt-BR" "ja" "fr" "it" "en-gb" "en-au" "zh-CN" "ko" "es-la" "ru" "de" "hi" )

# Algunas funciones
function salir(){
	logWrite "Código de finalización: $1"
	logEnd
	exit $1
}
########## PRIMERA SECCIÓN: OBTENER ARGUMENTOS ####################

function showHelp(){
	echo -e "${rojo_claro}$1${no_color}"
	echo "Opciones permitidas:"
	echo "		i=<palabra>	: Idioma de pronunciación. Ejemplo: ./decir \"bonjour\" i=fr"
	echo "		p=<numero>	: Pitch de la voz (tono). Debe ir de 0.5 a 1.0"
	echo "Strings de idiomas soportados: "
	for i in ${!idiomas_validos[*]}
	do
	  printf '		%s (%s)\n' ${idiomas_validos[i]} ${codigos_idioma[i]}
	done
	salir 1
}
function setIdioma(){
	input=$(echo "$1" | cut -d'=' -f2)
	# Validar si se ingresa un idioma
	if [ "$input" != "" ]
	then
		nidiomas=${#idiomas_validos[@]}
		for (( i=0 ; i<${nidiomas} ; i++ ))
		do
			if [ "$input" == "${idiomas_validos[$i]}" ] || [ "$input" == "${codigos_idioma[$i]}" ]
			then
				IDIOMA=${codigos_idioma[$i]}
				INDICE_IDIOMA=$i
				break
			fi
			if [ $i == $(( ${nidiomas} - 1 )) ]
			then
				showHelp "ERROR: Idioma no válido"
			fi
		done
	else
		showHelp "ERROR: Idioma no válido"
	fi
	echo -e "${amarillo}Idioma: ${idiomas_validos[$INDICE_IDIOMA]}${no_color}"
}
function setPitch(){
	valor=$(echo "$1" | cut -d'=' -f2)
	if [ "$valor" == "" ] ; then
		showHelp "ERROR: Pitch no recibió ningún valor"
	fi
	if (( $( echo "($valor <= 1.0) && ($valor >= 0.5)" | bc -l) ))  ; then
		PITCH="$valor"
	else
		showHelp "ERROR: Valor inválido para pitch"
	fi
	echo -e "${amarillo}Pitch: $PITCH${no_color}"
}

function validarInputs(){
	# Ver que se ingresó un input, si no, mostrar help. Si se ingresó opciones, verificar que son válidas y luego implementarlas
	#	1: Se entregó algún input?
	if [ "$INPUT1" == "" ] ; then
		showHelp "ERROR: debes ingresar algún texto"
	fi
	# 	2: Qué dice el argumento 2?
	if [ "$INPUT2" != "" ] ; then
		opcion=$(echo "$INPUT2" | cut -d"=" -f1)
		if [ "$opcion" == "i" ] ; then
			setIdioma $INPUT2
			i_listo=true
		elif [ "$opcion" == "p" ] ; then
			setPitch $INPUT2
			p_listo=true
		else
			showHelp "ERROR: Argumento no válido"
		fi
		#	3: Qué dice el argumento 3?
		if [ "$INPUT3" != "" ] ; then
			opcion=$(echo "$INPUT3" | cut -d"=" -f1)
			if [ "$opcion" == "i" ] ; then
				if [ $i_listo ] ; then
					showHelp "ERROR: Doble declaración de idioma"
				else
					setIdioma $INPUT3
				fi
			elif [ "$opcion" == "p" ] ; then
				if [ $p_listo ] ; then
					showHelp "ERROR: Doble declaración de pitch"
				else
					setPitch $INPUT3
				fi
			else
				showHelp "ERROR: Argumento no válido"
			fi
		fi
	fi
}

logWrite "Se validan inputs"
validarInputs
################ SEGUNDA SECCIÓN: EJECUCIÓN DEL PROGRAMA ####################
logWrite "Inputs validados"
logWrite "Decir: '$INPUT1'"
logWrite "Idioma: $IDIOMA"
logWrite "Pitch: $PITCH"
STRINGNUM=0
ary=($INPUT1)
for key in "${!ary[@]}"
do
SHORTTMP[$STRINGNUM]="${SHORTTMP[$STRINGNUM]} ${ary[$key]}"
LENGTH=$(echo ${#SHORTTMP[$STRINGNUM]})

if [[ "$LENGTH" -lt "100" ]]; then
SHORT[$STRINGNUM]=${SHORTTMP[$STRINGNUM]}
else
logWrite "String largo mayor a 100"
STRINGNUM=$(($STRINGNUM+1))
SHORTTMP[$STRINGNUM]="${ary[$key]}"
SHORT[$STRINGNUM]="${ary[$key]}"
fi
done
for key in "${!SHORT[@]}"
do
say() { local IFS=+;mplayer -ao alsa -really-quiet -noconsolecontrols -af scaletempo=scale=1.0:speed=pitch -speed $PITCH  "http://translate.google.com/translate_tts?ie=UTF-8&tl=$IDIOMA&q=${SHORT[$key]}"; }
logWrite "Llamando a mplayer para reproducir mp3 de google..."
say $*
done

salir 0
