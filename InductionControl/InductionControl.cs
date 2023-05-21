using Godot;
using System;

public partial class InductionControl : Panel
{
	private Induction induction;
	SerialHub serial_hub;
	private bool connected_prev = false;
	private Timer read_timer = new Timer();
	private Label power_label;
	private ProgressBar power_bar;
	private Label state_label;
	private ColorRect state_color;
	private Label detect_label;
	private float detect_level = 0;
	private int current_state = 0;

	public override void _Ready()
	{
		serial_hub = (SerialHub)GetNode("/root/SerialHub"); // Get autoloaded node

		induction = GetParent<Induction>();

		power_label = (Label)GetNode("PowerDisplay");
		power_bar = (ProgressBar)GetNode("PowerBar");
		state_label = (Label)GetNode("StateDisplay");
		state_color = (ColorRect)GetNode("StateColor");
		detect_label = (Label)GetNode("Panel/DetectLabel");
		
		AddChild(read_timer);
		read_timer.OneShot = true;
		read_timer.WaitTime = 0.2f;
		read_timer.Start();
	}

	public override void _Process(double delta)
	{
		 // Write parameters on connection
        if (serial_hub.connected && !connected_prev) {
			induction.SetPower(0);
        }
        connected_prev = serial_hub.connected;

		if (serial_hub.connected && read_timer.IsStopped() && Visible) {
			power_label.Text = induction.GetPower().ToString() + " W";
			power_bar.Value = induction.current_power;
			current_state = induction.GetState();
			state_label.Text = current_state.ToString();
			read_timer.Start();
		}

		state_color.Color = (serial_hub.connected && current_state == 1) ? new Color(0, 1, 0) : new Color(1, 0, 0);
	}

	public void _on_0_button_pressed() 		{ induction.SetPower(0); }
	public void _on_25_button_pressed() 	{ induction.SetPower(500); }
	public void _on_50_button_pressed() 	{ induction.SetPower(1000); }
	public void _on_75_button_pressed() 	{ induction.SetPower(1500); }
	public void _on_100_button_pressed() 	{ induction.SetPower(2000); }

	public void _on_detect_button_pressed()
	{
		detect_level = induction.RunDetect();
		detect_label.Text = " " + detect_level.ToString("000.00");
	}
}
