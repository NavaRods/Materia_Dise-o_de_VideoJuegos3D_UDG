extends Node2D

# Definimos las velocidades de órbita (puedes ajustarlas a tu gusto)
var velocidades = {
	"pivote_mercurio": 2.5,
	"pivote_venus": 1.8,
	"pivote_tierra": 1.2,
	"pivote_marte": 0.9,
	"pivote_jupiter": 0.5,
	"pivote_saturno": 0.3,
	"pivote_urano": 0.2,
	"pivote_neptuno": 0.15,
	"pivote_pluton": 0.1
}

# Esta función se conecta con la señal del Timer
func _on_timer_timeout() -> void:
	# Recorremos cada pivote y lo rotamos según su velocidad
	for nombre_pivote in velocidades.keys():
		var pivote = get_node(nombre_pivote)
		if pivote:
			pivote.rotation_degrees += velocidades[nombre_pivote]
