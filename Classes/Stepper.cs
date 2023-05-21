using Godot;

// Stepper motor operation
// Real motor through serial interface, or simulated
public partial class Stepper : Control
{
    public bool simulated = false;
    [Export] public int node_id = 1; // Serial node ID
    [Export] public int axis_number = -1;  // Axis number for serial interface
    [Export] public float read_frequency = 12.0f; // Hz
    SerialHub serial_hub;
    protected int position_steps = 0;
    protected int requested_position_steps = 0;
    protected int velocity_steps = 0;
    protected int acceleration_steps = 0;
    public bool in_position {
        get { return position_steps == requested_position_steps; }
    }
    private bool connected_prev = false;
    private Timer read_timer = new Timer();

    public override void _Ready()
    {
        serial_hub = (SerialHub)GetNode("/root/SerialHub"); // Get autoloaded node
        AddChild(read_timer);
        read_timer.OneShot = true;
        read_timer.WaitTime = 1.0f / read_frequency;
        read_timer.Start();
    }
    public override void _Process(double delta)
    {
        // Write parameters on connection
        if (serial_hub.connected && !connected_prev) {
                WriteVelocitySteps(velocity_steps);
                WriteAccelerationSteps(acceleration_steps);
        }
        connected_prev = serial_hub.connected;

        // Update position at fixed rate
        if (serial_hub.connected && read_timer.IsStopped()) {
            ReadPosition();
            read_timer.Start();
        }
    }
    protected void ReadPosition(){
        string response = serial_hub.Write(node_id + " " + axis_number.ToString());
        if (response != "") {
            string[] parts = response.Split(' ');
            if (parts.Length != 3) {
                GD.Print("[Axis " + axis_number.ToString() + "]: " + "Invalid response from serial hub - too short. " + response);
                return;
            }
            int response_node_id = parts[0].ToInt();
            if (response_node_id != node_id) {
                GD.Print("[Axis " + axis_number.ToString() + "]: " + "Invalid response from serial hub - wrong node ID. " + response);
                return;
            }
            int response_axis = parts[1].ToInt();
            int response_position = parts[2].ToInt(); 
            if (response_axis != axis_number) {
                GD.Print("[Axis " + axis_number.ToString() + "]: " + "Invalid response from serial hub - wrong axis. " + response);
                return;
            }
            position_steps = response_position;
        }
    }
    protected void WritePositionSteps(int requested_position)
    {
        requested_position_steps = requested_position;
        serial_hub.Write(node_id + " " + axis_number + " " + requested_position_steps);
    }
    protected void WriteVelocitySteps(int velocity)
    {
        velocity_steps = velocity;
        serial_hub.Write(node_id + " " + axis_number + " F" + velocity_steps);
    }
    public void WriteAccelerationSteps(int acceleration)
    {
        acceleration_steps = acceleration;
        serial_hub.Write(node_id + " " + axis_number + " A" + acceleration_steps);
    }
    protected void ResetPositionSteps(int new_position)
    {
        serial_hub.Write(node_id + " " + axis_number + " W" + new_position);
        position_steps = new_position;
        requested_position_steps = new_position;
    }
}
