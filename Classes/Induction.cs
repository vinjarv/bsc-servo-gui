using Godot;
using System;
using System.Text.RegularExpressions;

public partial class Induction : Control
{
	public bool simulated = false;
	[Export] public int node_id = 5; // Serial node ID
	SerialHub serial_hub;
	private bool connected_prev = false;
	public uint current_power = 0;

	public override void _Ready()
	{
		serial_hub = (SerialHub)GetNode("/root/SerialHub"); // Get autoloaded node
	}

	public override void _Process(double _delta)
	{
		// Write parameters on connection
        if (serial_hub.connected && !connected_prev) {
			SetPower(0);
			GetPower();
			GD.Print("[Induction] Connected");
        }
        connected_prev = serial_hub.connected;
	}

	public void SetPower(uint power)
	{
		// Limit power level
		power = Math.Clamp(power, 0, 2000);
		String reply = serial_hub.Write(node_id + " P " + power);
		String[] parts = reply.Split(' ');
		if (parts.Length == 0 || parts.Length > 2){
			GD.Print("[Induction] Wrong reply: " + reply);
			return;
		}
		uint reply_node_id = (uint)parts[0].ToInt();
		uint reply_power = (uint)Regex.Replace(parts[1], "[^0-9.]", "").ToFloat();
		GD.Print("Power: " + reply_power);
		if (reply_node_id != node_id){
			GD.Print("[Induction]: wrong node id" + reply);
			return;
		}
		current_power = reply_power;
		GD.Print("[Induction]: " + current_power + "W");
	}
	public uint GetPower()
	{
		String reply = serial_hub.Write(node_id + " P");
		String[] parts = reply.Split(' ');
		if (parts.Length == 0 || parts.Length > 2){
			GD.Print("[Induction] Wrong reply: " + reply);
			return 0;
		}
		uint reply_node_id = (uint)parts[0].ToInt();
		uint reply_power = (uint)Regex.Replace(parts[1], "[^0-9.]", "").ToFloat();
		if (reply_node_id != node_id){
			GD.Print("[Induction]: wrong node id" + reply);
			return 0;
		}
		current_power = reply_power;
		return current_power;
	}
	public float RunDetect() {
		String reply = serial_hub.Write(node_id + " detect");
		String[] parts = reply.Split(' ');
		if (parts.Length == 0 || parts.Length > 2){
			GD.Print("[Induction] Wrong reply: " + reply);
			return 0;
		}
		uint reply_node_id = (uint)parts[0].ToInt();
		float reply_detect = Regex.Replace(parts[1], "[^0-9.]", "").ToFloat();
		if (reply_node_id != node_id){
			GD.Print("[Induction]: wrong node id" + reply);
			return 0;
		}
		return reply_detect;
	}

	public int GetState() {
		String reply = serial_hub.Write(node_id + " state");
		String[] parts = reply.Split(' ');
		if (parts.Length == 0 || parts.Length > 2){
			GD.Print("[Induction] Wrong reply: " + reply);
			return -1;
		}
		uint reply_node_id = (uint)parts[0].ToInt();
		int reply_state = Regex.Replace(parts[1], "[^0-9.]", "").ToInt();
		if (reply_node_id != node_id){
			GD.Print("[Induction]: wrong node id" + reply);
			return -1;
		}
		return reply_state;
	}
}
