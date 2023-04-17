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

	[Export] int step_size = 1600;
	[Export] int jog_speed = 1600;

	public override void _Ready()
	{
		axis_pos_label = GetNode<Label>("Axis1/Panel/PosReadout");
		axis_vel_spinbox = GetNode<SpinBox>("Axis1/VelocityEntry");
		axis_accel_spinbox = GetNode<SpinBox>("Axis1/AccelEntry");
	}

	public override void _Process(double delta)
	{
		if (connected)
		{
			position = GetPosition(1);
			jog_speed = (int)axis_vel_spinbox.Value;
			// Move axis if required
			if (requested_position != position)
			{
				SetPosition(1, requested_position);
			}
			axis_pos_label.Text = position.ToString();

			Vector2 jog_dir = Input.GetVector("left", "right", "down", "up");
			if (jog_dir.Length() > 0)
				requested_position += (int)(jog_dir.X * jog_speed * delta); // Use X axis for jog direction

		}
		else
		{
			axis_pos_label.Text = "N/A";
		}
	}

	public string GetSerialPort(){
		// List all available ports
		string[] ports = SerialPort.GetPortNames();
		if (ports.Length <= 0)
		{
			GD.Print("No ports found");
			return "";
		}
		foreach (string port in ports)
		{
			GD.Print(port);
		}
		return ports[0];
	}
	
	public void ConnectSerial()
	{
		if (connected)
			return;

		// Try to connect to first serial port
		portName = GetSerialPort();
		try
		{
			serialPort = new SerialPort();
			serialPort.PortName = portName;
			serialPort.BaudRate = 115200;
			serialPort.ReadTimeout = 10000;
			serialPort.WriteTimeout = 1000;
			serialPort.RtsEnable = true; 	// Needed for Pi Pico serial comms driver
			serialPort.DtrEnable = true;	// Needed for Pi Pico serial comms driver
			
			if (serialPort.IsOpen)
				serialPort.Close();
			serialPort.Open();

			if (!serialPort.IsOpen)
			{
				GD.Print("Failed to open " + portName);
				connected = false;
				return;
			}

			serialPort.WriteLine("");
			connected = true;
			serialPort.ReadTimeout = 1000;
			GD.Print(serialPort);
			GD.Print("Connected to " + portName);
			// Set up axis
			position = GetPosition(1);
			requested_position = position;
			SetVelocity(1, (int)axis_vel_spinbox.Value);
			SetAcceleration(1, (int)axis_accel_spinbox.Value);
		}
		catch (Exception e)
		{
			GD.Print(e.Message);
			connected = false;
			serialPort.Dispose();
		}
	}

	public int GetPosition(int axis) {
		if (connected)
		{
			try
			{
				serialPort.DiscardInBuffer(); // Clear buffer
				serialPort.WriteLine(axis.ToString());
				string reply = serialPort.ReadLine();
				reply = reply.Trim();
				string[] parts = reply.Split(' ');
				if (parts.Length != 2)
					return 0;

				int reply_axis = parts[0].ToInt();
				int reply_pos = parts[1].ToInt();
				if (reply_axis == axis)
					return reply_pos;
			}
			catch (Exception e) {
				GD.Print("Timeout with ", e);
				connected = false;
				serialPort.Dispose();
			}
		}
		return 0;
	}

	private void _SendCommand(string cmd) {
		if (connected)
		{
			try
			{
				serialPort.DiscardInBuffer(); // Clear buffer
				serialPort.WriteLine(cmd);
				string reply = serialPort.ReadLine();
				// Not checking reply for now
			}
			catch (Exception e) {
				GD.Print("Timeout with ", e);
				connected = false;
				serialPort.Dispose();
			}
		}
	}
	public void SetPosition(int axis, int pos) {
		_SendCommand(axis.ToString() + " " + pos.ToString());
	}
	public void SetVelocity(int axis, int velocity) {
		_SendCommand(axis.ToString() + " F" + velocity.ToString());
	}
	public void SetAcceleration(int axis, int accel) {
		_SendCommand(axis.ToString() + " A" + accel.ToString());
	}

	public void _on_step_fwd_pressed()
	{
		requested_position += step_size;
	}
	public void _on_step_bwd_pressed()
	{
		requested_position -= step_size;
	}
	public void _on_velocity_entry_value_changed(float value)
	{
		SetVelocity(1, (int)value);
	}
	public void _on_accel_entry_value_changed(float value)
	{
		SetAcceleration(1, (int)value);
	}

}
