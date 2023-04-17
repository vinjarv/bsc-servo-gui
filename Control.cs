using Godot;
using System;
using System.IO.Ports;

public partial class Control : Godot.Control
{
	SerialPort serialPort;
	bool connected = false;
	string portName = "";
	Label axis_pos_label;
	SpinBox axis_vel_spinbox;
	SpinBox axis_accel_spinbox;
	int position = 0;
	int requested_position = 0;
	SerialHub serial_hub;

	[Export] int step_size = 1600;
	[Export] int jog_speed = 1600;

	public override void _Ready()
	{
		serial_hub = GetNode<SerialHub>("SerialHub");
	}

	public override void _Process(double delta)
	{
		var axes = GetNode<Node>("Axes").GetChild(0) as ServoAxis;
		GetNode<Label>("Axis1/Panel/PosReadout").Text = axes.position.ToString();
	}

	public void ConnectSerial(){
		if (!serial_hub.connected){
			string[] ports = serial_hub.GetSerialPorts();
			if (ports.Length > 0)
				serial_hub.ConnectSerialPort(ports[0]);
		}
	}


}
