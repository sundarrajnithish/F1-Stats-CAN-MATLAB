# F1 Telemetry Simulink Visualization - Solutions Guide

This guide explains the different solutions provided for visualizing F1 telemetry data in Simulink and addresses the issues you encountered with the original model.

## Issues Fixed

1. **Model name shadowing conflict**
   - Created new models with unique names to avoid conflicts
   - Used `F1_Telemetry_Sim_v3` and other unique names

2. **Vector CAN blocks dependency**
   - Created alternatives that work without Vehicle Network Toolbox
   - Added simulation capability to test without CAN hardware

3. **DisplayLabel and BufferSize parameter errors**
   - Fixed parameter issues by using minimal, universally supported parameters
   - Added proper text annotation blocks for warnings/labels
   - Removed incompatible scope parameters

4. **Live CAN Data Visualization**
   - Fixed issues with real-time data updates in Simulink
   - Implemented better global variable management for CAN reception
   - Created a true real-time visualization solution with continuous updates

## Solution Files

### 1. **F1_Telemetry_UDP.m (NEWEST - RECOMMENDED)**
   - Complete real-time solution using UDP instead of CAN
   - Works on any system without requiring Vector CAN hardware
   - Compatible with the new UDP_Send.py and UDP_Test.py scripts
   - Falls back to simulated data if UDP communication fails
   - Includes proper cleanup and error handling

### 2. **UDP_Send.py (NEW)**
   - Modified version of CAN_Send.py that uses UDP instead of CAN
   - Sends F1 telemetry data over UDP port 20001
   - Same functionality as CAN_Send.py but doesn't require Vector hardware
   - Uses simple network protocol compatible with MATLAB's UDP receiver

### 3. **UDP_Test.py (NEW)**
   - Simple test script that sends random F1 telemetry data via UDP
   - Useful for testing the UDP connection without F1 data dependencies
   - Sends data for 30 seconds with driver changes to test visualization
   - Great for quick testing of the UDP-based visualization model

### 4. **F1_Telemetry_CAN_Live.m**
   - Complete real-time solution for live CAN data visualization
   - Uses a more robust approach for updating the model with live data
   - Properly handles timeseries updates for continuous visualization
   - Falls back to simulated data if Vector CAN hardware is unavailable
   - Includes cleanup routines and better error handling

### 5. **Test_CAN_Connection.m**
   - Simple diagnostic script to verify CAN hardware connectivity
   - Tests connection to Vector CAN hardware and displays messages
   - Useful for troubleshooting connectivity issues before running models
   - Shows detailed error messages and possible solutions

### 3. **F1_Telemetry_Direct_Fix_v3.m**
   - Updated solution that creates an improved model with Vector CAN support
   - Falls back to simulated data if Vector CAN toolbox is not available
   - Properly displays all telemetry signals with scopes
   - Fixed all parameter compatibility issues
   - Uses minimal scope configuration that works across MATLAB versions

### 4. **F1_Telemetry_Simple.m**
   - Ultra-simplified model that works with any MATLAB version
   - Minimal parameters to avoid compatibility issues
   - Includes manual switch to choose between data sources
   - Basic model for quickly testing without errors

### 5. **Test_F1_Telemetry_Sim_v2.m**
   - Test script for the v3 model
   - Simulates multiple F1 drivers with different driving styles
   - Generates realistic telemetry data that matches CAN_Send.py format
   - Configures the model to use simulated data

### 6. **F1_Telemetry_Standalone.m**
   - Completely standalone solution that doesn't rely on CAN hardware
   - Creates a simpler model focused on visualization
   - Works with simulated data from the test script
   - Includes basic dashboard and data logging

### 7. **Test_F1_Telemetry_Standalone.m**
   - Generates realistic F1 telemetry based on a circuit profile
   - Creates visualization of the simulated data
   - Prepares data in the format expected by the model
   - Includes option to run the model directly

## How to Choose a Solution

### Option 1: UDP Solution (NEWEST & RECOMMENDED)
1. Run `F1_Telemetry_UDP.m` to create and start the real-time model
2. Run `UDP_Send.py` or `UDP_Test.py` in a separate terminal
3. Watch as the model displays live telemetry with continuous updates
4. Use `stopF1UDP` to properly clean up when finished

### Option 2: Best Real-Time CAN Solution (Requires Vector Hardware)
1. Run `F1_Telemetry_CAN_Live.m` to create and start the real-time model
2. Run your `CAN_Send.py` script in a separate terminal
3. Watch as the model displays live telemetry with continuous updates
4. Use `stopF1CANLive` to properly clean up when finished

### Option 2: Verify CAN Hardware First
1. Run `Test_CAN_Connection.m` to check if CAN hardware is working
2. If successful, then run `F1_Telemetry_CAN_Live.m` for visualization
3. If hardware test fails, check the error messages for troubleshooting steps

### Option 3: Simplest Solution (No CAN Requirements)
1. Run `F1_Telemetry_Simple.m` to create the minimal model
2. This works with any MATLAB version and comes with simulated data
3. Run the model to see simulated telemetry

### Option 4: If you have Vehicle Network Toolbox
1. Run `F1_Telemetry_Direct_Fix_v3.m` to create the improved model
2. Run your `CAN_Send.py` script
3. Run the Simulink model to see live telemetry

### Option 5: Without Vehicle Network Toolbox
1. Run `F1_Telemetry_Standalone.m` to create the standalone model
2. Run `Test_F1_Telemetry_Standalone.m` to generate test data
3. Run the standalone model to visualize the data

### Option 6: Testing with simulated multi-driver data
1. Run `F1_Telemetry_Direct_Fix_v3.m` to create the model
2. Run `Test_F1_Telemetry_Sim_v2.m` to simulate multiple drivers
3. Observe the differences in driving styles in the scopes

## Using with Your Python Script

All solutions are designed to work with your existing `CAN_Send.py` script without modifications. The Simulink models are set up to:

1. Connect to the same Vector CAN channel (when available)
2. Use the same message format with ID 0x123
3. Decode the data using the same algorithm

### Connection Architecture

The data flow process works as follows:

#### UDP Solution (Recommended):
1. **UDP_Send.py (Python)** → Sends UDP messages to localhost:20001
2. **F1_Telemetry_UDP (MATLAB/Simulink)** → Receives messages via UDP
3. **Real-time data flow** → Updates global variables for visualization
4. **Simulink Scopes** → Display live-updating graphs of telemetry data

#### CAN Solution (Requires Vector Hardware):
1. **CAN_Send.py (Python)** → Sends CAN messages to Vector Virtual channel 1
2. **F1_Telemetry_CAN_Live (MATLAB/Simulink)** → Receives messages via Vector API
3. **Real-time data flow** → Updates global variables and timeseries for visualization
4. **Simulink Scopes** → Display live-updating graphs of telemetry data

## Troubleshooting

If you encounter issues:

1. **Model not found**: Make sure to run the appropriate script first
2. **CAN connection error**: Run `Test_CAN_Connection.m` to diagnose CAN hardware issues
3. **Simulink errors**: Check MATLAB console for error messages
4. **No data displayed**: Make sure the data source is running (Python or test script)
5. **Static data only**: The new `F1_Telemetry_CAN_Live.m` solution fixes this with better timeseries updates
6. **Vector errors**: Make sure Vector hardware is connected or CANoe/CANalyzer is running with virtual channels

## Next Steps

After getting the visualization working, you can:

1. Extend the models with additional signal processing
2. Add custom dashboards for better visualization
3. Connect to other data sources like CSV files
4. Export the data for further analysis
