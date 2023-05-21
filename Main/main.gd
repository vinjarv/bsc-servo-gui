extends Control

# Load classes for autocomplete
# New objects need to be an instance of these for GDScript autocomplete of C# classes
var servo_class = preload("res://Classes/ServoAxis.cs")
var robot_class = preload("res://Classes/Robot.cs")
var induction_class = preload("res://Classes/Induction.cs")
var fan_class = preload("res://Classes/Fan.cs")
var servo_position_file = preload("res://Positions/servo_positions.gd")
var servo_positions = servo_position_file.new()
var robot_position_file = preload("res://Positions/robot_positions.gd")
var robot_positions = robot_position_file.new()

# Define objects
var robot = robot_class.new()
var patty1_feed_servo = servo_class.new()
var ketchup_servo = servo_class.new()
var bread_servo = servo_class.new()
var patty1_slice_servo = servo_class.new()
var oven_servo = servo_class.new()
var gripper_servo = servo_class.new()
var upper_induction = induction_class.new()
var lower_induction = induction_class.new()
var extraction_fan = fan_class.new()

var state : int = 0
var state_text : String = ""
var state_label : Label
var seq_timer : Timer = Timer.new()

var burger_removed : bool = false 	# For signaling that sequence is complete
var start_requested : bool = false  # For signaling

@export var patty_feed_amount_mm : float = 12.0		# Distance to feed per portion
@export var ketchup_feed_amount_mm : float = 1.0 	# Distance to feed per portion
@export var ketchup_feedrate : float = 1.0
var ketchup_robot_feedrate
func _ready():
	var ports = SerialHub.GetSerialPorts()
	if len(ports) > 0:
		SerialHub.ConnectSerialPort(ports[-1])
	seq_timer.one_shot = true
	add_child(seq_timer)
	state_label = $MarginContainer/TabContainer/Sequence/StateMargin/StatePanel/StatePanelMargin/StateLabel
	
	# Find actual objects in scene tree
	robot = $MarginContainer/TabContainer/Robot/RobotTest/Robot
	patty1_feed_servo = $MarginContainer/TabContainer/Magazines/Patty1FeedServo
	ketchup_servo = $MarginContainer/TabContainer/Magazines/KetchupServo
	bread_servo = $MarginContainer/TabContainer/Magazines/BreadServo
	patty1_slice_servo = $MarginContainer/TabContainer/Axes/Patty1SliceServo
	oven_servo = $MarginContainer/TabContainer/Axes/OvenServo
	gripper_servo = $MarginContainer/TabContainer/Axes/BurgerGripperServo
	upper_induction = $MarginContainer/TabContainer/Cooktops/UpperInduction
	lower_induction = $MarginContainer/TabContainer/Cooktops/LowerInduction
	extraction_fan = $MarginContainer/TabContainer/Cooktops/ExtractionFan

