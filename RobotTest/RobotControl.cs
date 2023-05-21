using Godot;
using System;
using System.IO.Ports;

public partial class RobotControl : Godot.Control
{
	SerialHub serial_hub;
	Label xlabel;
	Label ylabel;
	Label zlabel;
	Label status_label;
	ColorRect status_rect;
	CheckButton jog_enabled_button;
	[Export] float jog_speed = 50.0f;
	Robot robot;

	Vector3 jog_direction = Vector3.Zero;
	Timer jog_timer = new Timer();

	public override void _Ready()
	{
		serial_hub = GetNode<SerialHub>("/root/SerialHub");
		xlabel = GetNode<Label>("Panel/DRO/DRO_X/HBoxContainer/LabelBG/Label");
		ylabel = GetNode<Label>("Panel/DRO/DRO_Y/HBoxContainer/LabelBG/Label");
		zlabel = GetNode<Label>("Panel/DRO/DRO_Z/HBoxContainer/LabelBG/Label");
		status_label = GetNode<Label>("Panel/StatusLabel");
		status_rect = GetNode<ColorRect>("Panel/StatusLight");
		jog_enabled_button = GetNode<CheckButton>("Panel/JogEnable");
		robot = GetNode<Robot>("Robot");

		AddChild(jog_timer);
		jog_timer.WaitTime = 0.08f;
		jog_timer.OneShot = true;
		jog_timer.Start();

		ConnectSerial();
	}

	public override void _Process(double delta)
	{
		xlabel.Text = " " + robot.position_mm.X.ToString("000.00");
		ylabel.Text = " " + robot.position_mm.Y.ToString("000.00");
		zlabel.Text = " " + robot.position_mm.Z.ToString("000.00");
		status_label.Text = "Robot state: " + robot.state;
		status_rect.Color = (robot.in_position && serial_hub.connected) ? new Color(0, 1, 0) : new Color(1, 0, 0);
		

		if (jog_direction != Vector3.Zero && jog_enabled_button.ButtonPressed && jog_timer.IsStopped())
		{
			robot.Jog(jog_direction * jog_speed * (float)jog_timer.WaitTime, jog_speed);
			jog_timer.Start();
		}
	}

	public void ConnectSerial(){
		if (!serial_hub.connected){
			string[] ports = serial_hub.GetSerialPorts();
			if (ports.Length > 0)
				serial_hub.ConnectSerialPort(ports[ports.Length - 1]); // Try last port
		}
	}

	public override void _Input(InputEvent @event)
	{	
		if (serial_hub == null)
			return;
		if (!serial_hub.connected)
			return;

		
		if (@event.IsActionPressed("up"))
			jog_direction += new Vector3(0, 0, 1);
		if (@event.IsActionReleased("up")){
			jog_direction -= new Vector3(0, 0, 1);
			jog_timer.Start(0);
			robot.CancelJog();
		}

		if (@event.IsActionPressed("down"))
			jog_direction += new Vector3(0, 0, -1);
		if (@event.IsActionReleased("down")){
			jog_direction -= new Vector3(0, 0, -1);
			jog_timer.Start(0);
			robot.CancelJog();
		}

		if (@event.IsActionPressed("left"))
			jog_direction += new Vector3(-1, 0, 0);
		if (@event.IsActionReleased("left")){
			jog_direction -= new Vector3(-1, 0, 0);
			jog_timer.Start(0);
			robot.CancelJog();
		}

		if (@event.IsActionPressed("right"))	
			jog_direction += new Vector3(1, 0, 0);
		if (@event.IsActionReleased("right")){
			jog_direction -= new Vector3(1, 0, 0);
			jog_timer.Start(0);
			robot.CancelJog();
		}

		if (@event.IsActionPressed("forward"))
			jog_direction += new Vector3(0, 1, 0);
		if (@event.IsActionReleased("forward")){
			jog_direction -= new Vector3(0, 1, 0);
			jog_timer.Start(0);
			robot.CancelJog();
		}


		if (@event.IsActionPressed("back"))
			jog_direction += new Vector3(0, -1, 0);
		if (@event.IsActionReleased("back")){
			jog_direction -= new Vector3(0, -1, 0);
			jog_timer.Start(0);
			robot.CancelJog();
		}
	}

	public void _on_x_plus_1_pressed() 		{ robot.MovePosition(robot.position_mm + new Vector3(1, 0, 0)); }
	public void _on_x_plus_10_pressed() 	{ robot.MovePosition(robot.position_mm + new Vector3(10, 0, 0)); }
	public void _on_x_minus_1_pressed() 	{ robot.MovePosition(robot.position_mm + new Vector3(-1, 0, 0)); }
	public void _on_x_minus_10_pressed() 	{ robot.MovePosition(robot.position_mm + new Vector3(-10, 0, 0)); }
	public void _on_y_plus_1_pressed() 		{ robot.MovePosition(robot.position_mm + new Vector3(0, 1, 0)); }
	public void _on_y_plus_10_pressed() 	{ robot.MovePosition(robot.position_mm + new Vector3(0, 10, 0)); }
	public void _on_y_minus_1_pressed() 	{ robot.MovePosition(robot.position_mm + new Vector3(0, -1, 0)); }
	public void _on_y_minus_10_pressed() 	{ robot.MovePosition(robot.position_mm + new Vector3(0, -10, 0)); }
	public void _on_z_plus_1_pressed() 		{ robot.MovePosition(robot.position_mm + new Vector3(0, 0, 1)); }
	public void _on_z_plus_10_pressed() 	{ robot.MovePosition(robot.position_mm + new Vector3(0, 0, 10)); }
	public void _on_z_minus_1_pressed() 	{ robot.MovePosition(robot.position_mm + new Vector3(0, 0, -1)); }
	public void _on_z_minus_10_pressed() 	{ robot.MovePosition(robot.position_mm + new Vector3(0, 0, -10)); }
}
