% CAN_Simulink_Fix.m - Creates a Simulink model that properly receives CAN data
% and visualizes F1 telemetry signals

% Define model name
modelName = 'F1_Telemetry_Sim';

% Close and delete model if it already exists
if bdIsLoaded(modelName)
    bdclose(modelName);
end

% Create and open new model
new_system(modelName);
open_system(modelName);

% Set model parameters
set_param(modelName, 'SolverType', 'Fixed-step');
set_param(modelName, 'FixedStep', '0.01');
set_param(modelName, 'StopTime', 'inf'); % Run indefinitely

% Define path to DBC file
dbcPath = fullfile(pwd, 'f1.dbc');
% Check if DBC file exists
if ~exist(dbcPath, 'file')
    error('DBC file not found at: %s', dbcPath);
end

% Add CAN Receive block from Vehicle Network Toolbox
try
    % Create subsystem for CAN reception
    canSubsys = [modelName, '/CAN_Reception'];
    add_block('built-in/Subsystem', canSubsys, 'Position', [100, 100, 300, 300]);
    
    % Add CAN Configuration block
    add_block('canlib/CAN Configuration', [canSubsys, '/CAN_Config'], ...
        'Position', [50, 50, 150, 100], ...
        'HardwareID', 'Vector', ...
        'Channel', '0', ...
        'ApplicationName', 'CANalyzer', ...
        'BitRate', '500000');
    
    % Add CAN Receive block that uses DBC file
    add_block('canlib/CAN Receive', [canSubsys, '/CAN_Receive'], ...
        'Position', [50, 150, 150, 250], ...
        'DBCFile', dbcPath, ...
        'MessageID', '291', ...
        'IncludeHeaders', 'on');
    
    % Add output port for the CAN message data
    add_block('built-in/Outport', [canSubsys, '/CAN_Data'], ...
        'Position', [200, 200, 230, 220]);
    
    % Connect blocks in subsystem
    add_line(canSubsys, 'CAN_Config/1', 'CAN_Receive/1');
    add_line(canSubsys, 'CAN_Receive/1', 'CAN_Data/1');
catch canError
    warning('Error adding CAN blocks. Check if Vehicle Network Toolbox is installed: %s', canError.message);
    
    % Fallback to a simulated CAN data block
    add_block('simulink/Sources/Constant', [modelName, '/CAN_Simulated'], ...
        'Value', 'uint8([120 50 25 3 43 180 0 0])', ...
        'OutDataTypeStr', 'uint8', ...
        'Position', [100, 100, 200, 140], ...
        'BackgroundColor', 'red');
    
    % Rename and notification
    add_block('simulink/Sinks/Display', [modelName, '/WARNING'], ...
        'Position', [100, 30, 200, 70]);
    add_line(modelName, 'CAN_Simulated/1', 'WARNING/1');
    set_param([modelName, '/WARNING'], 'DisplayLabel', '"SIMULATED DATA - NOT ACTUAL CAN"');
end

% Add Bus Selector to extract specific signals
add_block('simulink/Signal Routing/Bus Selector', [modelName, '/Bus_Selector'], ...
    'Position', [350, 150, 450, 250]);

% Add Signal Conversion block
add_block('simulink/Signal Attributes/Data Type Conversion', [modelName, '/Convert_to_Double'], ...
    'Position', [500, 150, 600, 250]);

% Add MATLAB Function block for signal decoding
funcBlockPath = [modelName, '/DecodeCAN'];
add_block('simulink/User-Defined Functions/MATLAB Function', funcBlockPath, ...
    'Position', [650, 150, 750, 250]);

% Set the function code inside MATLAB Function block
open_system(funcBlockPath);
pause(1); % Wait for Simulink to register the block

rt = sfroot;
model = rt.find('-isa', 'Simulink.BlockDiagram', 'Name', modelName);
funcBlk = model.find('-isa','Stateflow.EMChart','Path', funcBlockPath);

