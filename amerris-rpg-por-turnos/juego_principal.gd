extends Node2D

# Referencias a la pantalla
@onready var log_texto: RichTextLabel = $RichTextLabel
@onready var label_jugador: Label = $LabelJugador
@onready var label_enemigo: Label = $LabelEnemigo
@onready var boton_atacar: Button = $HBoxContainer/BotonAtacar
@onready var boton_objeto: Button = $HBoxContainer/BotonObjeto
@onready var boton_siguiente: Button = $HBoxContainer/BotonSiguiente

# Variables de estado
var hp_jugador: int = 20
var hp_max_jugador: int = 20
var ataque_base_jugador: int = 1
var puntos_exploracion: int = 0
var monedas: int = 0

var hp_enemigo: int = 20
var hp_max_enemigo: int = 20
var ataque_base_enemigo: int = 1

var en_combate: bool = false

func _ready():
	boton_atacar.pressed.connect(_on_atacar_pressed)
	boton_siguiente.pressed.connect(_on_siguiente_pressed)
	
	# Ocultamos la interfaz del juego al inicio
	$HBoxContainer.visible = false
	$LabelJugador.visible = false
	$LabelEnemigo.visible = false
	$PanelHistorial.visible = false
	
	$PanelCheckIn.visible = true
	
	actualizar_interfaz()
	agregar_log("👋 ¡Bienvenido! Completá tu Check-In diario para iniciar la jornada.")
	boton_atacar.disabled = true

func agregar_log(mensaje: String):
	log_texto.append_text(mensaje + "\n")
	if log_texto.get_line_count() > 12:
		log_texto.clear()
		log_texto.append_text(mensaje + "\n")

func actualizar_interfaz():
	label_jugador.text = "HP: " + str(hp_jugador) + "/" + str(hp_max_jugador) + " | ATQ: " + str(ataque_base_jugador) + " | 🪙 " + str(monedas) + " | PTS: " + str(puntos_exploracion)
	if en_combate:
		label_enemigo.text = "Enemigo HP: " + str(hp_enemigo) + "/" + str(hp_max_enemigo)
	else:
		label_enemigo.text = "Enemigo: Ninguno"

# === SISTEMA DE EXPLORACIÓN POR DADO D20 ===
func _on_siguiente_pressed():
	if en_combate:
		return
		
	if puntos_exploracion <= 0:
		agregar_log("⚠️ ¡No te quedan Puntos de Exploración por hoy! Salí a caminar o esperá a mañana.")
		return
		
	puntos_exploracion -= 1
	
# Tirada de Evento (D20)
	var dado_d20 = randi_range(1, 20)
	agregar_log("-----------------------------------------")
	agregar_log("🎲 Tirada de Exploración (d20): " + str(dado_d20))
	
	if dado_d20 == 1:
		# Pifia: Muy Malo (-2 HP)
		hp_jugador = max(0, hp_jugador - 2)
		agregar_log("💀 ¡PIFIA (1)! Caíste en una trampa. Perdiste 2 HP.")
		
	elif dado_d20 >= 2 and dado_d20 <= 11:
		# Malo: Pelea (AHORA DEL 2 AL 11 -> 50% DE PROBABILIDAD DE COMBATE)
		agregar_log("⚠️ ¡Un enemigo te embosca en el camino!")
		iniciar_combate()
		
	elif dado_d20 >= 12 and dado_d20 <= 16:
		# Normal: Monedas (del 12 al 16)
		monedas += 2
		agregar_log("🪙 Encontraste un par de monedas tiradas (+2 Monedas).")
		
	elif dado_d20 >= 17 and dado_d20 <= 19:
		# Bueno: Objeto (del 17 al 19)
		agregar_log("✨ Encuentro Bueno. Encontraste un equipamiento.")
		generar_loot_objeto()
		
	elif dado_d20 == 20:
		# Crítico: Cofre
		monedas += 5
		agregar_log("🌟 ¡CRÍTICO (20)! ¡Encontraste un Cofre valioso! (+5 Monedas)")
		generar_loot_objeto()

	actualizar_interfaz()

# === SISTEMA DE LOOT D100 ===
func generar_loot_objeto():
	var dado_d100 = randi_range(1, 100)
	agregar_log("🎲 Tirada de Calidad de Objeto (d100): " + str(dado_d100))
	
	if dado_d100 <= 50:
		aplicar_mejora_objeto("Madera (Calidad 1)", 1, 1)
	elif dado_d100 <= 75:
		aplicar_mejora_objeto("Bronce (Calidad 2)", 3, 3)
	elif dado_d100 <= 85:
		aplicar_mejora_objeto("Acero (Calidad 3)", 4, 4)
	elif dado_d100 <= 94:
		aplicar_mejora_objeto("Acero Doble (Calidad 4)", 5, 5)
	else:
		aplicar_mejora_objeto("Obsidiana (Calidad 5)", 10, 10)

func aplicar_mejora_objeto(nombre_calidad: String, bonif_hp: int, bonif_atq: int):
	hp_max_jugador += bonif_hp
	hp_jugador += bonif_hp
	ataque_base_jugador += bonif_atq
	agregar_log("📦 ¡Conseguiste equipo de " + nombre_calidad + "! (+" + str(bonif_hp) + " HP Máx / +" + str(bonif_atq) + " ATQ Base)")

