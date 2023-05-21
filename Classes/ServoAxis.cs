using Godot;

// Wrap the Stepper class to use more meaningful units instead of steps
public partial class ServoAxis : Stepper
{
    [Export] int steps_per_rev = 1600;
    [Export] float units_per_rev = 5.0f;

    public float position {
        get { return (float)position_steps / steps_per_rev * units_per_rev; }
        //set { position_steps = (int)(value / units_per_rev * steps_per_rev); }
    }
    float requested_position {
        get { return (float)requested_position_steps / steps_per_rev * units_per_rev; }
        set { requested_position_steps = (int)(value / units_per_rev * steps_per_rev); }
    }
    public float velocity {
        get { return (float)velocity_steps / steps_per_rev * units_per_rev; }
        // set { velocity_steps = (int)(value / units_per_rev * steps_per_rev); }
    }
    public float acceleration {
        get { return (float)acceleration_steps / steps_per_rev * units_per_rev; }
        // set { acceleration_steps = (int)(value / units_per_rev * steps_per_rev); }
    }

    public ServoAxis()
    {
    }

    public void SetAcceleration(float accel)
    {
        WriteAcceleration((int)(accel / units_per_rev * steps_per_rev));
    }

    public void SetVelocity(float vel)
    {
        WriteVelocity((int)(vel / units_per_rev * steps_per_rev));
    }

    public void Move(float pos)
    {
        WritePosition((int)(pos / units_per_rev * steps_per_rev));
    }

    public void ResetPosition(float pos)
    {
        ResetPositionSteps((int)(pos / units_per_rev * steps_per_rev));
    }

    public bool IsAt(float pos, float tolerence = 0.5f)
    {
        return Mathf.Abs(pos - position) < tolerence;
    }
}
