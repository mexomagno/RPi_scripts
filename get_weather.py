#!/usr/bin/python
# -*- coding: utf-8 -*-

########################################################
# 
# Este programa es una alternativa al típico "weather" para linux, que por
# alguna razón no me funcionó para nada de bien en mi raspberry.
# El script se conecta con accuweather.com y saca directamente la información del pronóstico
# para los próximos 5 días. Los argumentos entregados a este script determinan
# qué de toda es información se retornarán.
#
# Programado por Maximiliano Castro en una noche de ocio extremo.
##########################################################

from bs4 import BeautifulSoup as BS
import sys, subprocess, os

DEBUG=False

############## PRIMERA SECCIÓN: PARSEO DE ARGUMENTOS ################
#Mensaje de ayuda
helpstr = """

## GET WEATHER ##
Este script obtiene la página de accuweather para santiago y la
parsea para obtener el clima.
Puede responder a las siguientes preguntas:
	-Temperatura mínima, máxima
	-Características del día
Todo esto para hoy a 4 días en el futuro.
Parámetros: 
	-d={0,1,2,3,4}: Especifica el día para el cual se pide el tiempo. 
			Default: 0 (hoy, ahora).
			Ejemplo: get_weather -d=1

	-m, --min	: Especifica que se quiere obtener temperatura mínima.

	-n, --now 	: Temperatura actual.

	-M, --max	: Igual a m pero máxima. Para d=0 es temperatura actual. 

	-nt, --no-temp	: NO entregar temperatura. Util si se quiere sólo saber cómo estará el día.
			Default: desactivado. Temperatura sí se entrega. 

	-nc, --no-como	: NO entregar características del día. 
			Default: desactivado. Características sí se entregan

	-h, --help 	: Muestra esta ayuda

Ciertas reglas:
	-Si no setea --min ni --max, por defecto se muestra --now para d=0 y --max en otro caso.
	-Setear --now admite dos opciones: --no-temp y --no-como. Entonces: No se muestra min, max. Se muestra temperatura para hoy.
	-Si entrega --no-temp y --no-como juntos, se entrega sólo la temperatura (se ignora --no-temp)
	-Si ingresa más de una definición para d, se toma la última
	-Si ingresa --help, se mostrará la ayuda ignorando el resto de los parámetros.
"""

def showHelp(mensaje):
	if mensaje != "":
		print "Error: {}".format(mensaje)
	print helpstr
	exit(1)

def isArg(arg):
	s = "-d=0 -d=1 -d=2 -d=3 -d=4 -m --min -M --max -n --now -nt --no-temp -nc --no-como -h --help"
	valid_args = s.split(" ")
	return (arg in valid_args)

def saveArg(arg):
	global args
	# setear argumento ingresado
	if arg=="-d=0": args['dia']=0
	elif arg=="-d=1": args['dia']=1
	elif arg=="-d=2": args['dia']=2
	elif arg=="-d=3": args['dia']=3
	elif arg=="-d=4": args['dia']=4
	elif arg=="-m" or arg=="--min": args['min']=True
	elif arg=="-M" or arg=="--max": args['max']=True
	elif arg=="-n" or arg=="--now": args['now']=True
	elif arg=="-nt" or arg=="--no-temp": args['temp']=False
	elif arg=="-nc" or arg=="--no-como": args['como']=False
	elif arg=="-h" or arg=="--help": showHelp("")

def checkArgs():
	global args
	# REGLAS:
	#	-Si no hay -m ni -M, setear -n para d=0 y -M para d!=0.
	#	-Si se setea -n setear todo acorde, menos -nt y -nc. Eso dejarlo al usuario.
	#	-Si se setea -nc Y -nt, mostrar temperatura
	#	-Si se setea más de un -d, ya se le asignó el último en saveArg
	#
	if not args['min'] and not args['max']: 
		if args['dia'] == 0:
			args['now']=True
			if DEBUG: print "Mostrando temperatura actual"
		else: 
			args['max']=True
			if DEBUG: print "Mostrando temperatura máxima"
	if not args['temp'] and not args['como']:
		args['temp']=True
		if DEBUG: print "Mostrando sólo temperatura"
	if args['now']:
		args['min']= False
		args['max']= False
		args['dia']= 0
		if DEBUG: print "Se seteó --now. Sobreescribiendo todo menos --no-temp y --no-como."
	# if args['now'] and (args['dia'] != 0): 
	# 	args['dia'] = 0
	# 	if DEBUG: print "Se seteó --now pero d!=0. Mostrando --now con d=0."
	# if args['now'] and (args ['min'] or args['max']):
	# 	args['min'] = False
	# 	args['max'] = False
	# 	if DEBUG: print "Se seteó --now con --min o --max. Mostrando --now solamente."
	# if args['now'] and not args['temp']:
	# 	args['temp'] = True
	# 	if DEBUG: print "Se seteó --now con --no-temp. Mostrando --now"

