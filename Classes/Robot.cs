using Godot;

// Stepper motor operation
// Real motor through serial interface, or simulated
public partial class Robot : Node
{
    public bool simulated = false;
    [Export] public int node_id = 2; // Serial node ID
	[Export] public float update_rate = 5.0f; // Hz
    SerialHub serial_hub;
    public Vector3 position_mm = Vector3.Zero;
    public Vector3 requested_position_mm = Vector3.Zero;
    public string state = "";
    private float position_tolerance_mm = 0.05f;
    public bool in_position { 
        get {
            return  (position_mm.X > (requested_position_mm.X - position_tolerance_mm))
                &&  (position_mm.X < (requested_position_mm.X + position_tolerance_mm))
                &&  (position_mm.Y > (requested_position_mm.Y - position_tolerance_mm))
                &&  (position_mm.Y < (requested_position_mm.Y + position_tolerance_mm))
                &&  (position_mm.Z > (requested_position_mm.Z - position_tolerance_mm))
                &&  (position_mm.Z < (requested_position_mm.Z + position_tolerance_mm));
        }
    }
    private bool connected_prev = false;
	private Timer read_timer = new Timer();

    public override void _Ready()
    {
        serial_hub = (SerialHub)GetNode("/root/SerialHub"); // Get autoloaded node

		// Read position every 0.2 seconds
		AddChild(read_timer);
		read_timer.WaitTime = 1.0f / update_rate;
		read_timer.Start();
		read_timer.OneShot = true;
    }
    public override async void _Process(double delta)
    {
        // Write parameters on connection
        if (serial_hub.connected && !connected_prev) {
			
        }
        connected_prev = serial_hub.connected;

        // Update position at fixed rate
        if (serial_hub.connected && read_timer.IsStopped()) {
            ReadPosition();
			read_timer.Start();
        }
    }
    protected void ReadPosition(){
        string response = serial_hub.Write(node_id + " ?");
        if (response != "") {
			// Response example: <Idle|MPos:0.000,0.000,0.000|FS:0.0,0>
            string[] parts = response.Split('|');
            if (parts.Length < 3) {
                GD.Print("[Robot]: " + "Invalid response from serial hub - too short. " + response);
                return;
            }
			state = parts[0].Replace("<", "");  // Split <Idle

            string data_string = parts[1].Split(':')[1]; //  Split MPos:0.000,0.000,0.000
			string[] data_parts = data_string.Split(',');
			Vector3 response_position = new Vector3(data_parts[0].ToFloat(), data_parts[1].ToFloat(), data_parts[2].ToFloat());
            position_mm = response_position;
        }
    }
    public void MovePosition(Vector3 requested_position)
    {
        requested_position_mm = requested_position;
        serial_hub.Write(node_id + " G0 " + "X" + requested_position_mm.X + " Y" + requested_position_mm.Y + " Z" + requested_position_mm.Z);
    }
    // Velocity in mm/s
    public void MoveVelocity(Vector3 requested_position, float velocity_mms)
    {
        requested_position_mm = requested_position;
        serial_hub.Write(node_id + " G1 F" + velocity_mms * 60 + " X" + requested_position_mm.X + " Y" + requested_position_mm.Y + " Z" + requested_position_mm.Z);
    }

    public void Jog(Vector3 jog_position, float jog_speed)
    {
        requested_position_mm = jog_position;
        serial_hub.Write(node_id + " $J=G91 " + "X" + jog_position.X + " Y" + jog_position.Y + " Z" + jog_position.Z + " F" + jog_speed * 60);
    }

    public void CancelJog() 
    {
        serial_hub.Write(node_id + " " + 0x85);
    }
    public bool InPosition()
    {
        return in_position;
    }
    public bool IsAt(Vector3 pos, float tolerence = 1.0f)
    {
        return (position_mm - pos).Length() < tolerence;
    }
}
