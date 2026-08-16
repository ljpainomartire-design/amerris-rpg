extends Node2D

# Referencias a la pantalla
@onready var log_texto: RichTextLabel = $RichTextLabel
@onready var label_jugador: Label = $LabelJugador
@onready var label_enemigo: Label = $LabelEnemigo
@onready var boton_atacar: Button = $HBoxContainer/BotonAtacar
@onready var boton_objeto: Button = $HBoxContainer/BotonObjeto
@onready var boton_siguiente: Button = $HBoxContainer/BotonSiguiente
@onready var inventario_pocion: ItemData = preload("res://pocion.tres")

# Variables de estado
var hp_jugador: int = 100
var ataque_jugador: int = 15
var puntos_exploracion: int = 0

var hp_enemigo: int = 0
var ataque_enemigo: int = 8

var en_combate: bool = false

func _ready():
	# Conectamos las funciones a los botones
	boton_atacar.pressed.connect(_on_atacar_pressed)
	boton_siguiente.pressed.connect(_on_siguiente_pressed)
	
	# Ocultamos la interfaz del juego al inicio
	$HBoxContainer.visible = false
	$LabelJugador.visible = false
	$LabelEnemigo.visible = false
	$PanelHistorial.visible = false
	
	# Mostramos únicamente el Check-In para ingresar datos
	$PanelCheckIn.visible = true
	
	actualizar_interfaz()
	agregar_log("👋 ¡Bienvenido! Completá tu Check-In diario para iniciar la jornada.")
	boton_atacar.disabled = true

func agregar_log(mensaje: String):
	log_texto.append_text(mensaje + "\n")
	
	# Si pasa de 10 líneas, limpia el log para que no se acumule tanto
	if log_texto.get_line_count() > 10:
		log_texto.clear()
		log_texto.append_text(mensaje + "\n")

func actualizar_interfaz():
	label_jugador.text = "HP: " + str(hp_jugador) + " | ATQ: " + str(ataque_jugador) + " | PTS: " + str(puntos_exploracion)
	if en_combate:
		label_enemigo.text = "Enemigo HP: " + str(hp_enemigo)
	else:
		label_enemigo.text = "Enemigo: Ninguno"

# EVENTOS / EXPLORACIÓN
func _on_siguiente_pressed():
	if en_combate:
		return
		
	# Verificar si quedan puntos de exploración
	if puntos_exploracion <= 0:
		agregar_log("⚠️ ¡No te quedan Puntos de Exploración por hoy! Salí a caminar o esperá a mañana.")
		return
		
	# Descontar 1 punto de exploración
	puntos_exploracion -= 1
	agregar_log("🗺️ Explorando... (Puntos restantes: " + str(puntos_exploracion) + ")")

	# Generamos un evento aleatorio
	var dado = randi_range(1, 2)
	if dado == 1:
		iniciar_combate()
	else:
		evento_curacion()

func evento_curacion():
	var curacion = 20
	hp_jugador += curacion
	actualizar_interfaz()
	agregar_log("Encontraste una fuente de agua clara. Te curas " + str(curacion) + " de HP.")

func iniciar_combate():
	en_combate = true
	hp_enemigo = 40
	actualizar_interfaz()
	agregar_log("⚠️ ¡Un Goblin salvaje te bloquea el paso!")
	boton_atacar.disabled = false
	boton_siguiente.disabled = true

# SISTEMA DE COMBATE POR TURNOS
func _on_atacar_pressed():
	if not en_combate:
		return
		
	# Turno del Jugador
	hp_enemigo -= ataque_jugador
	agregar_log("Atacas al Goblin por " + str(ataque_jugador) + " de daño.")
	
	if hp_enemigo <= 0:
		hp_enemigo = 0
		actualizar_interfaz()
		agregar_log("🎉 ¡Derrotaste al Goblin!")
		en_combate = false
		boton_atacar.disabled = true
		boton_siguiente.disabled = false
		return

	# Turno del Enemigo
	hp_jugador -= ataque_enemigo
	agregar_log("El Goblin te ataca e inflige " + str(ataque_enemigo) + " de daño.")
	
	if hp_jugador <= 0:
		hp_jugador = 0
		agregar_log("💀 Has muerto... Fin del juego.")
		boton_atacar.disabled = true
		boton_siguiente.disabled = true
		
	actualizar_interfaz()


