extends Node2D

# Referencias a la pantalla
@onready var log_texto: RichTextLabel = $RichTextLabel
@onready var label_jugador: Label = $LabelJugador
@onready var label_enemigo: Label = $LabelEnemigo
@onready var boton_atacar: Button = $HBoxContainer/BotonAtacar
@onready var boton_objeto: Button = $HBoxContainer/BotonObjeto
@onready var boton_siguiente: Button = $HBoxContainer/BotonSiguiente

# Referencias Menú e Interfaz
@onready var panel_menu_inicio: Panel = $PanelMenuInicio
@onready var panel_tienda: Panel = $PanelTienda
@onready var boton_stats: Button = $HBoxContainer/BotonStats

# Variables de estado RPG (Persistentes)
var hp_jugador: int = 20
var hp_max_jugador: int = 20
var ataque_base_jugador: int = 1
var puntos_exploracion: int = 0
var monedas: int = 0
var objetos_conseguidos: Array = []

var hp_enemigo: int = 20
var hp_max_enemigo: int = 20
var ataque_base_enemigo: int = 1

var en_combate: bool = false

func _ready():
	# Conectar botones principales
	boton_atacar.pressed.connect(_on_atacar_pressed)
	boton_siguiente.pressed.connect(_on_siguiente_pressed)
	boton_stats.pressed.connect(_on_boton_stats_pressed)
	
	# Conectar menú inicial de forma segura
	if has_node("PanelMenuInicio/BotonContinuar"):
		$PanelMenuInicio/BotonContinuar.pressed.connect(_on_continuar_partida_pressed)
	if has_node("PanelMenuInicio/BotonNuevaPartida"):
		$PanelMenuInicio/BotonNuevaPartida.pressed.connect(_on_nueva_partida_pressed)

	# Conectar Tienda de forma segura
	if has_node("PanelTienda/BotonComprar1"):
		$PanelTienda/BotonComprar1.pressed.connect(_on_comprar_pocion_pressed)
	if has_node("PanelTienda/BotonComprar2"):
		$PanelTienda/BotonComprar2.pressed.connect(_on_comprar_atq_pressed)
	if has_node("PanelTienda/BotonCerrarTienda"):
		$PanelTienda/BotonCerrarTienda.pressed.connect(_on_cerrar_tienda_pressed)
	
	# Ocultar paneles de juego hasta elegir partida
	$HBoxContainer.visible = false
	$LabelJugador.visible = false
	$LabelEnemigo.visible = false
	$PanelHistorial.visible = false
	$PanelCheckIn.visible = false
	panel_tienda.visible = false
	
	# Mostrar menú principal
	panel_menu_inicio.visible = true
	
	# Habilitar o deshabilitar botón Continuar según exista un guardado
	if has_node("PanelMenuInicio/BotonContinuar"):
		var existe_guardado = FileAccess.file_exists("user://save_slot_1.json")
		$PanelMenuInicio/BotonContinuar.disabled = not existe_guardado

# === LÓGICA DE MENÚ INICIAL ===
func _on_continuar_partida_pressed():
	cargar_estado_juego()
	panel_menu_inicio.visible = false
	$PanelCheckIn.visible = true
	actualizar_interfaz()
	agregar_log("📂 Partida cargada exitosamente. Completá tu Check-In diario.")

func _on_nueva_partida_pressed():
	# Reiniciar variables a valores base
	hp_jugador = 20
	hp_max_jugador = 20
	ataque_base_jugador = 1
	monedas = 0
	objetos_conseguidos.clear()
	
	# Borrar archivo guardado si existe
	if FileAccess.file_exists("user://save_slot_1.json"):
		DirAccess.remove_absolute("user://save_slot_1.json")
		
	panel_menu_inicio.visible = false
	$PanelCheckIn.visible = true
	actualizar_interfaz()
	agregar_log("✨ ¡Nueva partida iniciada! Completá tu Check-In diario.")

