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

## Define objects
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
@export var ketchup_feed_amount_mm : float = 2.0 	# Distance to feed per portion
@export var ketchup_feedrate : float = 2.0
@export var fast_feedrate : float = 600.0 			# mm/s for fast travel moves
@export var slow_feedrate : float = 200.0 			# mm/s for slower travel moves (with burger assembly in tool)
var ketchup_robot_feedrate
var robot_tolerence = 1.0
var servo_tolerence = 0.5
var ketchup_retract = 3.0 # mm

@onready var step_edit : LineEdit = $MarginContainer/TabContainer/Sequence/StepEdit

# Debug variables
var cooking_enabled : bool = false

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
	if robot == null:
		robot = $MarginContainer/TabContainer/Robot/RobotTest/Robot
	# Update positions from file
	servo_position_file = load("res://Positions/servo_positions.gd")
	servo_positions = servo_position_file.new()
	robot_position_file = load("res://Positions/robot_positions.gd")
	robot_positions = robot_position_file.new()
	# Calculate feedrate for ketchup stripe from positions
	var ketchup_distance = (robot_positions.SAUCE1_P2 - robot_positions.SAUCE1_P1).length()
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
			extraction_fan.SetSpeed(0)
			if !robot.IsAt(robot_positions.HOME, robot_tolerence):
				state_text = "Error: Robot not at initial position " + str(robot_positions.HOME)
			if !bread_servo.IsAt(servo_positions.BUN_RETRACTED, servo_tolerence):
				state_text = "Error: Bun servo not at initial position " + str(servo_positions.BUN_RETRACTED)
			if !patty1_slice_servo.IsAt(servo_positions.PATTY1_SLICE_RETRACTED, servo_tolerence):
				state_text = "Error: Patty 1 slice servo not at initial position " + str(servo_positions.PATTY1_SLICE_RETRACTED)
			if !oven_servo.IsAt(servo_positions.OVEN_BOTTOM, servo_tolerence):
				state_text = "Error: Oven servo not at initial position " + str(servo_positions.OVEN_BOTTOM)
			if !gripper_servo.IsAt(servo_positions.GRIPPER_CLOSED, servo_tolerence):
				state_text = "Error: Gripper servo not at initial position " + str(servo_positions.GRIPPER_CLOSED)
			
			# Check that magazine level is large enough for vending
			if patty1_feed_servo.GetPosition() + patty_feed_amount_mm > 0:
				state_text = "Error: Level too low in patty magazine 1"
			if ketchup_servo.GetPosition() + ketchup_feed_amount_mm + ketchup_retract > 0:
				state_text = "Error: Level too low in ketchup magazine"
			
			# Check if any errors
			if state_text != "Sequence starting":
				state = 999
			else:
				state = 10
		10:
			# ---- Pick up tool 1 (pan) ----
			robot.MoveVelocity(robot_positions.TOOL1_APPROACH, fast_feedrate)
			state = 11
		11:
			robot.MoveVelocity(robot_positions.TOOL1_PICKUP1, fast_feedrate)
			state = 12
		12:
			robot.MoveVelocity(robot_positions.TOOL1_PICKUP2, fast_feedrate)
			state = 13
		13:
			robot.MoveVelocity(robot_positions.TOOL1_PICKUP3, fast_feedrate)
			state = 14
		14:
			robot.MoveVelocity(robot_positions.TOOL1_PICKUP4, fast_feedrate)
			state = 15
		15:
			state_text = "Picking up tool 1"
			# Wait for queued moves to complete
			if robot.InPosition():
				state = 16
				pass
		16:
			robot.MoveVelocity(robot_positions.TOOL1_PICKUP4, fast_feedrate)
			state = 17
		17:
			robot.MoveVelocity(robot_positions.TOOL1_APPROACH, fast_feedrate)
			state = 18
		18:
			robot.MoveVelocity(robot_positions.HOME, fast_feedrate)
			state = 19
		19:
			# Wait for tool change complete
			state_text = "Moving home"
			if robot.InPosition():
				state = 20

		20:
			# ---- Up to preheat pan ----
			robot.MoveVelocity(robot_positions.COOK_APPROACH1, fast_feedrate)
			state = 21
		21:
			robot.MoveVelocity(robot_positions.COOK_APPROACH2, fast_feedrate)
			state = 22
		22:
			robot.MoveVelocity(robot_positions.COOK_INSIDE1, fast_feedrate)
			state = 10023
		10023:
			if robot.IsAt(robot_positions.COOK_INSIDE1, robot_tolerence):
				state = 23
		23:
			oven_servo.SetAcceleration(500)
			oven_servo.SetVelocity(50)
			oven_servo.Move(servo_positions.OVEN_READY)
			state = 24
		24:
			state_text = "Preheating pan"
			if oven_servo.IsAt(servo_positions.OVEN_READY, servo_tolerence):
				state = 25
		25:
			seq_timer.start(4.0)
			if cooking_enabled:
				lower_induction.SetPower(1500)
			state = 26
		26:
			state_text = "Moving to burger patty magazine"
			if seq_timer.is_stopped():
				state = 27
		27:
			lower_induction.SetPower(0)
			oven_servo.Move(servo_positions.OVEN_BOTTOM)
			state = 28
		28:
			robot.MoveVelocity(robot_positions.COOK_APPROACH2, fast_feedrate)
			state = 29
		29:
			robot.MoveVelocity(robot_positions.COOK_APPROACH1, fast_feedrate)
			state = 30
		30:
			robot.MoveVelocity(robot_positions.HOME, fast_feedrate)
			state = 31

		31:
			# Pick up burger slice
			robot.MoveVelocity(robot_positions.SLICE_MAG1_PICKUP, fast_feedrate)
			state = 32
		32:
			if robot.IsAt(robot_positions.SLICE_MAG1_PICKUP, robot_tolerence):
				state = 33
		33:
			patty1_slice_servo.SetAcceleration(1000)
			patty1_slice_servo.SetVelocity(150)
			patty1_slice_servo.Move(servo_positions.PATTY1_SLICE_EXTENDED)
			state = 34
		34: 
			state_text = "Slicing patty"
			if patty1_slice_servo.IsAt(servo_positions.PATTY1_SLICE_EXTENDED, servo_tolerence):
				state = 35
				seq_timer.start(3.5) # Delay for burger to fall
		35:
			if seq_timer.is_stopped():
				state = 36
		36:
			patty1_slice_servo.Move(servo_positions.PATTY1_SLICE_RETRACTED)
			robot.MoveVelocity(robot_positions.HOME, fast_feedrate)
			state = 37
		37:
			if patty1_slice_servo.IsAt(servo_positions.PATTY1_SLICE_RETRACTED, servo_tolerence):
				state = 38
		38:
			# Feed next slice
			patty1_feed_servo.SetAcceleration(100)
			patty1_feed_servo.SetVelocity(10)
			patty1_feed_servo.Move(patty1_feed_servo.GetPosition() + patty_feed_amount_mm)
			state = 40

		40:
			# Up to cook slice
			robot.MoveVelocity(robot_positions.COOK_APPROACH1, fast_feedrate)
			state = 41
		41:
			robot.MoveVelocity(robot_positions.COOK_APPROACH2, fast_feedrate)
			state = 42
		42:
			robot.MoveVelocity(robot_positions.COOK_INSIDE1, fast_feedrate)
			state = 43
		43:
			state_text = "Moving to cooking position"
			if robot.IsAt(robot_positions.COOK_INSIDE1, robot_tolerence):
				state = 44
		44:
			oven_servo.Move(servo_positions.OVEN_READY)
			state = 45
		45:
			if oven_servo.IsAt(servo_positions.OVEN_READY, servo_tolerence):
				state = 46
		46:
			# Preheat upper
			state_text = "Preheating"
			if cooking_enabled:
				upper_induction.SetPower(2000)
			else:
				print("[DEBUG] Upper induction 2000W")
			extraction_fan.SetSpeed(100)
			seq_timer.start(3.0)
			state = 47
		47:
			if seq_timer.is_stopped():
				state = 48
		48:
			# Start cooking
			state_text = "Cooking - high power"
			if cooking_enabled:
				upper_induction.SetPower(1000)
				lower_induction.SetPower(1500)
			else:
				print("[DEBUG] Upper induction 1000W")
				print("[DEBUG] Lower induction 1500W")
			state = 49
		49:
			# Press burger against top
			oven_servo.Move(servo_positions.OVEN_COOK)
			robot.MoveVelocity(robot_positions.COOK_INSIDE2, 50) 	# Move to match speed of servo
			seq_timer.start(5)										# Cook time 1
			state = 50
		50:
			if seq_timer.is_stopped():
				state = 51
		51:
			# Lower power
			state_text = "Cooking - holding at lower power"
			if cooking_enabled:
				upper_induction.SetPower(1200)
				lower_induction.SetPower(1200)
			else:
				print("[DEBUG] Upper induction 1200W")
				print("[DEBUG] Lower induction 1200W")
			seq_timer.start(5)										# Cook time 2
			state = 52
		52:
			if seq_timer.is_stopped():
				state = 53
		53:
			# Raise top power last seconds
			if cooking_enabled:
				lower_induction.SetPower(1000)
				upper_induction.SetPower(1600)
			else:
				print("[DEBUG] Lower induction 1000W")
				print("[DEBUG] Upper induction 1600W")
			seq_timer.start(5)										# Cook time 3
			state = 54
		54:
			state_text = "Cooking - finishing"
			if seq_timer.is_stopped():
				state = 55
		55:
			# Cook finished
			upper_induction.SetPower(0)
			lower_induction.SetPower(0)
			oven_servo.Move(servo_positions.OVEN_BOTTOM)
			robot.MoveVelocity(robot_positions.COOK_INSIDE1, 25)
			state = 56
		56:
			robot.MoveVelocity(robot_positions.COOK_APPROACH2, fast_feedrate)
			state = 57
		57:
			robot.MoveVelocity(robot_positions.COOK_APPROACH1, fast_feedrate)
			state = 58
		58:
			state_text = "Delivering patty to gripper"
			if robot.IsAt(robot_positions.COOK_APPROACH1, robot_tolerence):
				state = 60
		
		60:
			# ---- Pick up patty with gripper
			robot.MoveVelocity(robot_positions.GRIPPER_APPROACH1_T1, fast_feedrate)
			state = 61
		61:
			robot.MoveVelocity(robot_positions.GRIPPER_APPROACH2_T1, fast_feedrate)
			state = 62
		62:
			robot.MoveVelocity(robot_positions.GRIPPER_UNDER_T1, fast_feedrate)
			gripper_servo.SetAcceleration(1000)
			gripper_servo.SetVelocity(100)
			gripper_servo.Move(servo_positions.GRIPPER_OPEN)
			state = 63
		63:
			state_text = "Picking up patty"
			if gripper_servo.IsAt(servo_positions.GRIPPER_OPEN, servo_tolerence) and robot.IsAt(robot_positions.GRIPPER_UNDER_T1, robot_tolerence):
				state = 64
		64:
			robot.MoveVelocity(robot_positions.GRIPPER_INSIDE_T1, fast_feedrate)
			state = 65
		65:
			if robot.IsAt(robot_positions.GRIPPER_INSIDE_T1, robot_tolerence):
				state = 66
		66:
			gripper_servo.Move(servo_positions.GRIPPER_CLOSED)
			state = 67
		67:
			if gripper_servo.IsAt(servo_positions.GRIPPER_CLOSED, servo_tolerence):
				state = 68
		68:
			robot.MoveVelocity(robot_positions.GRIPPER_UNDER_T1, fast_feedrate)
			state = 69
		69:
			robot.MoveVelocity(robot_positions.GRIPPER_APPROACH2_T1, fast_feedrate)
			state = 70
		70:
			robot.MoveVelocity(robot_positions.GRIPPER_APPROACH1_T1, fast_feedrate)
			state = 72
		72:
			if robot.IsAt(robot_positions.GRIPPER_APPROACH1_T1, robot_tolerence):
				state = 73
		73:
			robot.MoveVelocity(robot_positions.HOME, fast_feedrate)
			state = 74
		74:
			state_text = "Changing to tool 2"
			if robot.IsAt(robot_positions.HOME, robot_tolerence):
				state = 80
				
		80:
			# Tool change, switch from 1 to 2
			# Return tool 1
			robot.MoveVelocity(robot_positions.TOOL1_APPROACH, fast_feedrate)
			state = 81
		81:
			robot.MoveVelocity(robot_positions.TOOL1_RETURN1, fast_feedrate)
			state = 82
		82:
			robot.MoveVelocity(robot_positions.TOOL1_RETURN2, fast_feedrate)
			state = 83
		83:
			robot.MoveVelocity(robot_positions.TOOL1_RETURN3, fast_feedrate)
			state = 84
		84:
			robot.MoveVelocity(robot_positions.TOOL1_RETURN4, fast_feedrate)
			state = 85
		85:
			robot.MoveVelocity(robot_positions.TOOL1_APPROACH, fast_feedrate)
			state = 86
		86:
			if robot.IsAt(robot_positions.TOOL1_APPROACH, robot_tolerence):
				state = 90
		90:
			# Pick up tool 2 (carton holder)
			robot.MoveVelocity(robot_positions.TOOL2_APPROACH, fast_feedrate)
			state = 91
		91:
			robot.MoveVelocity(robot_positions.TOOL2_PICKUP1, fast_feedrate)
			state = 92
		92:
			robot.MoveVelocity(robot_positions.TOOL2_PICKUP2, fast_feedrate)
			state = 93
		93:
			robot.MoveVelocity(robot_positions.TOOL2_PICKUP3, slow_feedrate)
			state = 94
		94:
			robot.MoveVelocity(robot_positions.TOOL2_PICKUP4, slow_feedrate)
			state = 95
		95:
			robot.MoveVelocity(robot_positions.TOOL2_APPROACH, slow_feedrate)
			state = 96
		96:
			state_text = "Picking up bottom bun"
			if robot.IsAt(robot_positions.TOOL2_APPROACH, robot_tolerence):
				state = 100

		100:
			# Pick up bun
			robot.MoveVelocity(robot_positions.BUN_MAG1_APPROACH, slow_feedrate)
			state = 101
			# Also at this point, all cooking steam should be gone
			extraction_fan.SetSpeed(0)
		101:
			robot.MoveVelocity(robot_positions.BUN_MAG1_UNDER, slow_feedrate)
			bread_servo.SetAcceleration(1500)
			bread_servo.SetVelocity(200)
			bread_servo.Move(servo_positions.BUN_EXTENDED)
			state = 102
		102:
			if robot.IsAt(robot_positions.BUN_MAG1_UNDER, robot_tolerence):
				state = 104
		104:
			if bread_servo.IsAt(servo_positions.BUN_EXTENDED, servo_tolerence):
				state = 105
		105:
			bread_servo.SetAcceleration(3000)
			bread_servo.SetVelocity(600)
			bread_servo.Move(servo_positions.BUN_RETRACTED)
			seq_timer.start(1.5)
			state = 106
		106:
			if seq_timer.is_stopped():
				state = 107
		107:
			robot.MoveVelocity(robot_positions.BUN_MAG1_APPROACH, slow_feedrate)
			state = 108
		108:
			robot.MoveVelocity(robot_positions.HOME, slow_feedrate)
			state = 109
		109:
			state_text = "Picking up patty"
			if robot.IsAt(robot_positions.HOME, robot_tolerence):
				state = 110

		110:
			# Pick up burger patty
			robot.MoveVelocity(robot_positions.GRIPPER_APPROACH1_T2, slow_feedrate)
			state = 112
		112:
			robot.MoveVelocity(robot_positions.GRIPPER_APPROACH2_T2, slow_feedrate)
			state = 113
		113:
			robot.MoveVelocity(robot_positions.GRIPPER_UNDER_T2, slow_feedrate)
			state = 114
		114:
			if robot.IsAt(robot_positions.GRIPPER_UNDER_T2, robot_tolerence):
				state = 115
		115:
			gripper_servo.Move(servo_positions.GRIPPER_OPEN)
			state = 116
		116:
			if gripper_servo.IsAt(servo_positions.GRIPPER_OPEN, servo_tolerence):
				seq_timer.start(1.0)
				state = 117
		117:
			if seq_timer.is_stopped():
				state = 118
		118:
			gripper_servo.Move(servo_positions.GRIPPER_CLOSED)
			robot.MoveVelocity(robot_positions.GRIPPER_APPROACH2_T2, slow_feedrate)
			state = 119
		119:
			robot.MoveVelocity(robot_positions.GRIPPER_APPROACH1_T2, slow_feedrate)
			state = 121
		121:
			robot.MoveVelocity(robot_positions.HOME, slow_feedrate)
			state = 122
		122:
			if robot.IsAt(robot_positions.HOME, robot_tolerence):
				if true: #TODO add ketchup option check
					state = 130

		130:
			state_text = "Adding ketchup"
			# Get ketchup
			robot.MoveVelocity(robot_positions.SAUCE1_P1, slow_feedrate)
			
			state = 131
		131:
			if robot.IsAt(robot_positions.SAUCE1_P1, robot_tolerence):
				state = 10032
		10032:
			ketchup_servo.SetAcceleration(100)
			ketchup_servo.SetVelocity(ketchup_feedrate)
			ketchup_servo.Move(ketchup_servo.GetPosition() + ketchup_retract)
			seq_timer.start(2.0)
			state = 100033
		10033:
			if seq_timer.is_stopped():
				state = 132
		132:
			ketchup_servo.Move(ketchup_servo.GetPosition() + ketchup_feed_amount_mm)
			seq_timer.start(0.5) 							# Ketchup delay
			state = 133
		133:
			if seq_timer.is_stopped():
				state = 134
		134:
			robot.MoveVelocity(robot_positions.SAUCE1_P2, ketchup_robot_feedrate)
			state = 135
		135:
			if robot.IsAt(robot_positions.SAUCE1_P2, robot_tolerence):
				seq_timer.start(1)
				state = 136
		136:
			if seq_timer.is_stopped():
				state = 137
		137:
			ketchup_servo.Move(ketchup_servo.GetPosition() - ketchup_retract)
			seq_timer.start(1)
			state = 138
		138:
			if seq_timer.is_stopped():
				state = 140

		140:
			state_text = "Picking up top bun"
			# ---- Get top bread ----
			robot.MoveVelocity(robot_positions.BUN_MAG1_APPROACH, slow_feedrate)
			state = 141
		141:
			robot.MoveVelocity(robot_positions.BUN_MAG1_UNDER, slow_feedrate)
			bread_servo.SetAcceleration(1500)
			bread_servo.SetVelocity(200)
			bread_servo.Move(servo_positions.BUN_EXTENDED)
			state = 142
		142:
			if robot.IsAt(robot_positions.BUN_MAG1_UNDER, robot_tolerence):
				state = 144
		144:
			if bread_servo.IsAt(servo_positions.BUN_EXTENDED, servo_tolerence):
				state = 145
		145:
			bread_servo.SetAcceleration(3000)
			bread_servo.SetVelocity(600)
			bread_servo.Move(servo_positions.BUN_RETRACTED)
			seq_timer.start(1.5)
			state = 10046
		10046:
			if seq_timer.is_stopped():
				state = 146
		146:
			robot.MoveVelocity(robot_positions.BUN_MAG1_APPROACH, slow_feedrate)
			state = 147
		147:
			robot.MoveVelocity(robot_positions.HOME, slow_feedrate)
			burger_removed = false # Reset signaling bit
			state = 150
			
		150:
			state_text = "Complete, waiting for manual pickup confirmed"
			# Sequence complete, wait for burger removal and reset
			# Continues from button press
			if burger_removed:
				state = 160
			
		160:
			state_text = "Returning tool 2"
			# Deliver tool 2 to holder
			robot.MoveVelocity(robot_positions.TOOL2_APPROACH, fast_feedrate)
			state = 161
		161:
			robot.MoveVelocity(robot_positions.TOOL2_RETURN1, fast_feedrate)
			state = 162
		162:
			robot.MoveVelocity(robot_positions.TOOL2_RETURN2, fast_feedrate)
			state = 163
		163:
			robot.MoveVelocity(robot_positions.TOOL2_RETURN3, fast_feedrate)
			state = 164
		164:
			robot.MoveVelocity(robot_positions.TOOL2_RETURN4, fast_feedrate)
			state = 165
		165:
			if robot.IsAt(robot_positions.TOOL2_RETURN4, robot_tolerence):
				state = 166
		166:
			robot.MoveVelocity(robot_positions.HOME, fast_feedrate)
			state = 167
		167:
			if robot.IsAt(robot_positions.HOME, robot_tolerence):
				state = 0
				start_requested = false
				# Sequence complete!

		
		999: 
			# An error occured, wait for manual clear
			pass
	# Update state label
	state_label.text = " " + str(state) + " : " + state_text


func _on_start_button_pressed():
	start_requested = true


func _on_pickup_button_pressed():
	burger_removed = true


func _on_step_write_pressed():
	var new_state = step_edit.text.to_int()
	state = new_state


func _on_ketchup_retract_button_pressed():
	ketchup_servo.Move(ketchup_servo.GetPosition() - ketchup_retract)