func _on_boton_objeto_pressed():
	if inventario_pocion == null:
		agregar_log("❌ No tenés ningún objeto para usar.")
		return

	# Curar al personaje (máximo 100 de HP)
	hp_jugador = min(100, hp_jugador + inventario_pocion.curacion)
	agregar_log("🧪 Usaste " + inventario_pocion.nombre + " y recuperaste " + str(inventario_pocion.curacion) + " de HP!")
	
	# Consumir el objeto
	inventario_pocion = null
	actualizar_interfaz()

	# Si estás en combate, usar un objeto te consume el turno y el Goblin ataca
	if en_combate:
		hp_jugador -= ataque_enemigo
		agregar_log("El Goblin aprovecha tu descuido y te ataca infligiendo " + str(ataque_enemigo) + " de daño.")
		
		if hp_jugador <= 0:
			hp_jugador = 0
			agregar_log("💀 Has muerto... Fin del juego.")
			boton_atacar.disabled = true
			boton_siguiente.disabled = true
		
		actualizar_interfaz()


func _on_boton_comenzar_dia_pressed():
	var input_peso = $PanelCheckIn/InputPeso
	var check_nutricion = $PanelCheckIn/CheckNutricion
	var check_gimnasio = $PanelCheckIn/CheckGimnasio
	var check_estudio = $PanelCheckIn/CheckEstudio
	var check_nofap = $PanelCheckIn/CheckNoFap
	var input_pasos = $PanelCheckIn/InputPasos

	var peso_texto = input_peso.text
	var pasos_num = int(input_pasos.text) if input_pasos.text.is_valid_int() else 0
	
	agregar_log("=== ☀️ INICIO DE JORNADA ===")
	
	if peso_texto != "":
		agregar_log("⚖️ Peso registrado: " + peso_texto + " kg")
	
	# Recompensas de Stats Reales:
	if check_nutricion.button_pressed:
		hp_jugador = min(100, hp_jugador + 10) # Te cura/defiende 10 de vida
		agregar_log("🥗 Nutrición en Rango (+10 HP Curado)")
		
	if check_gimnasio.button_pressed:
		ataque_jugador += 2 # Te sube el daño base de ataque
		agregar_log("🏋️ Gimnasio completado (+2 de Daño de Ataque)")
		
	if check_estudio.button_pressed:
		agregar_log("📚 Estudio completado (+1 Inteligencia)")
		
	if check_nofap.button_pressed:
		agregar_log("🧠 Perseverancia mantenida (+1 Claridad)")

# Pasos -> Puntos de Exploración
	puntos_exploracion = 1 # 1 punto base diario
	var puntos_extra = pasos_num / 5000
	puntos_exploracion += puntos_extra
	
	if puntos_extra > 0:
		agregar_log("👟 Pasos de hoy: " + str(pasos_num) + " (¡+" + str(puntos_extra) + " Puntos Extra!)")
	else:
		agregar_log("👟 Pasos de hoy: " + str(pasos_num) + " (+1 Punto base por iniciar el día)")
		
	agregar_log("🗺️ Puntos de Exploración disponibles: " + str(puntos_exploracion))
	
	agregar_log("=============================\n")
	
# Guardar la jornada en el archivo local
	guardar_jornada(peso_texto, pasos_num, check_nutricion.button_pressed, check_gimnasio.button_pressed, check_estudio.button_pressed, check_nofap.button_pressed)

	# Ocultar panel y refrescar interfaz
	$PanelCheckIn.visible = false
	actualizar_interfaz()

# Ocultamos el Check-In y revelamos la interfaz de juego
	$PanelCheckIn.visible = false
	$HBoxContainer.visible = true
	$LabelJugador.visible = true
	$LabelEnemigo.visible = true

