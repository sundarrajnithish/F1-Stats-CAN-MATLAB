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
- Universal model with direct data simulation (`F1_Telemetry_Universal.slx`)

During my final semester project, I created two distinct Simulink approaches:

1. **CAN-based Model** (`F1_Telemetry_Sim.slx`): Interfaces directly with Vector hardware for actual CAN bus communication. Ideal for situations where hardware is available and maximum realism is required.

2. **Universal Model** (`F1_Telemetry_Universal.slx`): Completely self-contained simulation that requires no additional hardware or toolboxes. This was my solution to the compatibility challenges that emerged when sharing the project with classmates who had different MATLAB configurations.

#### Universal Simulink Model
![Universal Simulink Model](/images/5.png)

The `F1_Telemetry_Universal` model represents a significant advancement in my approach to F1 telemetry visualization. During my master's thesis work, I encountered numerous challenges with MATLAB version compatibility when implementing the CAN-based telemetry system. Many of my peers were unable to run the original model due to specific Vector hardware dependencies and toolbox requirements that varied across MATLAB versions and academic licenses.

After spending weeks troubleshooting these compatibility issues, I developed this universal solution as a practical workaround that would function consistently across all environments. The key innovation was moving away from external hardware dependencies entirely.

Rather than relying on external CAN bus communications which required specific hardware and toolboxes, this model simulates the telemetry data directly within Simulink using fundamental blocks available in all MATLAB installations. My approach offers several advantages:

- **Universal Compatibility**: Works with any MATLAB version (from R2018b through R2023a tested) without requiring specialized toolboxes
- **Zero Hardware Dependencies**: Eliminates the need for Vector CAN hardware or drivers that many students don't have access to
- **Consistent Performance**: Delivers identical visualization experience across all systems, making it ideal for teaching environments
- **Simplified Deployment**: Single-file solution that works immediately without complicated setup procedures
- **Realistic Data Patterns**: Despite being simulated, maintains the essential characteristics of actual F1 telemetry

The model architecture is elegantly simple yet effective. At its core, I implemented a system of sine wave generators with carefully calibrated parameters (frequency, amplitude, bias, and phase) to produce realistic F1 telemetry signals for speed, throttle, brake, and RPM. These signals are mathematically designed to mimic actual race data patterns while maintaining clean, predictable outputs for reliable analysis.

To enhance usability, I added a manual switch that allows seamless toggling between:
1. **Simulated Data Mode**: Using the internal sine wave generators for completely standalone operation
2. **External Data Mode**: For users who do have access to the necessary hardware to integrate real CAN data

The visualization components include custom-configured color-coded scopes (blue for speed, green for throttle, red for brake, and magenta for RPM) with appropriate scaling, numeric displays showing current values, and automatic workspace variable logging for post-simulation analysis. All data is synchronized using a common time base to maintain proper relationships between the telemetry channels.

For those interested in the technical implementation, the model:
- Uses a fixed-step solver with 0.1s step size for consistent data generation
- Employs signal converters with descriptive labels for improved readability
- Includes automatic data logging to workspace variables for further analysis
- Features carefully tuned scope configurations with appropriate Y-axis limits for each telemetry channel

The visualization components include color-coded scopes, numeric displays, and automatic workspace logging—all functioning identically to our hardware-dependent implementation but without the compatibility headaches.

Throughout my testing across multiple MATLAB versions in our university lab, I found this approach to be remarkably robust. Even when students had limited MATLAB licenses or older versions installed on their laptops, the universal model performed consistently. This adaptability proved especially valuable during remote learning periods when access to university hardware was limited.

The design philosophy behind this model reflects what I learned during my master's program about creating truly portable engineering solutions. While the CAN-based approach offers excellent real-world integration, the universal model demonstrates how clever use of fundamental building blocks can overcome practical limitations without sacrificing core functionality. This balance between theoretical correctness and practical usability is something I strived to achieve throughout my academic projects.

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
For CAN-based implementation:
- MATLAB R2021a or newer recommended for full functionality
- Vehicle Network Toolbox (required for CAN communication)
- Simulink (required for visualization models)
- Vector CAN drivers (for hardware interface)