func agregar_log(mensaje: String):
	log_texto.append_text(mensaje + "\n")
	if log_texto.get_line_count() > 14:
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
	
	var dado_d20 = randi_range(1, 20)
	agregar_log("-----------------------------------------")
	agregar_log("🎲 Tirada de Exploración (d20): " + str(dado_d20))
	
	if dado_d20 == 1:
		hp_jugador = max(0, hp_jugador - 2)
		agregar_log("💀 ¡PIFIA (1)! Caíste en una trampa. Perdiste 2 HP.")
	elif dado_d20 >= 2 and dado_d20 <= 9:
		agregar_log("⚠️ ¡Un enemigo te embosca en el camino!")
		iniciar_combate()
	elif dado_d20 >= 10 and dado_d20 <= 13:
		agregar_log("🛒 Te cruzaste con un Mercader Ambulante.")
		abrir_tienda()
	elif dado_d20 >= 14 and dado_d20 <= 16:
		monedas += 2
		agregar_log("🪙 Encontraste un par de monedas (+2 Monedas).")
	elif dado_d20 >= 17 and dado_d20 <= 19:
		agregar_log("✨ Encuentro Bueno. Encontraste equipamiento.")
		generar_loot_objeto()
	elif dado_d20 == 20:
		monedas += 5
		agregar_log("🌟 ¡CRÍTICO (20)! ¡Cofre valioso encontrado! (+5 Monedas)")
		generar_loot_objeto()

	actualizar_interfaz()
	guardar_estado_juego()

# === LÓGICA DE TIENDA ===
func abrir_tienda():
	panel_tienda.visible = true
	$PanelTienda/TextoTienda.bbcode_enabled = true
	$PanelTienda/TextoTienda.text = "[b]🛒 TIENDA DEL MERCADER[/b]\n"
	$PanelTienda/TextoTienda.text += "Tus Monedas: " + str(monedas) + " 🪙\n\n"
	$PanelTienda/TextoTienda.text += "1. Poción de Curación (+10 HP) -> 3 Monedas\n"
	$PanelTienda/TextoTienda.text += "2. Piedra de Afilado (+2 ATQ Permanentes) -> 6 Monedas\n"

func _on_comprar_pocion_pressed():
	if monedas >= 3:
		monedas -= 3
		hp_jugador = min(hp_max_jugador, hp_jugador + 10)
		agregar_log("🧪 Compraste una Poción (+10 HP).")
		abrir_tienda()
		actualizar_interfaz()
		guardar_estado_juego()
	else:
		agregar_log("❌ Monedas insuficientes.")

func _on_comprar_atq_pressed():
	if monedas >= 6:
		monedas -= 6
		ataque_base_jugador += 2
		agregar_log("⚔️ Compraste Piedra de Afilado (+2 ATQ).")
		abrir_tienda()
		actualizar_interfaz()
		guardar_estado_juego()
	else:
		agregar_log("❌ Monedas insuficientes.")

func _on_cerrar_tienda_pressed():
	panel_tienda.visible = false
	agregar_log("👋 Saliste de la tienda.")

# === VER STATS ===
func _on_boton_stats_pressed():
	agregar_log("-----------------------------------------")
	agregar_log("🛡️ ESTADÍSTICAS DEL HÉROE:")
	agregar_log("• Vida: " + str(hp_jugador) + " / " + str(hp_max_jugador))
	agregar_log("• Daño Base: " + str(ataque_base_jugador))
	agregar_log("• Monedas: " + str(monedas) + " 🪙")
	if objetos_conseguidos.size() > 0:
		agregar_log("📦 Equipamiento: " + ", ".join(objetos_conseguidos))
	else:
		agregar_log("📦 Equipamiento: Ninguno por ahora.")
	agregar_log("-----------------------------------------")

# === LOOT D100 ===
func generar_loot_objeto():
	var dado_d100 = randi_range(1, 100)
	agregar_log("🎲 Calidad de Objeto (d100): " + str(dado_d100))
	
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
	objetos_conseguidos.append(nombre_calidad)
	agregar_log("📦 Equipo conseguido: " + nombre_calidad + " (+" + str(bonif_hp) + " HP / +" + str(bonif_atq) + " ATQ)")
	guardar_estado_juego()

func iniciar_combate():
	en_combate = true
	hp_enemigo = 20
	hp_max_enemigo = 20
	actualizar_interfaz()
	agregar_log("⚔️ ¡Enemigo a la vista! HP: 20")
	boton_atacar.disabled = false
	boton_siguiente.disabled = true