code = [
    'function [speed, throttle, brake, gear, rpm] = DecodeCAN(data)', newline, ...
    '    % Decode the CAN data payload into individual signals', newline, ...
    '    speed = double(data(1));     % km/h', newline, ...
    '    throttle = double(data(2));  % 0-100%', newline, ...
    '    brake = double(data(3));     % 0-100%', newline, ...
    '    gear = double(data(4));      % 0-15', newline, ...
    '    rpm = double(bitshift(data(5), 8) + data(6));  % 0-65535 RPM', newline, ...
    'end'
];
funcBlk.Script = code;

% Add display blocks for each output
add_block('simulink/Sinks/Display', [modelName, '/Speed_Display'], ...
    'Position', [850, 50, 950, 80]);
add_block('simulink/Sinks/Display', [modelName, '/Throttle_Display'], ...
    'Position', [850, 100, 950, 130]);
add_block('simulink/Sinks/Display', [modelName, '/Brake_Display'], ...
    'Position', [850, 150, 950, 180]);
add_block('simulink/Sinks/Display', [modelName, '/Gear_Display'], ...
    'Position', [850, 200, 950, 230]);
add_block('simulink/Sinks/Display', [modelName, '/RPM_Display'], ...
    'Position', [850, 250, 950, 280]);

% Add scopes for visualization
add_block('simulink/Sinks/Scope', [modelName, '/Speed_Scope'], ...
    'Position', [850, 300, 880, 330]);
add_block('simulink/Sinks/Scope', [modelName, '/Throttle_Scope'], ...
    'Position', [900, 300, 930, 330]);
add_block('simulink/Sinks/Scope', [modelName, '/Brake_Scope'], ...
    'Position', [950, 300, 980, 330]);
add_block('simulink/Sinks/Scope', [modelName, '/RPM_Scope'], ...
    'Position', [1000, 300, 1030, 330]);

% Configure scopes
set_param([modelName, '/Speed_Scope'], 'YLim', '[0, 350]');
set_param([modelName, '/Throttle_Scope'], 'YLim', '[0, 100]');
set_param([modelName, '/Brake_Scope'], 'YLim', '[0, 100]');
set_param([modelName, '/RPM_Scope'], 'YLim', '[0, 15000]');

% Connect blocks based on whether we have CAN blocks or simulated data
try
    % Connect CAN reception to decoder
    add_line(modelName, 'CAN_Reception/1', 'DecodeCAN/1');
catch
    % Connect simulated data to decoder
    add_line(modelName, 'CAN_Simulated/1', 'DecodeCAN/1');
end

% Connect decoder outputs to displays and scopes
outputNames = {'speed', 'throttle', 'brake', 'gear', 'rpm'};
scopeNames = {'Speed_Scope', 'Throttle_Scope', 'Brake_Scope', '', 'RPM_Scope'};

for i = 1:length(outputNames)
    % Connect to display
    add_line(modelName, ['DecodeCAN/' num2str(i)], [outputNames{i} '_Display/1']);
    
    % Connect to scope if applicable
    if ~isempty(scopeNames{i})
        add_line(modelName, ['DecodeCAN/' num2str(i)], [scopeNames{i} '/1']);
    end
end