For Universal model:
- **Any MATLAB version with basic Simulink** (tested on versions from R2018b through R2023a)
- **No additional toolboxes required**
- **No hardware dependencies**
- **No specialized drivers needed**

### Hardware/Software (CAN-based implementation only)
- Vector CAN interface (hardware or virtual)
- Vector CANalyzer (for CAN Explorer visualization)

This dual approach reflects an important lesson from my master's program: always design with deployment constraints in mind. The universal model emerged from conversations with peers who couldn't run my original implementation due to licensing or hardware limitations. Rather than requiring everyone to acquire specific hardware, I developed a solution that preserved the educational value while removing practical barriers to adoption.

## 🚀 Getting Started

### Option 1: Universal Approach (Recommended for most users)

1. Clone this repository
```
git clone https://github.com/yourusername/F1-Stats-CAN-MATLAB.git
cd F1-Stats-CAN-MATLAB
```

2. In MATLAB, run the Universal model generator script:
```matlab
>> F1_Telemetry_Universal    % Creates and opens a compatible Simulink model
```

3. Run the simulation by clicking the "Run" button in Simulink
   - Data will automatically be logged to your workspace
   - Live visualization will display in the model scopes

### Option 2: CAN-based Implementation (For users with Vector hardware)

1. Clone this repository as above

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

During my thesis testing, I found that the Universal approach was sufficient for most educational purposes, while the CAN-based implementation offered a more authentic experience for those specifically interested in automotive communication protocols.

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

### Universal Model Customization
- Modify sine wave parameters in `F1_Telemetry_Universal.m` to alter signal characteristics
- Extend the model with additional variables (like gear, lateral G-force, etc.)
- Customize scope configurations for different visualization needs
- Add signal processing blocks for data filtering or analysis
- Integrate with external visualization tools via To Workspace blocks

### CAN Implementation Extensions
- Modify `f1.dbc` to add custom signals
- Adjust sampling rates in `CAN_Send.py`
- Create custom MATLAB visualizations
- Extend Simulink model for advanced signal processing
- Implement machine learning for driving pattern recognition

One interesting extension I explored during my thesis was creating a hybrid approach that allowed the Universal model to record simulated data to CAN format files, enabling compatibility with the analysis tools designed for the hardware-based approach. This allowed for consistent analysis workflows regardless of data source.

## 📞 Contact

For questions or suggestions about this project, please open an issue or contact the repository owner.

---

## 🎓 Technical Lessons Learned

Throughout the development of this project for my master's thesis, I gained valuable insights about engineering system design that extend well beyond just the technical implementation:

1. **Accessibility vs. Authenticity**: The tension between creating an authentic system (CAN bus) and making it widely accessible (Universal model) taught me to consider diverse user constraints early in the design process.

2. **Graceful Degradation**: The universal model demonstrates how systems can be designed to provide core functionality even without specialized components. This principle of graceful degradation is critical in robust engineering systems.

3. **Testing Across Environments**: Validating the system across different MATLAB versions revealed subtle compatibility issues that weren't apparent in the development environment, highlighting the importance of broad testing strategies.

4. **Documentation for Different Users**: Creating documentation that serves both technical experts (who want to use the CAN implementation) and novices (who just need a working visualization) required careful organization of information.

5. **Simulation Fidelity**: Designing a simulation that captured the essential characteristics of real telemetry data without exact replication taught me to identify which aspects of a signal are truly relevant for the intended use case.

These lessons significantly influenced my approach to system design and will continue to guide my professional work in engineering.

**Note**: This project is intended for educational and demonstration purposes. Formula 1 data accessed via FastF1 is subject to Formula 1's terms and conditions.
