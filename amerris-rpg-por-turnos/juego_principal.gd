extends Node2D

# Referencias a la pantalla
@onready var log_texto: RichTextLabel = $RichTextLabel
@onready var label_jugador: Label = $LabelJugador
@onready var label_enemigo: Label = $LabelEnemigo
@onready var boton_atacar: Button = $HBoxContainer/BotonAtacar
@onready var boton_objeto: Button = $HBoxContainer/BotonObjeto
@onready var boton_siguiente: Button = $HBoxContainer/BotonSiguiente
@onready var inventario_pocion: ItemData = preload("res://pocion.tres")

# Variables de estado (NUEVO SISTEMA D&D)
var hp_jugador: int = 20
var hp_max_jugador: int = 20
var ataque_base_jugador: int = 1 # Daño fijo base
var puntos_exploracion: int = 0

var hp_enemigo: int = 20
var hp_max_enemigo: int = 20
var ataque_base_enemigo: int = 1

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
	
	# Si pasa de 12 líneas, limpia el log para que no se acumule tanto
	if log_texto.get_line_count() > 12:
		log_texto.clear()
		log_texto.append_text(mensaje + "\n")

func actualizar_interfaz():
	label_jugador.text = "HP: " + str(hp_jugador) + "/" + str(hp_max_jugador) + " | PTS: " + str(puntos_exploracion)
	if en_combate:
		label_enemigo.text = "Enemigo HP: " + str(hp_enemigo) + "/" + str(hp_max_enemigo)
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
	var curacion = 5
	hp_jugador = min(hp_max_jugador, hp_jugador + curacion)
	actualizar_interfaz()
	agregar_log("⛲ Encontraste una fuente de agua clara. Te curas " + str(curacion) + " de HP.")

func iniciar_combate():
	en_combate = true
	hp_enemigo = 20
	hp_max_enemigo = 20
	actualizar_interfaz()
	agregar_log("⚠️ ¡Un Goblin salvaje te bloquea el paso! (HP: 20)")
	boton_atacar.disabled = false
	boton_siguiente.disabled = true

# SISTEMA DE COMBATE POR TURNOS CON DADOS (1 + d4)
func _on_atacar_pressed():
	if not en_combate:
		return
		
	agregar_log("-----------------------------------------")
	agregar_log("⚔️ TURNO DEL JUGADOR:")
	
	# 1. Tirada de precisión (d6)
	var dado_precision = randi_range(1, 6)
	
	if dado_precision == 1:
		hp_jugador = max(0, hp_jugador - 3)
		agregar_log("💀 ¡PIFIA! Sacaste un 1 en el dado. Te tropezaste y perdiste 3 de HP.")
	elif dado_precision in [2, 3]:
		agregar_log("🛡️ Fallaste el ataque (Sacaste un " + str(dado_precision) + ". Necesitás > 3 para acertar).")
	else:
		# Acierto (4, 5 o 6)
		var dado_d4 = randi_range(1, 4)
		var dano_calculado = ataque_base_jugador + dado_d4
		
		if dado_precision == 6:
			var dano_critico = dano_calculado * 2
			hp_enemigo = max(0, hp_enemigo - dano_critico)
			agregar_log("💥 ¡GOLPE CRÍTICO (6)! [1 + d4(salio " + str(dado_d4) + ")] x 2 = " + str(dano_critico) + " de daño al enemigo.")
		else:
			hp_enemigo = max(0, hp_enemigo - dano_calculado)
			agregar_log("🎯 ¡Acierto! [1 + d4(salio " + str(dado_d4) + ")] = " + str(dano_calculado) + " de daño al enemigo.")

	actualizar_interfaz()
	
	# Verificar si el enemigo murió
	if hp_enemigo <= 0:
		en_combate = false
		agregar_log("🎉 ¡Derrotaste al Goblin!")
		boton_atacar.disabled = true
		boton_siguiente.disabled = false
		return

	# 2. Turno del Enemigo
	turno_enemigo()