func guardar_jornada(peso: String, pasos: int, nutricion: bool, gym: bool, estudio: bool, nofap: bool):
	var fecha_hoy = Time.get_date_string_from_system() # Formato AAAA-MM-DD
	
	var datos_jornada = {
		"fecha": fecha_hoy,
		"peso": peso,
		"pasos": pasos,
		"nutricion": nutricion,
		"gimnasio": gym,
		"estudio": estudio,
		"nofap": nofap
	}
	
	# Cargar historial existente
	var historial = cargar_historial()
	historial.append(datos_jornada)
	
	# Guardar en archivo JSON local en user://
	var archivo = FileAccess.open("user://historial_habitos.json", FileAccess.WRITE)
	if archivo:
		var json_texto = JSON.stringify(historial, "\t")
		archivo.store_string(json_texto)
		archivo.close()
		agregar_log("💾 Jornada guardada exitosamente en el historial.")

func cargar_historial() -> Array:
	if not FileAccess.file_exists("user://historial_habitos.json"):
		return []
		
	var archivo = FileAccess.open("user://historial_habitos.json", FileAccess.READ)
	if archivo:
		var texto = archivo.get_as_text()
		archivo.close()
		var json = JSON.new()
		if json.parse(texto) == OK:
			return json.get_data()
	return []


func _on_boton_historial_pressed():
	$PanelHistorial.visible = true
	mostrar_metricas_historial()

func _on_boton_cerrar_historial_pressed():
	$PanelHistorial.visible = false

func mostrar_metricas_historial():
	var historial = cargar_historial()
	
	if historial.size() == 0:
		$PanelHistorial/TextoHistorial.text = "[center]⚠️ No hay registros guardados todavía. ¡Completá tu primer día en el Check-in![/center]"
		return
		
	# 1. Cálculo de métricas
	var total_dias = historial.size()
	var racha_gimnasio = 0
	
	# Contar racha de gimnasio de los últimos días
	for i in range(historial.size() - 1, -1, -1):
		if historial[i].get("gimnasio", false):
			racha_gimnasio += 1
		else:
			break # Se corta la racha si un día no se hizo
			
	# Diferencia de peso (Primer registro vs ÚLTIMO registro)
	var primer_peso = float(historial[0].get("peso", "0"))
	var ultimo_peso = float(historial[historial.size() - 1].get("peso", "0"))
	var diff_peso = ultimo_peso - primer_peso
	var texto_peso = str(ultimo_peso) + " kg"
	
	if diff_peso != 0 and primer_peso > 0:
		var signo = "+" if diff_peso > 0 else ""
		texto_peso += " (" + signo + str(snapped(diff_peso, 0.1)) + " kg)"

	# 2. Armar el reporte visual con formato BBCode
	var reporte = "[b]📊 DASHBOARD DE PROGRESO[/b]\n"
	reporte += "---------------------------------------------------------\n"
	reporte += "📅 Días Registrados: " + str(total_dias) + " | 🔥 Racha Gimnasio: " + str(racha_gimnasio) + " días\n"
	reporte += "⚖️ Peso Actual: " + texto_peso + "\n"
	reporte += "---------------------------------------------------------\n"
	reporte += "[b]📜 ÚLTIMOS REGISTROS:[/b]\n\n"
	
	# Recorrer historial (del más reciente al más antiguo)
	var limite = max(0, historial.size() - 5) # Mostrar últimos 5 días
	for i in range(historial.size() - 1, limite - 1, -1):
		var reg = historial[i]
		var fecha = reg.get("fecha", "Sin fecha")
		var pasos = reg.get("pasos", 0)
		var gym = "🏋️" if reg.get("gimnasio", false) else "❌"
		var estudio = "📚" if reg.get("estudio", false) else "❌"
		var nutricion = "🥗" if reg.get("nutricion", false) else "❌"
		
		reporte += "• " + fecha + " | " + str(reg.get("peso", "-")) + "kg | " + str(pasos) + " pasos | Gym:" + gym + " Est:" + estudio + " Nut:" + nutricion + "\n"

	$PanelHistorial/TextoHistorial.bbcode_enabled = true
	$PanelHistorial/TextoHistorial.text = reporte