% Create a Dashboard using Simulink Dashboard
try
    % Add dashboard blocks
    dash_pos = [1100, 100, 1500, 500];
    dashSubsys = [modelName, '/Dashboard'];
    add_block('built-in/Subsystem', dashSubsys, 'Position', dash_pos);
    
    % Add gauges for each signal
    add_block('dspdemos/Dashboard/Gauge', [dashSubsys, '/Speed_Gauge'], ...
        'Position', [50, 50, 150, 150], ...
        'Min', '0', 'Max', '350');
    
    add_block('dspdemos/Dashboard/Gauge', [dashSubsys, '/Throttle_Gauge'], ...
        'Position', [50, 200, 150, 300], ...
        'Min', '0', 'Max', '100');
    
    add_block('dspdemos/Dashboard/Gauge', [dashSubsys, '/Brake_Gauge'], ...
        'Position', [200, 50, 300, 150], ...
        'Min', '0', 'Max', '100');
    
    add_block('dspdemos/Dashboard/Gauge', [dashSubsys, '/RPM_Gauge'], ...
        'Position', [200, 200, 300, 300], ...
        'Min', '0', 'Max', '15000');
    
    % Add inports for the dashboard
    add_block('built-in/Inport', [dashSubsys, '/Speed_In'], ...
        'Position', [10, 100, 30, 120], 'Port', '1');
    add_block('built-in/Inport', [dashSubsys, '/Throttle_In'], ...
        'Position', [10, 250, 30, 270], 'Port', '2');
    add_block('built-in/Inport', [dashSubsys, '/Brake_In'], ...
        'Position', [10, 350, 30, 370], 'Port', '3');
    add_block('built-in/Inport', [dashSubsys, '/RPM_In'], ...
        'Position', [10, 450, 30, 470], 'Port', '4');
    
    % Connect inports to gauges
    add_line(dashSubsys, 'Speed_In/1', 'Speed_Gauge/1');
    add_line(dashSubsys, 'Throttle_In/1', 'Throttle_Gauge/1');
    add_line(dashSubsys, 'Brake_In/1', 'Brake_Gauge/1');
    add_line(dashSubsys, 'RPM_In/1', 'RPM_Gauge/1');
    
    % Connect signals to dashboard
    add_line(modelName, 'DecodeCAN/1', 'Dashboard/1');
    add_line(modelName, 'DecodeCAN/2', 'Dashboard/2');
    add_line(modelName, 'DecodeCAN/3', 'Dashboard/3');
    add_line(modelName, 'DecodeCAN/5', 'Dashboard/4');
catch dashError
    warning('Could not create dashboard components. This is optional functionality: %s', dashError.message);
end

% Add To Workspace blocks to save signals for later analysis
add_block('simulink/Sinks/To Workspace', [modelName, '/Save_Speed'], ...
    'Position', [850, 350, 950, 370], ...
    'VariableName', 'speed_data', ...
    'SaveFormat', 'Timeseries');

add_block('simulink/Sinks/To Workspace', [modelName, '/Save_Throttle'], ...
    'Position', [850, 400, 950, 420], ...
    'VariableName', 'throttle_data', ...
    'SaveFormat', 'Timeseries');

add_block('simulink/Sinks/To Workspace', [modelName, '/Save_Brake'], ...
    'Position', [850, 450, 950, 470], ...
    'VariableName', 'brake_data', ...
    'SaveFormat', 'Timeseries');

add_block('simulink/Sinks/To Workspace', [modelName, '/Save_RPM'], ...
    'Position', [850, 500, 950, 520], ...
    'VariableName', 'rpm_data', ...
    'SaveFormat', 'Timeseries');

% Connect signals to workspace blocks
add_line(modelName, 'DecodeCAN/1', 'Save_Speed/1');
add_line(modelName, 'DecodeCAN/2', 'Save_Throttle/1');
add_line(modelName, 'DecodeCAN/3', 'Save_Brake/1');
add_line(modelName, 'DecodeCAN/5', 'Save_RPM/1');

% Add informative annotations
add_annotation = @(text, pos) add_block('built-in/Note', [modelName, '/Note_', num2str(randi(1000))], ...
    'Position', pos, 'Text', text);

add_annotation('F1 Telemetry Visualization', [100, 30, 400, 50]);
add_annotation('Receives CAN signals from F1 telemetry data', [100, 60, 400, 80]);
add_annotation('Decoded signals are displayed and plotted in real-time', [450, 30, 800, 50]);

% Save the model
save_system(modelName);

% Show a success message
fprintf('\n✅ F1_Telemetry_Sim model created successfully!\n');
fprintf('→ The model is configured to receive data from Vector CAN channel 0.\n');
fprintf('→ Use the CAN_Send.py script to stream telemetry data.\n');
fprintf('→ Click "Run" in Simulink to start visualization.\n\n');

% Open the model
open_system(modelName);
