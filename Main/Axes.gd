extends TabBar

# Load class for autocomplete
var axis = preload("res://Classes/ServoAxis.cs")
var servo_position_file = preload("res://Positions/servo_positions.gd")
var servo_positions = servo_position_file.new()

var patty1_slice_servo = axis.new()
var oven_servo = axis.new()
var gripper_servo = axis.new()

func _ready():
	servo_positions = servo_position_file.new()
	patty1_slice_servo = $Patty1SliceServo
	oven_servo = $OvenServo
	gripper_servo = $BurgerGripperServo

func _process(delta):
	servo_position_file = load("res://Positions/servo_positions.gd")
	servo_positions = servo_position_file.new()

func _on_patty1_slicer_zero_button_pressed():
	patty1_slice_servo.ResetPosition(0);
	print("Patty slicer axis zeroed")

func _on_oven_zero_button_pressed():
	oven_servo.ResetPosition(0);
	print("Oven lift axis zeroed")

func _on_gripper_zero_button_pressed():
	gripper_servo.ResetPosition(0);
	print("Oven lift axis zeroed")

func _on_patty1_slice_retract_button_pressed():
	patty1_slice_servo.WritePosition(servo_positions.PATTY1_SLICE_RETRACTED)

func _on_patty1_slice_extend_button_pressed():
	patty1_slice_servo.WritePosition(servo_positions.PATTY1_SLICE_EXTENDED)

func _on_oven_down_pos_button_pressed():
	oven_servo.WritePosition(servo_positions.OVEN_BOTTOM)

func _on_oven_ready_pos_button_pressed():
	oven_servo.WritePosition(servo_positions.OVEN_READY)

func _on_oven_cook_pos_button_pressed():
	oven_servo.WritePosition(servo_positions.OVEN_COOK)

func _on_gripper_close_button_pressed():
	gripper_servo.WritePosition(servo_positions.GRIPPER_CLOSED)

func _on_gripper_open_button_pressed():
	gripper_servo.WritePosition(servo_positions.GRIPPER_OPEN)
