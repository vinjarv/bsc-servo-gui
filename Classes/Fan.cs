using Godot;
using System;

public partial class Fan : Control
{
	public bool simulated = false;
	[Export] public int node_id = 0; // Serial node ID
	SerialHub serial_hub;
	private bool connected_prev = false;
	public override void _Ready()
	{
		serial_hub = (SerialHub)GetNode("/root/SerialHub"); // Get autoloaded node
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
		// Write parameters on connection
        if (serial_hub.connected && !connected_prev) {
			GD.Print("[Fan] Connected");
        }
        connected_prev = serial_hub.connected;
	}
	public void SetSpeed(float speed) 
	{
		if (!serial_hub.connected)
			return;
		// Limit speed level
		uint write_speed = (uint)Math.Clamp(speed, 0, 100);
		serial_hub.Write(node_id + " fan " + speed);
	}
}
