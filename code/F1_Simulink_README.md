# F1 Telemetry Simulink Models

This package contains Simulink models for visualizing F1 telemetry data received via CAN bus.

## Available Models

### 1. F1_Telemetry_CAN_Simulink.slx

This model is created by `Create_F1_Telemetry_CAN_Simulink.m` and requires the Vehicle Network Toolbox with Vector hardware support.

**Features:**
- Receives F1 telemetry data via Vector CAN interface
- Displays Speed, Throttle, Brake, and RPM in real-time
- Logs data to MATLAB workspace

### 2. F1_Telemetry_Universal.slx

This model is created by `Create_F1_Telemetry_Universal.m` and works with all MATLAB versions.

**Features:**
- Works with or without Vehicle Network Toolbox
- Provides a simulation mode when no CAN hardware is detected
- Compatible with older MATLAB versions
- Displays and logs the same telemetry parameters

## How to Use These Models

### Prerequisites
- MATLAB (Any version)
- Simulink (Any version)
- For hardware mode: Vector CAN hardware or compatible CAN interface

### Running the Models

1. Run one of the creation scripts:
   ```matlab
   % For Vector-specific hardware
   run Create_F1_Telemetry_CAN_Simulink.m
   
   % OR for universal compatibility
   run Create_F1_Telemetry_Universal.m
   ```

2. The script will generate and open the corresponding Simulink model

3. Click the "Run" button in the Simulink toolbar to start the simulation

4. View the real-time telemetry data in the scopes and displays

5. Data is automatically logged to the MATLAB workspace in variables:
   - `speed_log`
   - `throttle_log`
   - `brake_log`
   - `rpm_log`

6. To save the logged data after simulation:
   ```matlab
   save('f1_telemetry_log.mat', 'speed_log', 'throttle_log', 'brake_log', 'rpm_log');
   ```

## Model Details

These models mimic the functionality of the `CAN_Receive_Performance.m` script, providing:

- Real-time visualization of F1 telemetry data
- Data logging capabilities
- Compatible with various MATLAB versions and hardware setups

The universal model includes a fallback simulation mode that generates realistic F1 telemetry data when no CAN hardware is available, making it suitable for demonstration and testing purposes.

## Data Structure

Both models process CAN messages with the following byte structure:
- Byte 1: Speed (km/h)
- Byte 2: Throttle (%)
- Byte 3: Brake (%)
- Bytes 5-6: RPM (combined value)