func iniciar_combate():
	en_combate = true
	hp_enemigo = 20
	hp_max_enemigo = 20
	actualizar_interfaz()
	agregar_log("⚔️ ¡Enemigo a la vista! HP: 20")
	boton_atacar.disabled = false
	boton_siguiente.disabled = true

# === COMBATE POR TURNOS CON DADOS ===
func _on_atacar_pressed():
	if not en_combate:
		return
		
	agregar_log("⚔️ TURNO DEL JUGADOR:")
	var dado_precision = randi_range(1, 6)
	
	if dado_precision == 1:
		hp_jugador = max(0, hp_jugador - 3)
		agregar_log("💀 ¡PIFIA! Sacaste 1. Te tropezaste y perdiste 3 HP.")
	elif dado_precision in [2, 3]:
		agregar_log("🛡️ Fallaste el ataque (Sacaste " + str(dado_precision) + ").")
	else:
		var dado_d4 = randi_range(1, 4)
		var dano_calculado = ataque_base_jugador + dado_d4
		
		if dado_precision == 6:
			var dano_critico = dano_calculado * 2
			hp_enemigo = max(0, hp_enemigo - dano_critico)
			agregar_log("💥 ¡CRÍTICO (6)! [ATQ " + str(ataque_base_jugador) + " + d4(" + str(dado_d4) + ")] x 2 = " + str(dano_critico) + " de daño.")
		else:
			hp_enemigo = max(0, hp_enemigo - dano_calculado)
			agregar_log("🎯 ¡Acierto! [ATQ " + str(ataque_base_jugador) + " + d4(" + str(dado_d4) + ")] = " + str(dano_calculado) + " de daño.")

	actualizar_interfaz()
	
	if hp_enemigo <= 0:
		en_combate = false
		agregar_log("🎉 ¡Derrotaste al enemigo!")
		agregar_log("🎁 El enemigo soltó un objeto al caer:")
		generar_loot_objeto()
		boton_atacar.disabled = true
		boton_siguiente.disabled = false
		actualizar_interfaz()
		return

	turno_enemigo()

func turno_enemigo():
	agregar_log("😈 TURNO DEL ENEMIGO:")
	var dado_precision = randi_range(1, 6)
	
	if dado_precision == 1:
		hp_enemigo = max(0, hp_enemigo - 3)
		agregar_log("🤡 ¡PIFIA ENEMIGA! Sacó 1 y se autodañó por 3 HP.")
	elif dado_precision in [2, 3]:
		agregar_log("💨 Esquivaste el ataque enemigo (Sacó " + str(dado_precision) + ").")
	else:
		var dado_d4 = randi_range(1, 4)
		var dano_calculado = ataque_base_enemigo + dado_d4
		
		if dado_precision == 6:
			var dano_critico = dano_calculado * 2
			hp_jugador = max(0, hp_jugador - dano_critico)
			agregar_log("🔥 ¡CRÍTICO ENEMIGO! Impacto por " + str(dano_critico) + " de daño.")
		else:
			hp_jugador = max(0, hp_jugador - dano_calculado)
			agregar_log("🥊 El enemigo golpeó por " + str(dano_calculado) + " de daño.")

	actualizar_interfaz()
	
	if hp_jugador <= 0:
		en_combate = false
		agregar_log("💀 Has sido derrotado...")
		boton_atacar.disabled = true
		boton_siguiente.disabled = true

func _on_boton_objeto_pressed():
	agregar_log("ℹ️ Tus objetos equipados aumentan tus stats máximos automáticamente.")

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
	
	if check_nutricion.button_pressed:
		hp_jugador = min(hp_max_jugador, hp_jugador + 5)
		agregar_log("🥗 Nutrición (+5 HP Curado)")
		
	if check_gimnasio.button_pressed:
		ataque_base_jugador += 1
		agregar_log("🏋️ Gimnasio (+1 ATQ Base permanente)")
		
	if check_estudio.button_pressed:
		agregar_log("📚 Estudio (+1 Inteligencia)")
		
	if check_nofap.button_pressed:
		agregar_log("🧠 Perseverancia (+1 Claridad)")

	puntos_exploracion = 1
	var puntos_extra = pasos_num / 5000
	puntos_exploracion += puntos_extra
	
	if puntos_extra > 0:
		agregar_log("👟 Pasos: " + str(pasos_num) + " (¡+" + str(puntos_extra) + " Puntos Extra!)")
	else:
		agregar_log("👟 Pasos: " + str(pasos_num) + " (+1 Punto base)")
		
	agregar_log("=============================\n")
	
	guardar_jornada(peso_texto, pasos_num, check_nutricion.button_pressed, check_gimnasio.button_pressed, check_estudio.button_pressed, check_nofap.button_pressed)

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
		agregar_log("💾 Jornada guardada en historial.")

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
		$PanelHistorial/TextoHistorial.text = "[center]⚠️ No hay registros guardados todavía.[/center]"
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
