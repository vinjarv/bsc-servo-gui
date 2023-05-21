extends Node

# Defines robot positions as variables

var HOME = Vector3(0, 0, 0)

# Tool 1
# Frying pan pickup
var TOOL1_APPROACH = 	Vector3(-308, 200, 50)		# In front of tool change station

var TOOL1_PICKUP1 = 	Vector3(-463, 211, 50)		# Entering wedge
var TOOL1_PICKUP2 = 	Vector3(-468, 211, 72.6)		# In and up to align
var TOOL1_PICKUP3 = 	Vector3(-468, 211, 86)		# Up to hook fully
var TOOL1_PICKUP4 = 	Vector3(-430, 211, 86)		# Straight away

var TOOL1_RETURN1 = 	Vector3(-430, 211, 86)		# In front of pins
var TOOL1_RETURN2 = 	Vector3(-468, 211, 86)		# On pins
var TOOL1_RETURN3 = 	Vector3(-462, 211, 50)		# Down and clear
var TOOL1_RETURN4 = 	Vector3(-426, 211, 50)		# Away

# Tool 2
# Tray holder pickup
var TOOL2_APPROACH = 	Vector3(-200, 80, 50)		# In front of tool change station
var TOOL2_PICKUP1 = 	Vector3(-466, 62, 50)		# Entering wedge
var TOOL2_PICKUP2 = 	Vector3(-468, 62, 72)		# In and up to align
var TOOL2_PICKUP3 = 	Vector3(-468, 62, 86)		# Up to hook fully
var TOOL2_PICKUP4 = 	Vector3(-438, 62, 86)		# Straight away

var TOOL2_RETURN1 = 	Vector3(-438, 61, 87)		# In front of pins
var TOOL2_RETURN2 = 	Vector3(-470, 61, 87)		# On pins
var TOOL2_RETURN3 = 	Vector3(-462, 61, 50)		# Down and clear
var TOOL2_RETURN4 = 	Vector3(-426, 61, 50)		# Away

# Meat magazine
var SLICE_MAG1_PICKUP = Vector3(-146, 204, 247) 		# Under meat magazine 1

# Cooking station
var COOK_APPROACH1 = 	Vector3(0, 0, 874)		# From home to height
var COOK_APPROACH2 = 	Vector3(-262, 130, 874)		# XY-move to entrance
var COOK_INSIDE1 = 		Vector3(-262, 130, 857) 		# Inside, middle
var COOK_INSIDE2 = 		Vector3(-262, 130, 893)		# Inside, pressed against the top

# Gripper handover station
var GRIPPER_APPROACH1_T1 = 	Vector3(-2, 0, 662)	
var GRIPPER_APPROACH2_T1 = 	Vector3(-2, 193, 662)	
var GRIPPER_UNDER_T1 = 		Vector3(-2, 193, 662)	
var GRIPPER_INSIDE_T1 = 	Vector3(-2, 193, 697)	
var GRIPPER_APPROACH1_T2 =  Vector3(-26, 0, 673)	
var GRIPPER_APPROACH2_T2 = 	Vector3(-26, 202, 673)	
var GRIPPER_UNDER_T2 = 		Vector3(-26, 202, 670)	
 
var BUN_MAG1_APPROACH = Vector3(-70, 30, 200)		
var BUN_MAG1_UNDER = 	Vector3(-292.5, 30.5, 196)		

var SAUCE1_P1 = 		Vector3(-186, 190, 218)		# Start of ketchup stripe
var SAUCE1_P2 = 		Vector3(-120, 190, 218)		# End of ketchup stripe
