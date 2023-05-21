extends TabBar

# Load class for autocomplete
var axis = preload("res://Classes/ServoAxis.cs")
var servo_position_file = preload("res://Positions/servo_positions.gd")
var servo_positions = servo_position_file.new()

var patty1_servo = axis.new()
var ketchup_servo = axis.new()
var bread_servo = axis.new()

func _ready():
	servo_positions = servo_position_file.new()
	patty1_servo = $Patty1FeedServo
	ketchup_servo = $KetchupServo
	bread_servo = $BreadServo

func _process(delta):
	servo_position_file = load("res://Positions/servo_positions.gd")
	servo_positions = servo_position_file.new()

func _on_patty1feed_position_write_button_pressed():
	var pos : float = float($Patty1FeedServo/PositionInput.text)
	patty1_servo.ResetPosition(-pos)
	print("Reset Patty 1 Feed dispenser axis to pos. ", -pos)

func _on_ketchup_position_write_button_pressed():
	var pos : float = float($KetchupServo/PositionInput.text)
	ketchup_servo.ResetPosition(-pos)
	print("Reset Ketchup dispenser axis to pos. ", -pos)

func _on_bun_zero_button_pressed():
	bread_servo.ResetPosition(0)
	print("Bun dispenser axis zeroed")

func _on_bun_retract_button_pressed():
	bread_servo.Move(servo_positions.BUN_RETRACTED)

func _on_bun_extend_button_pressed():
	bread_servo.Move(servo_positions.BUN_EXTENDED)
