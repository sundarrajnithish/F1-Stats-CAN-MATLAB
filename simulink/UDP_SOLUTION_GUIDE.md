# F1 Telemetry UDP Solution Guide

## Overview

This guide explains the new UDP-based solution for visualizing F1 telemetry data in Simulink. This approach works without requiring Vector CAN hardware and offers the same functionality as the original CAN-based solution.

## Why UDP Instead of CAN?

After testing, we discovered that the Vector CAN hardware was unavailable or not properly configured on your system. The UDP solution provides the following benefits:
- Works on any computer without special hardware
- Uses simple network communication over localhost
- Maintains the same data format and visualization capabilities
- Easier to debug and test

## Files Included

### MATLAB Files:
1. **F1_Telemetry_UDP.m**
   - Creates and runs the UDP-based Simulink model
   - Displays F1 telemetry data in real-time
   - Includes data logging and scope visualization
   - Handles driver number tracking
   - Built-in fallback to simulated data

### Python Files:
1. **UDP_Send.py**
   - Sends actual F1 telemetry data over UDP
   - Uses the same fastf1 library and data format as CAN_Send.py
   - Includes all drivers from the specified F1 session
   - Same functionality, different transport mechanism

2. **UDP_Test.py**
   - Quick test script that sends random F1 telemetry
   - Perfect for verifying the visualization works without F1 data dependencies
   - Changes drivers occasionally to test driver number display
   - Runs for 30 seconds by default

## How to Use

### Option 1: Full F1 Telemetry Data
1. Start MATLAB and run `F1_Telemetry_UDP.m`
2. Wait for the Simulink model to initialize and start running
3. Open a terminal/command prompt and run:
   ```
   python UDP_Send.py
   ```
4. Watch as real F1 telemetry data is displayed in the Simulink model
5. When finished, run the `stopF1UDP` command in MATLAB

### Option 2: Quick Test with Random Data
1. Start MATLAB and run `F1_Telemetry_UDP.m`
2. Wait for the Simulink model to initialize and start running
3. Open a terminal/command prompt and run:
   ```
   python UDP_Test.py
   ```
4. Watch as random telemetry data is displayed for 30 seconds
5. When finished, run the `stopF1UDP` command in MATLAB

## Troubleshooting

If you encounter issues:

1. **Model not starting**: Check the MATLAB console for error messages
2. **No data displayed**: Make sure the Python script is running and sending data
3. **UDP connection error**: Verify that port 20001 is not blocked by a firewall
4. **Python errors**: Make sure all required libraries are installed with `pip install fastf1 socket struct`

## Technical Details

### Data Format
The UDP data is transmitted in a compact binary format:
- Speed (1 byte, 0-255 km/h)
- Throttle (1 byte, 0-100%)
- Brake (1 byte, 0-100%)
- Gear (1 byte, 1-8)
- RPM (2 bytes, 0-15000)
- Driver Number (1 byte, 1-99)

### UDP Protocol
- Protocol: UDP (connectionless)
- IP: 127.0.0.1 (localhost)
- Port: 20001
- Data rate: 10Hz (100ms interval)
- Format: Big-endian binary data
