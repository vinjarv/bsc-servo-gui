extends Node

# Defines robot positions as variables

var HOME = Vector3(0, 0, 0)

# Tool 1
# Frying pan pickup
var TOOL1_APPROACH = 	Vector3(0, 0, 0)		# In front of tool change station

var TOOL1_PICKUP1 = 	Vector3(0, 0, 0)		# Entering wedge
var TOOL1_PICKUP2 = 	Vector3(0, 0, 0)		# In and up to align
var TOOL1_PICKUP3 = 	Vector3(0, 0, 0)		# Up to hook fully
var TOOL1_PICKUP4 = 	Vector3(0, 0, 0)		# Straight away

var TOOL1_RETURN1 = 	Vector3(0, 0, 0)		# In front of pins
var TOOL1_RETURN2 = 	Vector3(0, 0, 0)		# On pins
var TOOL1_RETURN3 = 	Vector3(0, 0, 0)		# Down and clear
var TOOL1_RETURN4 = 	Vector3(0, 0, 0)		# Away

# Tool 2
# Tray holder pickup
var TOOL2_APPROACH = 	Vector3(0, 0, 0)		# In front of tool change station
var TOOL2_PICKUP1 = 	Vector3(0, 0, 0)		# Entering wedge
var TOOL2_PICKUP2 = 	Vector3(0, 0, 0)		# In and up to align
var TOOL2_PICKUP3 = 	Vector3(0, 0, 0)		# Up to hook fully
var TOOL2_PICKUP4 = 	Vector3(0, 0, 0)		# Straight away

var TOOL2_RETURN1 = 	Vector3(0, 0, 0)		# In front of pins
var TOOL2_RETURN2 = 	Vector3(0, 0, 0)		# On pins
var TOOL2_RETURN3 = 	Vector3(0, 0, 0)		# Down and clear
var TOOL2_RETURN4 = 	Vector3(0, 0, 0)		# Away

# Meat magazine
var SLICE_MAG1_PICKUP = Vector3(0, 0, 0) 	# Under meat magazine 1

# Cooking station
var COOK_APPROACH1 = 	Vector3(0, 0, 0)		# From home to height
var COOK_APPROACH2 = 	Vector3(0, 0, 0)		# XY-move to entrance
var COOK_INSIDE1 = 		Vector3(0, 0, 0) 		# Inside, middle
var COOK_INSIDE2 = 		Vector3(0, 0, 0)		# Inside, pressed against the top

# Gripper handover station
var GRIPPER_APPROACH1_T1 = 	Vector3(0, 0, 0)
var GRIPPER_APPROACH2_T1 = 	Vector3(0, 0, 0)
var GRIPPER_UNDER_T1 = 		Vector3(0, 0, 0)
var GRIPPER_INSIDE_T1 = 	Vector3(0, 0, 0)
var GRIPPER_APPROACH1_T2 =  Vector3(0, 0, 0)
var GRIPPER_APPROACH2_T2 = 	Vector3(0, 0, 0)
var GRIPPER_UNDER_T2 = 		Vector3(0, 0, 0)
 
var BUN_MAG1_APPROACH = Vector3(0, 0, 0)
var BUN_MAG1_UNDER = 	Vector3(0, 0, 0)

var SAUCE1_P1 = 		Vector3(0, 0, 0)		
var SAUCE1_P2 = 		Vector3(0, 0, 0)		
