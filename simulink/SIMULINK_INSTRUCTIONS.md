# Running the F1 Telemetry Visualization System

This document provides instructions for running the F1 telemetry visualization system with Simulink.

## System Overview

The system consists of:

1. **Python Sender** (`CAN_Send.py`): Extracts F1 telemetry data and sends it over CAN
2. **Simulink Model** (`F1_Telemetry_Sim.slx`): Receives and visualizes CAN data
3. **MATLAB Scripts** (`CAN_Receive.m`, etc.): Alternative visualization options

## Step-by-Step Instructions

### Option 1: Full CAN Setup with Python

1. **Create/Fix the Simulink Model**
   - Run one of these scripts in MATLAB:
     - `F1_Telemetry_Direct_Fix.m` (recommended)
     - `CAN_Simulink_Fix.m` (alternative)

2. **Start Python Data Sender**
   - Open a command prompt and run:
   ```
   python CAN_Send.py
   ```

3. **Run the Simulink Model**
   - In MATLAB, click the "Run" button in the Simulink model
   - You should see real-time data display in the scopes

4. **Stop the Simulation**
   - Click the "Stop" button in Simulink when done
   - The collected data will be available in the MATLAB workspace

### Option 2: Testing with Simulated Data

If you don't have a Vector CAN setup:

1. **Run the Test Script**
   ```matlab
   Test_F1_Telemetry_Sim
   ```

2. **Observe Simulation Results**
   - The script will run with simulated F1 telemetry data
   - Data will be available in the MATLAB workspace after completion

### Option 3: MATLAB Direct Reception

As an alternative to Simulink:

1. **Start Python Data Sender**
   ```
   python CAN_Send.py
   ```

2. **Run MATLAB Receiver**
   ```matlab
   CAN_Receive
   ```
   or
   ```matlab
   CAN_Receive_Performance
   ```

3. **Analyze Logged Data**
   - Use saved CSV files for further analysis
   - Or use `CAN_Driver_Analysis.m` to compare drivers

## Troubleshooting

### CAN Connection Issues
- Ensure Vector CAN setup is installed and configured
- Check that the CAN channel (Virtual 1) is available
- Verify the bitrate is set to 500000 in both Python and MATLAB/Simulink

### No Data Displayed in Simulink
- Make sure the Python script is running
- Check that the message IDs match (0x123)
- Try the Test_F1_Telemetry_Sim.m script to test with simulated data

### Other Issues
- Restart MATLAB/Simulink
- Reinstall Vector CAN drivers if needed
- Check MATLAB command window for error messages

## System Requirements

- MATLAB R2019b or newer
- Simulink
- Vehicle Network Toolbox (for CAN communication)
- Python 3.x with fastf1 and python-can packages
- Vector CAN driver software
