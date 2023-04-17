using Godot;

// Stepper motor operation
// Real motor through serial interface, or simulated
public partial class Stepper : Node
{
    public bool simulated = false;
    [Export] int axis_number = -1;  // Axis number for serial interface
    [Export] SerialHub serial_hub;
    protected int position_steps = 0;
    protected int requested_position_steps = 0;
    protected int velocity_steps = 0;
    protected int acceleration_steps = 0;

    public override void _Ready()
    {

    }
    public override void _Process(double delta)
    {
        if (serial_hub.connected) {
            ReadPosition();
            
        }
    }
    private void ReadPosition(){
        string response = serial_hub.Write(axis_number + "");
        if (response != "") {
            string[] parts = response.Split(' ');
            if (parts.Length != 2) {
                GD.Print("[Axis " + axis_number.ToString() + "]: " + "Invalid response from serial hub - too short. " + response);
                return;
            }
            int response_axis = parts[0].ToInt();
            int response_position = parts[1].ToInt(); 
            if (response_axis != axis_number) {
                GD.Print("[Axis " + axis_number.ToString() + "]: " + "Invalid response from serial hub - wrong axis. " + response);
                return;
            }
            position_steps = response_position;
        }
    }
    private void WritePosition(int requested_position)
    {
        requested_position_steps = requested_position;
        serial_hub.Write(axis_number + " " + requested_position_steps);
    }
    private void WriteVelocity(int velocity)
    {
        velocity_steps = velocity;
        serial_hub.Write(axis_number + " F" + velocity_steps);
    }
    public void WriteAcceleration(int acceleration)
    {
        acceleration_steps = acceleration;
        serial_hub.Write(axis_number + " A" + acceleration_steps);
    }
}
