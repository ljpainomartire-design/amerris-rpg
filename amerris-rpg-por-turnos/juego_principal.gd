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

var hp_enemigo: int = 0
var ataque_enemigo: int = 8

var en_combate: bool = false

func _ready():
	# Conectamos las funciones a los botones
	boton_atacar.pressed.connect(_on_atacar_pressed)
	boton_siguiente.pressed.connect(_on_siguiente_pressed)
	
	actualizar_interfaz()
	agregar_log("¡Bienvenido a la aventura! Presiona 'Avanzar Evento' para comenzar.")
	boton_atacar.disabled = true

func agregar_log(mensaje: String):
	log_texto.append_text(mensaje + "\n")
	
	# Si pasa de 10 líneas, limpia el log para que no se acumule tanto
	if log_texto.get_line_count() > 10:
		log_texto.clear()
		log_texto.append_text(mensaje + "\n")

func actualizar_interfaz():
	label_jugador.text = "Jugador HP: " + str(hp_jugador)
	if en_combate:
		label_enemigo.text = "Enemigo HP: " + str(hp_enemigo)
	else:
		label_enemigo.text = "Enemigo: Ninguno"

# EVENTOS / EXPLORACIÓN
func _on_siguiente_pressed():
	if en_combate:
		return
		
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
