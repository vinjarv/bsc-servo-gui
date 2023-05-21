extends Control

var RobotClass = preload("res://Classes/Robot.cs")
var robot = RobotClass.new()

var state = 0;


func _ready():
	robot = $Robot # Replace template object with the one from tree
	var ports = SerialHub.GetSerialPorts()
	SerialHub.ConnectSerialPort(ports[len(ports) - 1])

func _process(delta):
	var p = preload("res://StateTest/pos.gd").new()
	
	$SpinBox.value = state
	
	match state:
		0:
			pass
		1:
			print("Starting")
			robot.MoveVelocity(Vector3(0, 100, 0), 160)
			state = 2
		2:
			robot.MovePosition(Vector3(-100, 100, 0))
			state = 3
		3:
			robot.MovePosition(Vector3(-100, 0, 0))
			state = 4
		4:
			robot.MovePosition(Vector3(0, 0, 0))
			state = 10
		10:
			robot.MovePosition(Vector3(0, 0, 100))
			state = 11
		11:
			if robot.InPosition():
				state = 12
		12:
			robot.MovePosition(Vector3(0, 100, 100))
			state = 13
		13:
			robot.MovePosition(Vector3(-100, 100, 100))
			state = 14
		14:
			robot.MovePosition(Vector3(-100, 0, 100))
			state = 15
		15:
			robot.MovePosition(Vector3(0, 0, 100))
			state = 16
		16:
			# Diagonal
			robot.MovePosition(Vector3(-100, 100, 100))
			state = 21
		21:
			# Home
			robot.MoveVelocity(Vector3(0, 0, 0), 100)
			state = 22
		22:
			if robot.InPosition():
				state = 0

func _on_spin_box_value_changed(value):
	state = int(value)