def parseArgs():
	"""
	Lee todos los argumentos recibidos, valida que existan, y corrige inconsistencias entre ellos.
	"""
	# obtener argumentos ingresados
	argv=sys.argv
	argv.pop(0)
	# para cada uno, chequear si es un argumento existente y guardar lo que setea.
	for arg in argv:
		if not isArg(arg):
			showHelp("Argumento no válido: {}".format(arg))
		saveArg(arg)
	# Reparar inconsistencias de los argumentos
	checkArgs()

############## SEGUNDA SECCIÓN: OBTENCIÓN DEL CLIMA ################

def inCelsius(soup,gradosdiv_id):
	"""
	Recibe 		: 
					Objeto beautifulsoup con toda la página
	Retorna 	:
					True si la página muestra grados celsius
					False si está en Fahrenheit
	"""
	gradosdiv = str(soup.find(id=gradosdiv_id))
	i = gradosdiv.index('°')
	unidad = gradosdiv[i+2:i+3] #saltarse unos chars, porque ° es rarito.
	return (True if (unidad == "C") else False)

def parseForecast(soup,tiempodiv_id,div_hoy_id,div_hoy_mM_id):
	"""
	Recibe 		: 
					-Objeto beautifulsoup con la página.
	Retorna 	:
					Arreglo tamaño 5 con forecast para cada día.
					Cada elemento contiene: temperaturas mínima, máxima y string que describe el día.
					Para el dia 0, sólo tiene temperatura mínima.
	"""
	global celsius
	div = soup.find(id=tiempodiv_id)
	div_hoy = soup.find(id=div_hoy_id)
	div_hoy_mM = soup.find(id=div_hoy_mM_id)
	strings = div.findAll("span",{"class" : "cond"})
	maxs = div.findAll("strong",{"class" : "temp"})
	mins = div.findAll("span", {"class" : "low"})
	hoy_now = div_hoy.find("span",{"class" : "temp"}).text.encode("utf-8")
	hoy_now = hoy_now[0:hoy_now.find('°')]
	hoy_max = (div_hoy_mM.find("tr", {"class" : "hi"}).td.text.encode("utf-8"))
	hoy_max = hoy_max[0:hoy_max.find('°')]
	hoy_min = (div_hoy_mM.find("tr", {"class" : "last lo"})).td.text.encode("utf-8")
	hoy_min = hoy_min[0:hoy_min.find('°')]
	hoy_cond = div_hoy.find("span",{"class" : "cond"})
	arreglo = []
	for i in range(5):
		if i==0:
			temp_min = hoy_min
			temp_max = hoy_max
		else:
			# Obtener temperatura mínima
			temp_min = mins[i].text.encode("utf-8") # "Mín. X°"
			deg_index = temp_min.find('°')
			temp_min = temp_min[5:deg_index].strip() # "X"
			# Obtener temperatura máxima
			temp_max = maxs[i].text.encode("utf-8") # "X°"
			deg_index = temp_max.find('°')
			temp_max = temp_max[0:deg_index].strip() # "X"
		if not celsius:
			#Convertir fahrenheit a celsius
			if i != 0: temp_min = ""+(int((int(temp_min) - 32)*5.0/9.0))
			temp_max = ""+(int((int(temp_min) - 32)*5.0/9.0))
		# Obtener string con descripción del día
		string = strings[i].text.encode("utf-8")
		if i==0:
			string = hoy_cond.text.encode("utf-8")
		arreglo.append([temp_min, temp_max, string.lower()])
	# Agregar temperatura de hoy al final del primer elemento (correspondiente al dia d=0)
	arreglo[0].append(hoy_now)
	return arreglo