# === COMBATE ===
func _on_atacar_pressed():
	if not en_combate:
		return
		
	agregar_log("⚔️ TURNO DEL JUGADOR:")
	var dado_precision = randi_range(1, 6)
	
	if dado_precision == 1:
		hp_jugador = max(0, hp_jugador - 3)
		agregar_log("💀 ¡PIFIA! Sacaste 1. Caíste y perdiste 3 HP.")
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
		agregar_log("🎁 Botín del enemigo:")
		generar_loot_objeto()
		boton_atacar.disabled = true
		boton_siguiente.disabled = false
		actualizar_interfaz()
		guardar_estado_juego()
		return

	turno_enemigo()

func turno_enemigo():
	agregar_log("😈 TURNO DEL ENEMIGO:")
	var dado_precision = randi_range(1, 6)
	
	if dado_precision == 1:
		hp_enemigo = max(0, hp_enemigo - 3)
		agregar_log("🤡 ¡PIFIA ENEMIGA! Se autodañó por 3 HP.")
	elif dado_precision in [2, 3]:
		agregar_log("💨 Esquivaste el ataque enemigo.")
	else:
		var dado_d4 = randi_range(1, 4)
		var dano_calculado = ataque_base_enemigo + dado_d4
		
		if dado_precision == 6:
			var dano_critico = dano_calculado * 2
			hp_jugador = max(0, hp_jugador - dano_critico)
			agregar_log("🔥 ¡CRÍTICO ENEMIGO! Recibiste " + str(dano_critico) + " de daño.")
		else:
			hp_jugador = max(0, hp_jugador - dano_calculado)
			agregar_log("🥊 El enemigo golpeó por " + str(dano_calculado) + " de daño.")

	actualizar_interfaz()
	guardar_estado_juego()
	
	if hp_jugador <= 0:
		en_combate = false
		agregar_log("💀 Has sido derrotado...")
		boton_atacar.disabled = true
		boton_siguiente.disabled = true

# === CHECK-IN DIARIO ===
func _on_boton_comenzar_dia_pressed():
	var input_peso = $PanelCheckIn/InputPeso
	var check_gimnasio = $PanelCheckIn/CheckGimnasio
	var check_estudio = $PanelCheckIn/CheckEstudio
	var check_nofap = $PanelCheckIn/CheckNoFap
	var input_pasos = $PanelCheckIn/InputPasos

	var peso_texto = input_peso.text
	var pasos_num = int(input_pasos.text) if input_pasos.text.is_valid_int() else 0
	
	var estado_nutricion: String = "Fuera de Rango"
	if $PanelCheckIn.has_node("OptionNutricion"):
		var idx = $PanelCheckIn/OptionNutricion.selected
		if idx == 1:
			estado_nutricion = "Parcial"
			hp_jugador = min(hp_max_jugador, hp_jugador + 3)
		elif idx == 2:
			estado_nutricion = "En Rango"
			hp_jugador = min(hp_max_jugador, hp_jugador + 5)
	elif $PanelCheckIn.has_node("CheckNutricion"):
		if $PanelCheckIn/CheckNutricion.button_pressed:
			estado_nutricion = "En Rango"
			hp_jugador = min(hp_max_jugador, hp_jugador + 5)

	agregar_log("=== ☀️ INICIO DE JORNADA ===")
	if peso_texto != "":
		agregar_log("⚖️ Peso: " + peso_texto + " kg")
	
	agregar_log("🥗 Nutrición: " + estado_nutricion)
		
	if check_gimnasio.button_pressed:
		ataque_base_jugador += 1
		agregar_log("🏋️ Gimnasio (+1 ATQ Base)")
		
	if check_estudio.button_pressed:
		agregar_log("📚 Estudio completado")
		
	if check_nofap.button_pressed:
		agregar_log("🧠 Perseverancia mantenida")

	puntos_exploracion = 1
	var puntos_extra = pasos_num / 5000
	puntos_exploracion += puntos_extra
	
	if puntos_extra > 0:
		agregar_log("👟 Pasos: " + str(pasos_num) + " (¡+" + str(puntos_extra) + " Pts Extra!)")
	else:
		agregar_log("👟 Pasos: " + str(pasos_num) + " (+1 Pt base)")
		
	agregar_log("=============================\n")
	
	guardar_jornada(peso_texto, pasos_num, estado_nutricion, check_gimnasio.button_pressed, check_estudio.button_pressed, check_nofap.button_pressed)

	$PanelCheckIn.visible = false
	$HBoxContainer.visible = true
	$LabelJugador.visible = true
	$LabelEnemigo.visible = true
	actualizar_interfaz()

