using Godot;
using System;
using System.IO.Ports;

public partial class Control : Godot.Control
{
	SerialHub serial_hub;

	public override void _Ready()
	{
		serial_hub = GetNode<SerialHub>("/root/SerialHub");
	}

	public override void _Process(double delta)
	{
	}

	public void ConnectSerial(){
		if (!serial_hub.connected){
			string[] ports = serial_hub.GetSerialPorts();
			if (ports.Length > 0)
				serial_hub.ConnectSerialPort(ports[0]);
		}
	}
}
