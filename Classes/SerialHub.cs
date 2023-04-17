using Godot;
using System;
using System.IO.Ports;

public partial class SerialHub : Node 
{
    SerialPort serialPort;
    public bool connected = false;
    string portName = "";
    [Export] int baudrate = 115200;
    public override void _Ready()
    {

    }
    public override void _Process(double delta)
    {
        
    }
    public string[] GetSerialPorts(){
        // List all available ports
        string[] ports = SerialPort.GetPortNames();
        if (ports.Length <= 0)
        {
            GD.Print("No ports found");
            return ports;
        }
        GD.Print("Available ports:");
        foreach (string port in ports)
        {
            GD.Print(port);
        }
        GD.Print("");
        return ports;
    }
    public void ConnectSerialPort(string portName)
    {
        if (connected)
        {
            GD.Print("Already connected");
            return;
        }
        serialPort = new SerialPort(portName, baudrate);
        serialPort.Open();
        connected = true;
        GD.Print("Connected to " + portName);
    }
    public void DisconnectSerialPort()
    {
        if (!connected)
        {
            GD.Print("Not connected");
            return;
        }
        serialPort.Close();
        connected = false;
        GD.Print("Disconnected");
    }

    //TODO: Add multiple ports
    // public string Write(int device, string message)
    // {
    //     if (!connected)
    //     {
    //         return "";
    //     }
    //     serialPort.DiscardInBuffer();
    //     serialPort.Write(device.ToString() + message);
    //     return serialPort.ReadLine();
    // }

    public string Write(string message)
    {
        if (!connected)
        {
            return "";
        }
        serialPort.DiscardInBuffer();
        serialPort.Write(message);
        return serialPort.ReadLine();
    }


}
