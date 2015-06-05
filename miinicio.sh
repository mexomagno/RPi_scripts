#!/bin/bash

###############################################################
## Este script se ejecuta cada vez que la Raspberry inicia.  ##
## A continuación se ejecutan distintos programas y servicios
## personalizados.
## NO OLVIDAR NUNCA TERMINAR LAS LÍNEAS CON '&' (ampersand)
## sinó la raspberry nunca terminará el booteo a menos que los
## programas y servicios terminen y retornen algo!
###############################################################

## Lo que viene es para eliminar unos mensajes de "missing LSB and overrides" o algo asi
### BEGIN INIT INFO
# Provides: miinicio.sh
# Required-Start:
# Required-Stop:
# Should-Start:
# Should-Stop:
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Mis servicios
# Description: Mis servicios
### END INIT INFO

# Para escribir logs en ~/logs/
source "<path a logs.sh>"
logInit
echo iniciando ejecutables pulentos míos...
#inicializar pines en 0 al partir el raspi
#for i in 'seq 0 16'; do /usr/local/bin/rpio --setoutput $i; done
#for i in 'seq 0 16'; do /usr/local/bin/rpio -s $i:0; done

#Inicializar hd-idle: programa que pone a descansar discos duros después de un tiempo inactivos.
logWrite "Ejecutando hd-idle..."
/usr/local/sbin/hd-idle -i 600 &
logWrite "Ejecutando servicio de Domótica..."
<path a mis scripts>/domotica.py &
logEnd
