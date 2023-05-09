using Godot;
using System;

public partial class AxisJog : Control
{
	// Object references
	private SerialHub serial_hub;
	private ServoAxis axis;
	// UI elements
	Label label_pos;
	SpinBox spinbox_vel;
	SpinBox spinbox_accel;
	float step_size = 10;
	public override void _Ready()
	{
		axis = GetParent<ServoAxis>();
		serial_hub = GetNode<SerialHub>("/root/SerialHub");

		label_pos = GetNode<Label>("Axis1/Panel/PosReadout");
		spinbox_vel = GetNode<SpinBox>("Axis1/VelocityEntry");
		spinbox_accel = GetNode<SpinBox>("Axis1/AccelEntry");
		
		GetNode<Label>("Axis1/AxisLabel").Text = "Axis " + axis.axis_number.ToString();
		axis.SetAcceleration((float)spinbox_accel.Value); // Set initial parameters from UI elements
		axis.SetVelocity((float)spinbox_vel.Value);

		step_size = (float)GetNode<SpinBox>("Axis1/StepSizeEntry").Value;
	}

	public override void _Process(double delta)
	{
		label_pos.Text = axis.position.ToString();
	}

	// UI callbacks
	public void _on_accel_entry_value_changed(float val){
		axis.SetAcceleration(val);
	}
	public void _on_velocity_entry_value_changed(float val){
		axis.SetVelocity(val);
	}
	public void _on_step_size_entry_value_changed(float val){
		step_size = val;
	}
	public void _on_step_fwd_pressed(){
		axis.Move(axis.position + step_size);
	}
	public void _on_step_bwd_pressed(){
		axis.Move(axis.position - step_size);
	}
}


