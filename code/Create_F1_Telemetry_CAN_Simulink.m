% Create_F1_Telemetry_CAN_Simulink.m
% This script creates a Simulink model that receives F1 telemetry data via CAN
% and displays it in scopes, mimicking the functionality in CAN_Receive_Performance.m

% Close any open system
close_system('F1_Telemetry_CAN_Simulink', 0);

try
    % Create a new Simulink model
    sys = 'F1_Telemetry_CAN_Simulink';
    new_system(sys);
    open_system(sys);
    
    % Set model parameters for compatibility across MATLAB versions
    set_param(sys, 'SaveFormat', 'Structure');
    set_param(sys, 'SolverType', 'Fixed-step');
    set_param(sys, 'Solver', 'FixedStepDiscrete');
    set_param(sys, 'FixedStep', '0.1');
    set_param(sys, 'StopTime', 'inf');
    
    % Add CAN Receive block
    add_block('vnt3/CAN Receive', [sys '/CAN Receive'], ...
        'Position', [100, 100, 200, 150], ...
        'ChannelName', 'Vector Virtual 1', ...
        'SampleTime', '0.01');
    
    % Add Bus Selector to extract CAN message data
    add_block('simulink/Signal Routing/Bus Selector', [sys '/Bus Selector'], ...
        'Position', [250, 100, 350, 150]);
    
    % Connect CAN Receive to Bus Selector
    add_line(sys, 'CAN Receive/1', 'Bus Selector/1');
    
    % Configure Bus Selector to select 'Data' field
    set_param([sys '/Bus Selector'], 'OutputSignals', 'Data');
    
    % Add a Demux block to separate the data bytes
    add_block('simulink/Signal Routing/Demux', [sys '/Demux'], ...
        'Position', [400, 100, 450, 150], ...
        'Outputs', '8');  % CAN message can have up to 8 bytes
    
    % Connect Bus Selector to Demux
    add_line(sys, 'Bus Selector/1', 'Demux/1');
    
    % Add Data Type Conversion blocks for each parameter
    % Speed (Byte 1)
    add_block('simulink/Signal Attributes/Data Type Conversion', [sys '/Speed_Conv'], ...
        'Position', [500, 50, 600, 70]);
    add_line(sys, 'Demux/1', 'Speed_Conv/1');
    
    % Throttle (Byte 2)
    add_block('simulink/Signal Attributes/Data Type Conversion', [sys '/Throttle_Conv'], ...
        'Position', [500, 100, 600, 120]);
    add_line(sys, 'Demux/2', 'Throttle_Conv/1');
    
    % Brake (Byte 3)
    add_block('simulink/Signal Attributes/Data Type Conversion', [sys '/Brake_Conv'], ...
        'Position', [500, 150, 600, 170]);
    add_line(sys, 'Demux/3', 'Brake_Conv/1');
    
    % RPM calculation (Bytes 5 and 6)
    % Byte 5
    add_block('simulink/Signal Attributes/Data Type Conversion', [sys '/RPM_High_Conv'], ...
        'Position', [500, 200, 600, 220]);
    add_line(sys, 'Demux/5', 'RPM_High_Conv/1');
    
    % Byte 6
    add_block('simulink/Signal Attributes/Data Type Conversion', [sys '/RPM_Low_Conv'], ...
        'Position', [500, 250, 600, 270]);
    add_line(sys, 'Demux/6', 'RPM_Low_Conv/1');
    
    % Shift operation for RPM high byte
    add_block('simulink/Math Operations/Shift Arithmetic', [sys '/Shift_Left'], ...
        'Position', [650, 200, 700, 220], ...
        'NumberOfBitsToShift', '8', ...
        'Direction', 'Left');
    add_line(sys, 'RPM_High_Conv/1', 'Shift_Left/1');
    
    % Add blocks to combine RPM bytes
    add_block('simulink/Math Operations/Add', [sys '/RPM_Combine'], ...
        'Position', [750, 220, 800, 240]);
    add_line(sys, 'Shift_Left/1', 'RPM_Combine/1');
    add_line(sys, 'RPM_Low_Conv/1', 'RPM_Combine/2');
    
    % Add scopes for each parameter with appropriate settings
    % Speed Scope
    add_block('simulink/Sinks/Scope', [sys '/Speed_Scope'], ...
        'Position', [700, 50, 750, 70], ...
        'BackgroundColor', 'blue');
    set_param([sys '/Speed_Scope'], 'YLimMode', 'on', 'YMin', '0', 'YMax', '350');
    set_param([sys '/Speed_Scope'], 'OpenAtSimulationStart', 'on');
    add_block('simulink/Signal Attributes/Signal Conversion', [sys '/Speed_Label'], ...
        'Position', [650, 50, 670, 70]);
    add_line(sys, 'Speed_Conv/1', 'Speed_Label/1');
    add_line(sys, 'Speed_Label/1', 'Speed_Scope/1');
    
    % Throttle Scope
    add_block('simulink/Sinks/Scope', [sys '/Throttle_Scope'], ...
        'Position', [700, 100, 750, 120], ...
        'BackgroundColor', 'green');
    set_param([sys '/Throttle_Scope'], 'YLimMode', 'on', 'YMin', '0', 'YMax', '100');
    set_param([sys '/Throttle_Scope'], 'OpenAtSimulationStart', 'on');
    add_block('simulink/Signal Attributes/Signal Conversion', [sys '/Throttle_Label'], ...
        'Position', [650, 100, 670, 120]);
    add_line(sys, 'Throttle_Conv/1', 'Throttle_Label/1');
    add_line(sys, 'Throttle_Label/1', 'Throttle_Scope/1');
    
    % Brake Scope
    add_block('simulink/Sinks/Scope', [sys '/Brake_Scope'], ...
        'Position', [700, 150, 750, 170], ...
        'BackgroundColor', 'red');
    set_param([sys '/Brake_Scope'], 'YLimMode', 'on', 'YMin', '0', 'YMax', '100');
    set_param([sys '/Brake_Scope'], 'OpenAtSimulationStart', 'on');
    add_block('simulink/Signal Attributes/Signal Conversion', [sys '/Brake_Label'], ...
        'Position', [650, 150, 670, 170]);
    add_line(sys, 'Brake_Conv/1', 'Brake_Label/1');
    add_line(sys, 'Brake_Label/1', 'Brake_Scope/1');
    
    % RPM Scope
    add_block('simulink/Sinks/Scope', [sys '/RPM_Scope'], ...
        'Position', [850, 220, 900, 240], ...
        'BackgroundColor', 'magenta');
    set_param([sys '/RPM_Scope'], 'YLimMode', 'on', 'YMin', '0', 'YMax', '15000');
    set_param([sys '/RPM_Scope'], 'OpenAtSimulationStart', 'on');
    add_block('simulink/Signal Attributes/Signal Conversion', [sys '/RPM_Label'], ...
        'Position', [810, 220, 830, 240]);
    add_line(sys, 'RPM_Combine/1', 'RPM_Label/1');
    add_line(sys, 'RPM_Label/1', 'RPM_Scope/1');
    
    % Add To Workspace blocks to log data
    % Speed
    add_block('simulink/Sinks/To Workspace', [sys '/Speed_Log'], ...
        'Position', [700, 20, 750, 40], ...
        'VariableName', 'speed_log', ...
        'SaveFormat', 'Timeseries');
    add_line(sys, 'Speed_Conv/1', 'Speed_Log/1');
    
    % Throttle
    add_block('simulink/Sinks/To Workspace', [sys '/Throttle_Log'], ...
        'Position', [700, 70, 750, 90], ...
        'VariableName', 'throttle_log', ...
        'SaveFormat', 'Timeseries');
    add_line(sys, 'Throttle_Conv/1', 'Throttle_Log/1');
    
    % Brake
    add_block('simulink/Sinks/To Workspace', [sys '/Brake_Log'], ...
        'Position', [700, 120, 750, 140], ...
        'VariableName', 'brake_log', ...
        'SaveFormat', 'Timeseries');
    add_line(sys, 'Brake_Conv/1', 'Brake_Log/1');
    
    % RPM
    add_block('simulink/Sinks/To Workspace', [sys '/RPM_Log'], ...
        'Position', [850, 190, 900, 210], ...
        'VariableName', 'rpm_log', ...
        'SaveFormat', 'Timeseries');
    add_line(sys, 'RPM_Combine/1', 'RPM_Log/1');
    
    % Add Display blocks for real-time values
    % Speed
    add_block('simulink/Sinks/Display', [sys '/Speed_Display'], ...
        'Position', [750, 50, 820, 80], ...
        'Format', 'short', ...
        'Decimation', '1');
    add_line(sys, 'Speed_Label/1', 'Speed_Display/1');
    
    % Throttle
    add_block('simulink/Sinks/Display', [sys '/Throttle_Display'], ...
        'Position', [750, 100, 820, 130], ...
        'Format', 'short', ...
        'Decimation', '1');
    add_line(sys, 'Throttle_Label/1', 'Throttle_Display/1');
    
    % Brake
    add_block('simulink/Sinks/Display', [sys '/Brake_Display'], ...
        'Position', [750, 150, 820, 180], ...
        'Format', 'short', ...
        'Decimation', '1');
    add_line(sys, 'Brake_Label/1', 'Brake_Display/1');
    
    % RPM
    add_block('simulink/Sinks/Display', [sys '/RPM_Display'], ...
        'Position', [900, 220, 970, 250], ...
        'Format', 'short', ...
        'Decimation', '1');
    add_line(sys, 'RPM_Label/1', 'RPM_Display/1');
    
    % Add manual trigger to stop model after inactivity
    add_block('simulink/Sources/Clock', [sys '/Clock'], ...
        'Position', [100, 300, 120, 320]);
    
    % Add data labels using annotation
    add_annotation(sys, 'textarrow', [0.6, 0.1, 0.65, 0.1], 'String', 'Speed (km/h)');
    add_annotation(sys, 'textarrow', [0.6, 0.2, 0.65, 0.2], 'String', 'Throttle (%)');
    add_annotation(sys, 'textarrow', [0.6, 0.3, 0.65, 0.3], 'String', 'Brake (%)');
    add_annotation(sys, 'textarrow', [0.8, 0.45, 0.85, 0.45], 'String', 'RPM');
    
    % Add a title to the model
    add_annotation(sys, 'text', [0.4, 0.05, 0.6, 0.1], 'String', 'F1 Telemetry CAN Receiver');
    
    % Save the model
    save_system(sys);
    disp('Simulink model created successfully: F1_Telemetry_CAN_Simulink.slx');
    disp('To run the model, open it and click the Run button.');
    
catch ME
    disp('Error creating Simulink model:');
    disp(ME.message);
    
    % Provide workaround instructions if specific blocks are missing
    if contains(ME.message, 'vnt3/CAN Receive')
        disp('Note: The Vector CAN blocks might not be available in your MATLAB installation.');
        disp('Alternative: You can use the Vehicle Network Toolbox with "slcan/CAN Receive" block instead.');
        disp('If that''s also not available, consider using the "Instrument Control Toolbox" with a Serial Receive block.');
    end
end

% Instructions for users
disp(' ');
disp('===== INSTRUCTIONS =====');
disp('1. This model requires either:');
disp('   - Vehicle Network Toolbox with Vector hardware support');
disp('   - Vehicle Network Toolbox with CAN adapters');
disp('2. Before running, ensure your CAN hardware is connected');
disp('3. The model will display Speed, Throttle, Brake and RPM from F1 telemetry');
disp('4. Data is also logged to the MATLAB workspace');
disp('5. To save the logged data after simulation:');
disp('   >> save(''f1_telemetry_log.mat'', ''speed_log'', ''throttle_log'', ''brake_log'', ''rpm_log'');');
disp('======================');