func _process(delta):
	# Update positions from file
	servo_position_file = load("res://Positions/servo_positions.gd")
	servo_positions = servo_position_file.new()
	robot_position_file = load("res://Positions/robot_positions.gd")
	robot_positions = robot_position_file.new()
	# Calculate feedrate for ketchup stripe from positions
	var ketchup_distance = (robot_positions.SAUCE1_P2 - robot_positions.SAUCE1_P1)
	ketchup_robot_feedrate = (ketchup_distance / ketchup_feedrate) if (ketchup_distance > 0) else 1
	
	match state:
		0:
			# Idle state, jogging etc. can be done
			state_text = "Machine Idle"
			if start_requested:
				state = 1
				
		1:
			# Check initial positions
			state_text = "Sequence starting"
			# Reset signaling bits
			start_requested = false
			burger_removed = false
			if !robot.IsAt(robot_positions.HOME):
				state_text = "Error: Robot not at initial position " + str(robot_positions.HOME)
			if !bread_servo.IsAt(servo_positions.BUN_RETRACTED):
				state_text = "Error: Bun servo not at initial position " + str(servo_positions.BUN_RETRACTED)
			if !patty1_slice_servo.IsAt(servo_positions.PATTY1_SLICE_RETRACTED):
				state_text = "Error: Patty 1 slice servo not at initial position " + str(servo_positions.PATTY1_SLICE_RETRACTED)
			if !oven_servo.IsAt(servo_positions.OVEN_BOTTOM):
				state_text = "Error: Oven servo not at initial position " + str(servo_positions.OVEN_BOTTOM)
			if !gripper_servo.IsAt(servo_positions.GRIPPER_CLOSED):
				state_text = "Error: Gripper servo not at initial position " + str(servo_positions.GRIPPER_CLOSED)
			
			# Check that magazine level is large enough for vending
			if patty1_feed_servo.position + patty_feed_amount_mm > 0:
				state_text = "Error: Level too low in patty magazine 1"
			if ketchup_servo.position + ketchup_feed_amount_mm > 0:
				state_text = "Error: Level too low in ketchup magazine"
			
			# Check if any errors
			if state_text != "Sequence starting":
				state = 999
			else:
				state = 10
		10:
			# ---- Pick up tool 1 (pan) ----
			robot.MovePosition(robot_positions.TOOL1_APPROACH)
			state = 11
		11:
			robot.MovePosition(robot_positions.TOOL1_PICKUP1)
			state = 12
		12:
			robot.MovePosition(robot_positions.TOOL1_PICKUP2)
			state = 13
		13:
			robot.MovePosition(robot_positions.TOOL1_PICKUP2)
			state = 14
		14:
			robot.MovePosition(robot_positions.TOOL1_PICKUP3)
			state = 15
		15:
			# Wait for queued moves to complete
			if robot.InPosition():
				state = 16
		16:
			robot.MovePosition(robot_positions.TOOL1_PICKUP4)
			state = 17
		17:
			robot.MovePosition(robot_positions.TOOL1_APPROACH)
			state = 18
		18:
			robot.MovePosition(robot_positions.HOME)
			state = 19
		19:
			# Wait for tool change complete
			if robot.InPosition():
				state = 20

		20:
			# ---- Up to preheat pan ----
			robot.MovePosition(robot_positions.COOK_APPROACH1)
			state = 21
		21:
			robot.MovePosition(robot_positions.COOK_APPROACH2)
			state = 22
		22:
			robot.MovePosition(robot_positions.COOK_INSIDE1)
			state = 23
		23:
			oven_servo.WriteAcceleration(1800)
			oven_servo.WriteVelocity(180)
			oven_servo.WritePosition(servo_positions.OVEN_READY)
			state = 24
		24:
			if oven_servo.IsAt(servo_positions.OVEN_READY):
				state = 25
		25:
			seq_timer.start(3.0)
			#lower_induction.SetPower(1500)
			state = 26
		26:
			if seq_timer.is_stopped():
				state = 27
		27:
			lower_induction.SetPower(0)
			oven_servo.WritePosition(servo_positions.OVEN_BOTTOM)
			state = 28
		28:
			robot.MovePosition(robot_positions.COOK_APPROACH2)
			state = 29
		29:
			robot.MovePosition(robot_positions.COOK_APPROACH1)
			state = 30
		30:
			robot.MovePosition(robot_positions.HOME)
			state = 31

		31:
			# Pick up burger slice
			robot.MovePosition(robot_positions.SLICE_MAG1_PICKUP)
			state = 32
		32:
			if robot.IsAt(robot_positions.SLICE_MAG1_PICKUP):
				state = 33
		33:
			patty1_slice_servo.WriteAcceleration(1000)
			patty1_slice_servo.WriteVelocity(150)
			patty1_slice_servo.WritePosition(servo_positions.PATTY1_SLICE_EXTENDED)
			state = 34
		34: 
			if patty1_slice_servo.IsAt(servo_positions.PATTY1_SLICE_EXTENDED):
				state = 35
				seq_timer.start(7.0) # Delay for burger to fall
		35:
			if seq_timer.is_stopped():
				state = 36
		36:
			patty1_slice_servo.WritePosition(servo_positions.PATTY1_SLICE_RETRACTED)
			robot.MovePosition(robot_positions.HOME)
			state = 37
		37:
			# Feed next slice
			patty1_feed_servo.WriteAcceleration(100)
			patty1_feed_servo.WriteVelocity(10)
			patty1_feed_servo.WritePosition(patty1_feed_servo.position + patty_feed_amount_mm)
			state = 40

		40:
			# Up to cook slice
			robot.MovePosition(robot_positions.COOK_APPROACH1)
			state = 41
		41:
			robot.MovePosition(robot_positions.COOK_APPROACH2)
			state = 42
		42:
			robot.MovePosition(robot_positions.COOK_INSIDE1)
			state = 43
		43:
			if robot.IsAt(robot_positions.COOK_INSIDE1):
				state = 44
		44:
			oven_servo.WritePosition(servo_positions.OVEN_READY)
			state = 45
		45:
			if oven_servo.IsAt(servo_positions.OVEN_READY):
				state = 46
		46:
			# Preheat upper
			upper_induction.SetPower(2000)
			seq_timer.start(3.0)
			state = 47
		47:
			if seq_timer.is_stopped():
				state = 48
		48:
			# Start cooking
			upper_induction.SetPower(1000)
			lower_induction.SetPower(1500)
			state = 49
		49:
			# Press burger against top
			oven_servo.WritePosition(servo_positions.OVEN_COOK)
			robot.MoveVelocity(robot_positions.COOK_INSIDE2, 25) 	# Move to match speed of servo
			seq_timer.start(10)										# Cook time 1
			state = 50
		50:
			if seq_timer.is_stopped():
				state = 51
		51:
			# Lower power
			upper_induction.SetPower(1200)
			lower_induction.SetPower(1200)
			seq_timer.start(15)										# Cook time 2
			state = 52
		52:
			if seq_timer.is_stopped():
				state = 53
		53:
			# Raise top power last seconds
			lower_induction.SetPower(1000)
			upper_induction.SetPower(1600)
			seq_timer.start(10)										# Cook time 3
		54:
			if seq_timer.is_stopped():
				state = 55
		55:
			# Cook finished
			upper_induction.SetPower(0)
			lower_induction.SetPower(0)
			oven_servo.WritePosition(servo_positions.OVEN_BOTTOM)
			robot.MoveVelocity(robot_positions.COOK_INSIDE1, 25)
			state = 56
		56:
			robot.MovePosition(robot_positions.COOK_APPROACH2)
			state = 57
		57:
			robot.MovePosition(robot_positions.COOK_APPROACH1)
			state = 58
		58:
			if robot.IsAt(robot_positions.COOK_APPROACH1):
				state = 60
		
		60:
			# ---- Pick up patty with gripper
			robot.MovePosition(robot_positions.GRIPPER_APPROACH1_T1)
			state = 61
		61:
			robot.MovePosition(robot_positions.GRIPPER_APPROACH2_T1)
			state = 62
		62:
			robot.MovePosition(robot_positions.GRIPPER_UNDER_T1)
			gripper_servo.WriteAcceleration(1000)
			gripper_servo.WriteVelocity(100)
			gripper_servo.WritePosition(servo_positions.GRIPPER_OPEN)
			state = 63
		63:
			if gripper_servo.IsAt(servo_positions.GRIPPER_OPEN) and robot.IsAt(robot_positions.GRIPPER_UNDER_T1):
				state = 64
		64:
			robot.MovePosition(robot_positions.GRIPPER_INSIDE_T1)
			state = 65
		65:
			if robot.IsAt(robot_positions.GRIPPER_INSIDE_T1):
				state = 66
		66:
			gripper_servo.WritePosition(servo_positions.GRIPPER_CLOSED)
			state = 67
		67:
			if gripper_servo.IsAt(servo_positions.GRIPPER_CLOSED):
				state = 68
		68:
			robot.MovePosition(robot_positions.GRIPPER_UNDER_T1)
			state = 69
		69:
			robot.MovePosition(robot_positions.GRIPPER_APPROACH2_T1)
			state = 70
		70:
			robot.MovePosition(robot_positions.GRIPPER_APPROACH1_T1)
			state = 71
		71: 
			robot.MovePosition(robot_positions.COOK_APPROACH1)
			state = 72
		72:
			if robot.IsAt(robot_positions.COOK_APPROACH1):
				state = 73
		73:
			robot.MovePosition(robot_positions.HOME)
			state = 74
		74:
			if robot.IsAt(robot_positions.HOME):
				state = 80
				
		80:
			# Tool change, switch from 1 to 2
			# Return tool 1
			robot.MovePosition(robot_positions.TOOL1_APPROACH)
			state = 81
		81:
			robot.MovePosition(robot_positions.TOOL1_RETURN1)
			state = 82
		82:
			robot.MovePosition(robot_positions.TOOL1_RETURN2)
			state = 83
		83:
			robot.MovePosition(robot_positions.TOOL1_RETURN3)
			state = 84
		84:
			robot.MovePosition(robot_positions.TOOL1_RETURN4)
			state = 85
		85:
			robot.MovePosition(robot_positions.TOOL1_APPROACH)
			state = 86
		86:
			if robot.IsAt(robot_positions.TOOL1_APPROACH):
				state = 90
		90:
			# Pick up tool 2 (carton holder)
			robot.MovePosition(robot_positions.TOOL2_APPROACH)
			state = 91
		91:
			robot.MovePosition(robot_positions.TOOL2_PICKUP1)
			state = 92
		92:
			robot.MovePosition(robot_positions.TOOL2_PICKUP2)
			state = 93
		93:
			robot.MovePosition(robot_positions.TOOL2_PICKUP3)
			state = 94
		94:
			robot.MovePosition(robot_positions.TOOL2_PICKUP4)
			state = 95
		95:
			robot.MovePosition(robot_positions.TOOL2_APPROACH)
			state = 96
		96:
			if robot.IsAt(robot_positions.TOOL2_APPROACH):
				state = 100

		100:
			# Pick up bun
			robot.MovePosition(robot_positions.BUN_MAG1_APPROACH)
			state = 101
		101:
			robot.MovePosition(robot_positions.BUN_MAG1_UNDER)
			state = 102
		102:
			if robot.IsAt(robot_positions.BUN_MAG1_UNDER):
				state = 103
		103:
			# Feed one bun part
			bread_servo.WriteAcceleration(3000)
			bread_servo.WriteVelocity(600)
			bread_servo.WritePosition(servo_positions.BUN_EXTENDED)
			state = 104
		104:
			if bread_servo.in_position:
				state = 105
		105:
			bread_servo.WritePosition(servo_positions.BUN_RETRACTED)
			seq_timer.start(1)
			state = 106
		106:
			if seq_timer.is_stopped():
				state = 107
		107:
			robot.MovePosition(robot_positions.BUN_MAG1_APPROACH)
			state = 108
		108:
			robot.MovePosition(robot_positions.HOME)
			state = 109
		109:
			if robot.IsAt(robot_positions.HOME):
				state = 110

		110:
			# Pick up burger patty
			robot.MovePosition(robot_positions.COOK_APPROACH1_T2)
			state = 111
		111:
			robot.MovePosition(robot_positions.GRIPPER_APPROACH1_T2)
			state = 112
		112:
			robot.MovePosition(robot_positions.GRIPPER_APPROACH2_T2)
			state = 113
		113:
			robot.MovePosition(robot_positions.GRIPPER_UNDER_T2)
			state = 114
		114:
			if robot.IsAt(robot_positions.GRIPPER_UNDER_T2):
				state = 115
		115:
			gripper_servo.WritePosition(servo_positions.GRIPPER_OPEN)
			state = 116
		116:
			if gripper_servo.IsAt(servo_positions.GRIPPER_OPEN):
				seq_timer.start(1.0)
				state = 117
		117:
			if seq_timer.is_stopped():
				state = 118
		118:
			gripper_servo.WritePosition(servo_positions.GRIPPER_CLOSED)
			robot.MovePosition(robot_positions.GRIPPER_APPROACH2_T2)
			state = 119
		119:
			robot.MovePosition(robot_positions.GRIPPER_APPROACH1_T2)
			state = 120
		120:
			robot.MovePosition(robot_positions.COOK_APPROACH1)
			state = 121
		121:
			robot.MovePosition(robot_positions.HOME)
			state = 122
		122:
			if robot.IsAt(robot_positions.HOME):
				if true: #TODO add ketchup option check
					state = 130

		130:
			# Get ketchup
			robot.MovePosition(robot_positions.SAUCE1_P1)
			state = 131
		131:
			if robot.IsAt(robot_positions.SAUCE1_P1):
				state = 132
		132:
			ketchup_servo.WriteAcceleration(100)
			ketchup_servo.WriteVelocity(ketchup_feedrate)
			seq_timer.start(0.2) 							# Ketchup delay
			state = 133
		133:
			if seq_timer.is_stopped():
				state = 134
		134:
			robot.MoveVelocity(robot_positions.SAUCE1_P2, ketchup_robot_feedrate)
			state = 135
		135:
			if robot.IsAt(robot_positions.SAUCE1_P2):
				seq_timer.start(1)
				state = 136
		136:
			if seq_timer.is_stopped():
				state = 140

		140:
			# ---- Get top bread ----
			robot.MovePosition(robot_positions.BUN_MAG1_APPROACH)
			state = 141
		141:
			robot.MovePosition(robot_positions.BUN_MAG1_UNDER)
			state = 142
		142:
			if robot.IsAt(robot_positions.BUN_MAG1_UNDER):
				state = 143
		143:
			bread_servo.WritePosition(servo_positions.BUN_EXTENDED)
			state = 144
		144:
			if bread_servo.in_position:
				state = 145
		145:
			bread_servo.WritePosition(servo_positions.BUN_RETRACTED)
			seq_timer.start(1.0)
			state = 146
		146:
			robot.MovePosition(robot_positions.BUN_MAG1_APPROACH)
			state = 147
		147:
			robot.MovePosition(robot_positions.HOME)
			burger_removed = false # Reset signaling bit
			state = 150
			
		150:
			# Sequence complete, wait for burger removal and reset
			# Continues from button press
			if burger_removed:
				state = 160
			
		160:
			# Deliver tool 2 to holder
			robot.MovePosition(robot_positions.TOOL2_APPROACH)
			state = 161
		161:
			robot.MovePosition(robot_positions.TOOL2_RETURN1)
			state = 162
		162:
			robot.MovePosition(robot_positions.TOOL2_RETURN2)
			state = 163
		163:
			robot.MovePosition(robot_positions.TOOL2_RETURN3)
			state = 164
		164:
			robot.MovePosition(robot_positions.TOOL2_RETURN4)
			state = 165
		165:
			if robot.IsAt(robot_positions.TOOL2_RETURN4):
				state = 166
		166:
			robot.MovePosition(robot_positions.HOME)
			state = 167
		167:
			if robot.IsAt(robot_positions.HOME):
				state = 0
				start_requested = false
				# Sequence complete!

		
		999: 
			# An error occured, wait for manual clear
			pass
	# Update state label
	state_label.text = " " + str(state) + " : " + state_text


func _on_start_button_pressed():
	if state == 0:
		state = 1
