using Godot;
using System;
using System.IO.Ports;

public partial class SerialHub : Node 
{
    SerialPort serialPort;
    public bool connected = false;
    string portName = "";
    [Export] int baudrate = 115200;
    private static Mutex mut = new Mutex();
    long receive_timeout_ms = 2;
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
        serialPort.ReadTimeout = 5000;
        serialPort.WriteTimeout = 1000;
        serialPort.Open();
        connected = true;
        serialPort.ReadTimeout = 1000;
        serialPort.RtsEnable = true; // Needed for Pi Pico driver
        serialPort.DtrEnable = true;
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
        string[] parts = message.Split(' ');
        int node_id = parts[0].ToInt();
        mut.Lock();
        try{
            if (!connected){
                mut.Unlock();
                return "";
            }
            serialPort.DiscardInBuffer();
            long send_timestamp_ms = DateTime.Now.Ticks / TimeSpan.TicksPerMillisecond;
            serialPort.WriteLine(message);
            while (true) {
                // Read from serial port until data received from correct node, or timeout
                string reply = serialPort.ReadLine();
                reply = reply.Trim();
                string[] reply_parts = reply.Split(' ');
                int reply_node = (int)reply_parts[0].ToFloat();
                long timestamp_now_ms = DateTime.Now.Ticks / TimeSpan.TicksPerMillisecond;
                if (reply_node == node_id || (timestamp_now_ms - send_timestamp_ms < 10)){
                    mut.Unlock();
                    return reply;
                }
            }
        } catch (Exception e){
            GD.Print("Serial error: " + e);
            // serialPort.Dispose();
            // connected = false;
            mut.Unlock();
            return "";
        }
    }
}