# === SISTEMA DE PERSISTENCIA (JSON) ===
func guardar_jornada(peso: String, pasos: int, nutricion: String, gym: bool, estudio: bool, nofap: bool):
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
	
	var datos_completos = cargar_archivo_json()
	datos_completos["historial"].append(datos_jornada)
	escribir_archivo_json(datos_completos)

func guardar_estado_juego():
	var datos_completos = cargar_archivo_json()
	datos_completos["jugador"] = {
		"hp": hp_jugador,
		"hp_max": hp_max_jugador,
		"atq_base": ataque_base_jugador,
		"monedas": monedas,
		"equipamiento": objetos_conseguidos
	}
	escribir_archivo_json(datos_completos)

func cargar_estado_juego():
	var datos_completos = cargar_archivo_json()
	if datos_completos.has("jugador"):
		var stats = datos_completos["jugador"]
		hp_jugador = stats.get("hp", 20)
		hp_max_jugador = stats.get("hp_max", 20)
		ataque_base_jugador = stats.get("atq_base", 1)
		monedas = stats.get("monedas", 0)
		objetos_conseguidos = stats.get("equipamiento", [])

func cargar_archivo_json() -> Dictionary:
	if not FileAccess.file_exists("user://save_slot_1.json"):
		return {"jugador": {}, "historial": []}
		
	var archivo = FileAccess.open("user://save_slot_1.json", FileAccess.READ)
	if archivo:
		var texto = archivo.get_as_text()
		archivo.close()
		var json = JSON.new()
		if json.parse(texto) == OK:
			return json.get_data()
	return {"jugador": {}, "historial": []}

func escribir_archivo_json(datos: Dictionary):
	var archivo = FileAccess.open("user://save_slot_1.json", FileAccess.WRITE)
	if archivo:
		archivo.store_string(JSON.stringify(datos, "\t"))
		archivo.close()

# === HISTORIAL Y BITÁCORA SEMANAL ===
func _on_boton_historial_pressed():
	$PanelHistorial.visible = true
	mostrar_metricas_historial()

func _on_boton_cerrar_historial_pressed():
	$PanelHistorial.visible = false

func mostrar_metricas_historial():
	var datos = cargar_archivo_json()
	var historial = datos.get("historial", [])
	
	if historial.size() == 0:
		$PanelHistorial/TextoHistorial.text = "[center]⚠️ No hay registros guardados todavía.[/center]"
		return
		
	var reporte = "[b]📊 BITÁCORA DE HÁBITOS Y PROGRESO[/b]\n"
	reporte += "---------------------------------------------------------------------------------\n"
	reporte += " FECHA     | PESO   | NUTRICIÓN    | GYM | ESTUDIO | NOFAP | PASOS\n"
	reporte += "---------------------------------------------------------------------------------\n"
	
	var limite = max(0, historial.size() - 7)
	for i in range(historial.size() - 1, limite - 1, -1):
		var reg = historial[i]
		var fecha = reg.get("fecha", "Sin Fecha")
		var peso = reg.get("peso", "-") + "kg"
		var nut = reg.get("nutricion", "Sin datos")
		var gym = " ✅ " if reg.get("gimnasio", false) else " ❌ "
		var est = " ✅ " if reg.get("estudio", false) else " ❌ "
		var nofap = " ✅ " if reg.get("nofap", false) else " ❌ "
		var pasos = str(reg.get("pasos", 0))
		
		reporte += fecha + " | " + peso + " | " + nut + " | " + gym + " | " + est + " | " + nofap + " | " + pasos + "\n"

	$PanelHistorial/TextoHistorial.bbcode_enabled = true
	$PanelHistorial/TextoHistorial.text = reporte
