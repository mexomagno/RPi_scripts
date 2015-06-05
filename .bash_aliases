#	Uso general del sistema
alias rm='rm -I'
alias mv='mv -i'
alias apagar='sudo shutdown -h -P 0'
alias instalar='sudo apt-get install'
alias sudo='sudo '
alias instalados='apt-mark showmanual'
alias editar='sudo nano'
alias hd-idle='/usr/local/sbin/hd-idle'
alias cmatrix='cmatrix -b -s'

#	Audio y música
#alias play='$SCRIPTS_MAX/play.sh'
#alias volumen='$SCRIPTS_MAX/volumen.sh'
#alias player='sudo cmus '

#	Control de GPIO

#	Montar dispositivos
alias montar='$SCRIPTS_MAX/montar.sh'
alias remontar='$SCRIPTS_MAX/remontar.sh'
alias desmontar='$SCRIPTS_MAX/desmontar.sh'

# Servidor http python
alias http_server='python -m SimpleHTTPServer'

# iniciar teamviewer
# alias teamviewer='$HOME/teamviewerqs/tv_bin/script/teamviewer'

# Descomprimir. Usar como 'cat <archivo.tar.gz> | tar_gz'
alias tar_gz='gunzip -c - | tar xf -'

# Obtener temperatura CPU
alias temp='cat /sys/class/thermal/thermal_zone0/temp'

# Control básico de voz tts (Google)
alias decir='sudo $SCRIPTS_MAX/decir.sh'

# Información de clima
alias clima='$SCRIPTS_MAX/get_weather.py'
alias rpi-info='cat /proc/cpuinfo'