func turno_enemigo():
	agregar_log("😈 TURNO DEL ENEMIGO:")
	var dado_precision = randi_range(1, 6)
	
	if dado_precision == 1:
		hp_enemigo = max(0, hp_enemigo - 3)
		agregar_log("🤡 ¡PIFIA DEL ENEMIGO! Sacó un 1 y se autodañó por 3 de HP.")
	elif dado_precision in [2, 3]:
		agregar_log("💨 El enemigo atacó pero esquivaste (Sacó " + str(dado_precision) + ").")
	else:
		var dado_d4 = randi_range(1, 4)
		var dano_calculado = ataque_base_enemigo + dado_d4
		
		if dado_precision == 6:
			var dano_critico = dano_calculado * 2
			hp_jugador = max(0, hp_jugador - dano_critico)
			agregar_log("🔥 ¡CRÍTICO DEL ENEMIGO! [1 + d4(salio " + str(dado_d4) + ")] x 2 = " + str(dano_critico) + " de daño.")
		else:
			hp_jugador = max(0, hp_jugador - dano_calculado)
			agregar_log("🥊 El enemigo te acertó: [1 + d4(salio " + str(dado_d4) + ")] = " + str(dano_calculado) + " de daño.")

	actualizar_interfaz()
	
	if hp_jugador <= 0:
		en_combate = false
		agregar_log("💀 Has sido derrotado... Fin de la exploración por hoy.")
		boton_atacar.disabled = true
		boton_siguiente.disabled = true

func _on_boton_objeto_pressed():
	if inventario_pocion == null:
		agregar_log("❌ No tenés ningún objeto para usar.")
		return

	# Curar al personaje
	hp_jugador = min(hp_max_jugador, hp_jugador + inventario_pocion.curacion)
	agregar_log("🧪 Usaste " + inventario_pocion.nombre + " y recuperaste " + str(inventario_pocion.curacion) + " de HP!")
	
	# Consumir el objeto
	inventario_pocion = null
	actualizar_interfaz()

	# Si estás en combate, usar objeto consume turno y responde el enemigo
	if en_combate:
		turno_enemigo()

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
		hp_jugador = min(hp_max_jugador, hp_jugador + 5)
		agregar_log("🥗 Nutrición en Rango (+5 HP Curado)")
		
	if check_gimnasio.button_pressed:
		ataque_base_jugador += 1
		agregar_log("🏋️ Gimnasio completado (+1 de Daño Base permanente)")
		
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
		
	agregar_log("MAPA: Puntos disponibles: " + str(puntos_exploracion))
	agregar_log("=============================\n")
	
	# Guardar la jornada en el archivo local
	guardar_jornada(peso_texto, pasos_num, check_nutricion.button_pressed, check_gimnasio.button_pressed, check_estudio.button_pressed, check_nofap.button_pressed)

	# Ocultamos el Check-In y revelamos la interfaz de juego
	$PanelCheckIn.visible = false
	$HBoxContainer.visible = true
	$LabelJugador.visible = true
	$LabelEnemigo.visible = true
	actualizar_interfaz()

func guardar_jornada(peso: String, pasos: int, nutricion: bool, gym: bool, estudio: bool, nofap: bool):
	var fecha_hoy = Time.get_date_string_from_system()
	
	var datos_jornada = {
		"fecha": fecha_hoy,
		"peso": peso,
		"pasos": pasos,
		"nutricion": nutricion,
		"gimnasio": gym,
		"estudio": estudio,
		"nofap": nofap
	}
	
	var historial = cargar_historial()
	historial.append(datos_jornada)
	
	var archivo = FileAccess.open("user://historial_habitos.json", FileAccess.WRITE)
	if archivo:
		var json_texto = JSON.stringify(historial, "\t")
		archivo.store_string(json_texto)
		archivo.close()
		agregar_log("💾 Jornada guardada en el historial.")

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
		
	var total_dias = historial.size()
	var racha_gimnasio = 0
	
	for i in range(historial.size() - 1, -1, -1):
		if historial[i].get("gimnasio", false):
			racha_gimnasio += 1
		else:
			break
			
	var primer_peso = float(historial[0].get("peso", "0"))
	var ultimo_peso = float(historial[historial.size() - 1].get("peso", "0"))
	var diff_peso = ultimo_peso - primer_peso
	var texto_peso = str(ultimo_peso) + " kg"
	
	if diff_peso != 0 and primer_peso > 0:
		var signo = "+" if diff_peso > 0 else ""
		texto_peso += " (" + signo + str(snapped(diff_peso, 0.1)) + " kg)"

	var reporte = "[b]📊 DASHBOARD DE PROGRESO[/b]\n"
	reporte += "---------------------------------------------------------\n"
	reporte += "📅 Días Registrados: " + str(total_dias) + " | 🔥 Racha Gimnasio: " + str(racha_gimnasio) + " días\n"
	reporte += "⚖️ Peso Actual: " + texto_peso + "\n"
	reporte += "---------------------------------------------------------\n"
	reporte += "[b]📜 ÚLTIMOS REGISTROS:[/b]\n\n"
	
	var limite = max(0, historial.size() - 5)
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