def getForecast(forecast):
	"""
	Recibe 		:
					Arreglo con forecast generado por parseForecast
	Retorna 	:
					String con el forecast, según los parámetros ingresados
	"""
	global args
	FRASE = 2
	#Frases a usar:
	frase_temp_hoy 		= " Temperatura {} para hoy: {} grados."
	frase_temp_both_hoy = " Temperaturas mínima y máxima para hoy: {} y {} grados."
	frase_temp_current	= " Temperatura actual: {} grados."
	frase_temp_1		= " Temperatura {} mañana: {} grados."
	frase_temp_both_1	= " Temperaturas mínima y máxima mañana: {} y {} grados."
	frase_temp_x		= " Temperatura {} en {} días: {} grados."
	frase_temp_both_x	= " Temperaturas mínima y máxima en {} días: {} y {} grados."
	frase_dia_hoy_a		= " Está {}."
	frase_dia_hoy_b		= " Hay {}."
	frase_dia_1_a		= " Mañana estará {}."
	frase_dia_1_b		= " Mañana habrá {}."
	frase_dia_x_a		= " En {} días estará {}."
	frase_dia_x_b		= " En {} días habrá {}."
	s=""
	# ver qué día se pide
	a_dia=args['dia']
	a_min=args['min']
	a_max=args['max']
	a_now=args['now']
	a_temp=args['temp']
	a_como=args['como']
	if a_dia == 0: 
		if a_now:
			if a_temp:
				s+= frase_temp_current.format(forecast[a_dia][3])
		else:
			if a_temp:
				if a_min and a_max:
					s+= frase_temp_both_hoy.format(forecast[a_dia][0],forecast[a_dia][1])
				elif a_min:
					s+= frase_temp_hoy.format("mínima",forecast[a_dia][0])
				else: s+= frase_temp_hoy.format("máxima",forecast[a_dia][1])
		if a_como:
			# ver si la palabra se dice con verbo "estar" o "haber"
			frase = forecast[a_dia][FRASE]
			if frase[0:frase.find(' ')] == "mucha" or frase[0:frase.find(' ')] == "mucho":
				s+= frase_dia_hoy_b.format(forecast[a_dia][FRASE])
			else: s+= frase_dia_hoy_a.format(forecast[a_dia][FRASE])
	elif a_dia == 1:
		if a_temp:
			if a_min and a_max:
				s+= frase_temp_both_1.format(forecast[a_dia][0],forecast[a_dia][1])
			elif a_min:
				s+= frase_temp_1.format("mínima",forecast[a_dia][0])
			else: s+= frase_temp_1.format("máxima",forecast[a_dia][1])
		if a_como:
			# ver si la palabra se dice con verbo "estar" o "haber"
			frase = forecast[a_dia][FRASE]
			if frase[0:frase.find(' ')] == "mucha" or frase[0:frase.find(' ')] == "mucho":
				s+= frase_dia_1_b.format(forecast[a_dia][FRASE])
			else: s+= frase_dia_1_a.format(forecast[a_dia][FRASE])
	else:
		if a_temp:
			if a_min and a_max:
				s+= frase_temp_both_x.format(a_dia,forecast[a_dia][0],forecast[a_dia][1])
			elif a_min:
				s+= frase_temp_x.format("mínima",a_dia,forecast[a_dia][0])
			else: s+= frase_temp_x.format("máxima",a_dia,forecast[a_dia][1])
		if a_como:
			# ver si la palabra se dice con verbo "estar" o "haber"
			frase = forecast[a_dia][FRASE]
			if frase[0:frase.find(' ')] == "mucha" or frase[0:frase.find(' ')] == "mucho":
				s+= frase_dia_x_b.format(a_dia,forecast[a_dia][FRASE])
			else: s+= frase_dia_x_a.format(a_dia,forecast[a_dia][FRASE])
	return s.strip()


############## INICIO DEL PROGRAMA #################################
def main():
	global args, celsius
	# Valores default de los parámetros
	args={'dia' : 0,'min': False, 'max' : False, 'now' : False, 'temp' : True, 'como' : True}

	# Validar argumentos recibidos y configurar variables
	parseArgs()

	## Variables de parseo html
	# Archivo donde se guardará temporalmente la página de accuweather
	html_doc = "/tmp/clima.html"
	#ID's de div's importantes
	tiempodiv_id = "feed-tabs"
	gradosdiv_id = "bt-menu-settings"
	div_hoy_id = "detail-now"
	div_hoy_mM_id = "feature-history"

	##Lógica
	# Obtener página web de accuweather para santiago
	if DEBUG: print "Obteniendo datos desde Accuweather..."
	with open(os.devnull, "wb") as devnull:
		subprocess.check_call(["wget","http://www.accuweather.com/<AJUSTAR PARA ZONA DESEADA>", "-O",html_doc], stdout=devnull, stderr=subprocess.STDOUT)
	# Obtener sección de interés
	soup = BS(open(html_doc))
	# Ver unidad de medición
	celsius = inCelsius(soup,gradosdiv_id)
	# Guardar temperaturas y características para los 5 días
	forecast = parseForecast(soup,tiempodiv_id,div_hoy_id,div_hoy_mM_id)
	soup.decompose()
	# escribir resultado del forecast según argumentos entregados
	print getForecast(forecast)
	with open(os.devnull, "wb") as devnull:
		subprocess.check_call(["rm",html_doc], stdout=devnull, stderr=subprocess.STDOUT)

main()