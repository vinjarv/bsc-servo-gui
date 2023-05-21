extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	var ports = SerialHub.GetSerialPorts()
	SerialHub.ConnectSerialPort(ports[-1])


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
