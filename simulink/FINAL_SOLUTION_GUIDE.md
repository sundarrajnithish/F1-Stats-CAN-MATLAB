# F1 Telemetry Visualization Solution Guide

## Introduction

This document provides a comprehensive guide to the F1 telemetry visualization solutions we've created. Our goal was to fix the original Simulink model (F1_Telemetry_Sim.slx) to properly visualize F1 telemetry data from Python over either CAN or UDP.

## Solutions Overview

We've created multiple solutions to address different scenarios:

### 1. UDP-Based Solutions (Recommended)

These solutions don't require Vector CAN hardware:

- `F1_Telemetry_UDP_Fix.m`: Fixed UDP-based solution that works on any MATLAB version
- `UDP_Test_Fix.py`: Test script that sends random F1 telemetry data via UDP
- `UDP_Send.py`: Sends real F1 telemetry data from the fastf1 library over UDP

### 2. CAN-Based Solutions

These solutions require Vector CAN hardware:

- `F1_Telemetry_CAN_Live.m`: Real-time CAN visualization solution
- `Test_CAN_Connection.m`: Diagnostic script to verify CAN hardware
- `F1_Telemetry_CAN_Connector.m`: Connector script for the Simple model

### 3. Standalone Solutions

These solutions work without any external data source:

- `F1_Telemetry_Simple.m`: Minimal model with simulated data
- `F1_Telemetry_Standalone.m`: Self-contained visualization

## How to Use Each Solution

### Option 1: UDP Solution (Recommended)

1. Run `F1_Telemetry_UDP_Fix.m` in MATLAB
2. Run either `UDP_Test_Fix.py` (random data) or `UDP_Send.py` (real F1 data)
3. Watch the Simulink model update with real-time data
4. When finished, run the `stopF1UDP_Fix` command in MATLAB

### Option 2: CAN Solution (Requires Vector CAN Hardware)

1. Run `Test_CAN_Connection.m` to verify your hardware setup
2. Run `F1_Telemetry_CAN_Live.m` in MATLAB
3. Run `CAN_Send.py` in a separate terminal
4. When finished, run the `stopF1CANLive` command in MATLAB

### Option 3: Standalone Solution

1. Run `F1_Telemetry_Standalone.m` in MATLAB
2. Run `Test_F1_Telemetry_Standalone.m` to generate test data
3. Observe the simulation with pre-generated data

## Troubleshooting Common Issues

### 1. "shadowing another name" Error
This happens when a function/script name conflicts with an existing model name. Our fixed version uses unique names to avoid this issue.

### 2. Invalid Display Block Format
Some MATLAB versions don't support custom format strings in Display blocks. Our fixed solutions remove these format options.

### 3. CAN Hardware Missing
If you receive "Unable to perform operation because channel lacks initialization access", your system doesn't have Vector CAN hardware configured. Use our UDP solutions instead.

### 4. UDP Connection Issues
Make sure port 20001 is not blocked by your firewall. Try running both MATLAB and Python scripts as administrator if needed.

## Key Files and Their Purpose

| File | Purpose |
|------|---------|
| F1_Telemetry_UDP_Fix.m | Main UDP solution script |
| UDP_Test_Fix.py | Simple UDP test data generator |
| UDP_Send.py | Real F1 data over UDP |
| F1_Telemetry_CAN_Live.m | CAN-based visualization |
| F1_Telemetry_Simple.m | Simple model with static data |
| stopF1UDP_Fix.m | Cleanup script for UDP solution |

## Technical Details

### Data Format

Both UDP and CAN solutions use the same data format:
- Byte 0: Speed (0-255 km/h)
- Byte 1: Throttle (0-100%)
- Byte 2: Brake (0-100%)
- Byte 3: Gear (1-8)
- Bytes 4-5: RPM (0-65535, MSB first)
- Byte 6: Driver number (1-99)
- Byte 7: Reserved/padding

## Conclusion

The F1_Telemetry_UDP_Fix.m solution is recommended as it works on any system without requiring specialized hardware. It provides real-time visualization of F1 telemetry data with proper error handling and cleanup routines.
