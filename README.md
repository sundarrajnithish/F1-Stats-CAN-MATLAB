# 🏎️ F1 Telemetry Data Acquisition and Analysis System

A comprehensive platform for capturing, transmitting, visualizing, and analyzing Formula 1 telemetry data using Python, CAN bus communication, and MATLAB. This project demonstrates how to:

1. Extract real F1 telemetry data using FastF1 API
2. Transmit data over CAN bus
3. Visualize live telemetry data
4. Log and analyze driver performance metrics

## 🏆 System Overview

This project creates a complete end-to-end pipeline for working with F1 telemetry data:

![Architecture](/images/0.1.png)

- **Data Extraction**: Uses FastF1 Python API to access historical F1 race data
- **CAN Transmission**: Sends telemetry data over Vector virtual CAN bus
- **Real-time Visualization**: Multiple MATLAB scripts for live data display
- **Performance Analysis**: Tools to compare different drivers' telemetry
- **Data Logging**: Records all received data for post-session analysis

### Python CAN Transmission
![Python Code with CAN Transmission](/images/1.png)

## 🛠️ System Components

### 1. Data Transmission (`CAN_Send.py`)

The Python script extracts F1 telemetry from the 2023 Canadian Grand Prix and transmits it over CAN:
- Fetches fastest lap telemetry for 20 F1 drivers
- Packages telemetry data (speed, throttle, brake, gear, RPM) into CAN frames
- Transmits data over a Vector virtual CAN interface at configurable rates
- Includes error handling and progress tracking

### 2. CAN Message Format (`f1.dbc`)

Defines the CAN message structure for telemetry data:
- Message ID: 291 (0x123 in the code)
- Signal definitions:
  - Speed (km/h): 8-bit unsigned (0-255)
  - Throttle (%): 8-bit unsigned (0-100)
  - Brake (%): 8-bit unsigned (0-100)
  - Gear: 8-bit unsigned (0-15)
  - RPM: 16-bit unsigned (0-65535)

### 3. CAN Explorer Visualization
![CAN Explorer Visualization](/images/2.png)

### 4. MATLAB Data Reception (`CAN_Receive.m`)

Basic telemetry receiver that:
- Connects to Vector CAN channel
- Decodes incoming CAN messages
- Presents data in real-time multi-plot display
- Logs all data to timestamped CSV files

### 5. Performance Data Logger (`CAN_Receive_Performance.m`)

Enhanced receiver with:
- Automatic driver detection and separation
- Individual data logging for each driver
- Cleaner, more responsive visualization
- Organized data storage for analysis

### 6. MATLAB Real-time Visualization
![MATLAB Real-time Graphs](/images/3.png)

### 7. Driver Analysis Tool (`CAN_Driver_Analysis.m`)

Powerful comparison tool that:
- Loads any two driver telemetry logs
- Normalizes data by distance for fair comparison
- Generates side-by-side performance visualizations
- Helps identify driving style differences

### 8. Driver Performance Comparison
![Driver Comparison Analysis](/images/4.png)

### 9. Simulink Integration

Includes Simulink models for:
- Real-time data processing (`F1_Telemetry_Sim.slx`)
- Advanced signal filtering and analysis
- Custom visualization options
- Signal export capabilities

## 📋 Requirements

### Python
- Python 3.9+
- `fastf1`: For F1 telemetry data access
- `python-can`: For CAN bus communication

Install with:
```bash
pip install fastf1 python-can
```

### MATLAB
- MATLAB R2021a or newer
- Vehicle Network Toolbox
- Simulink (optional)
- Vector CAN drivers

### Hardware/Software
- Vector CAN interface (hardware or virtual)
- Vector CANalyzer (for CAN Explorer visualization)

## 🚀 Getting Started

1. Clone this repository
```
git clone https://github.com/yourusername/F1-Stats-CAN-MATLAB.git
cd F1-Stats-CAN-MATLAB
```

2. Set up Vector virtual CAN channel (or configure hardware CAN)

3. Run the Python sender script
```
python CAN_Send.py
```

4. In MATLAB, open and run one of the receiver scripts:
```matlab
>> CAN_Receive            % For basic visualization
>> CAN_Receive_Performance % For multi-driver logging
```

5. For driver comparison after data collection:
```matlab
>> CAN_Driver_Analysis    % Interactive driver comparison tool
```

## 📊 Data Processing Workflow

1. **Data Acquisition**: Python extracts telemetry from FastF1
2. **CAN Transmission**: Data is encoded into CAN frames and sent
3. **Real-time Display**: MATLAB receives and visualizes live data
4. **Data Logging**: Telemetry is saved to CSV files by driver
5. **Analysis**: Performance metrics are compared between drivers

## 🔍 Telemetry Signals

The following signals are captured and analyzed:

- **Speed** (km/h): Vehicle speed from 0-255 km/h
- **Throttle** (%): Throttle pedal position (0-100%)
- **Brake** (%): Brake pedal pressure (0-100%)
- **Gear**: Current gear selection (0-15)
- **RPM**: Engine speed in revolutions per minute

## 📈 Use Cases

- Compare driving styles between F1 drivers
- Analyze throttle and brake application techniques
- Study corner entry and exit strategies
- Educational tool for motorsport engineering
- Demonstration of real-time data acquisition systems

## 🔧 Advanced Features

- Modify `f1.dbc` to add custom signals
- Adjust sampling rates in `CAN_Send.py`
- Create custom MATLAB visualizations
- Extend Simulink model for advanced signal processing
- Implement machine learning for driving pattern recognition

## 📞 Contact

For questions or suggestions about this project, please open an issue or contact the repository owner.

---

**Note**: This project is intended for educational and demonstration purposes. Formula 1 data accessed via FastF1 is subject to Formula 1's terms and conditions.
