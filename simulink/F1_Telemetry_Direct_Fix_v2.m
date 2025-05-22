% F1_Telemetry_Direct_Fix_v2.m - Creates a Simulink model that directly decodes
% CAN messages from the receiver without needing a DBC file (Fixed version)

% Define model name - use a more unique name to avoid shadowing
modelName = 'F1_Telemetry_Sim_v2';

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

% Add Vector CAN Configure block
try
    % Try to add Vector CAN Configuration block
    add_block('vnt/CAN/Vector CAN Setup', [modelName, '/CAN_Config'], ...
        'Position', [100, 100, 200, 150], ...
        'P1', 'Virtual 1', ...
        'P2', '1', ...
        'P3', '500000');
    
    % Add Vector CAN Receive block
    add_block('vnt/CAN/Vector CAN Receive', [modelName, '/CAN_Receive'], ...
        'Position', [250, 100, 350, 150], ...
        'P1', '0x123'); % Match the ID in CAN_Send.py
    
    % Connect configuration to receiver
    add_line(modelName, 'CAN_Config/1', 'CAN_Receive/1');
    
    fprintf('✅ Successfully added Vector CAN blocks\n');
    using_can_hardware = true;
catch
    % Fallback to simulated data
    warning('Could not add Vector CAN blocks. Using simulated data instead.');
    fprintf('ℹ️ To use live CAN data, install Vehicle Network Toolbox\n');
    
    % Add simulated CAN data source
    add_block('simulink/Sources/Constant', [modelName, '/CAN_Simulated'], ...
        'Value', 'uint8([120 50 25 3 43 180 0 0])', ...
        'OutDataTypeStr', 'uint8', ...
        'Position', [100, 100, 200, 140], ...
        'BackgroundColor', 'red');
    
    % Add warning display - fix the DisplayLabel issue
    add_block('simulink/Sinks/Display', [modelName, '/WARNING'], ...
        'Position', [100, 50, 300, 80]);
    set_param([modelName, '/WARNING'], 'FontSize', '12');
    set_param([modelName, '/WARNING'], 'BackgroundColor', 'yellow');
    % Don't use DisplayLabel parameter since it doesn't exist
    
    using_can_hardware = false;
end

% Add MATLAB Function block for signal decoding
funcBlockPath = [modelName, '/DecodeCAN'];
add_block('simulink/User-Defined Functions/MATLAB Function', funcBlockPath, ...
    'Position', [450, 100, 550, 200]);

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
    'Position', [650, 50, 750, 80]);
add_block('simulink/Sinks/Display', [modelName, '/Throttle_Display'], ...
    'Position', [650, 100, 750, 130]);
add_block('simulink/Sinks/Display', [modelName, '/Brake_Display'], ...
    'Position', [650, 150, 750, 180]);
add_block('simulink/Sinks/Display', [modelName, '/Gear_Display'], ...
    'Position', [650, 200, 750, 230]);
add_block('simulink/Sinks/Display', [modelName, '/RPM_Display'], ...
    'Position', [650, 250, 750, 280]);

% Add scopes for visualization
add_block('simulink/Sinks/Scope', [modelName, '/Speed_Scope'], ...
    'Position', [800, 50, 850, 100]);
add_block('simulink/Sinks/Scope', [modelName, '/Throttle_Scope'], ...
    'Position', [800, 110, 850, 160]);
add_block('simulink/Sinks/Scope', [modelName, '/Brake_Scope'], ...
    'Position', [800, 170, 850, 220]);
add_block('simulink/Sinks/Scope', [modelName, '/RPM_Scope'], ...
    'Position', [800, 230, 850, 280]);

% Configure scopes with better settings
scope_config = @(path, name, ylim, buffsize) set_param(path, ...
    'NumInputPorts', '1', ...
    'LimitDataPoints', 'off', ...
    'BufferSize', num2str(buffsize), ...
    'YLim', ylim, ...
    'YLimMode', 'manual', ...
    'SaveName', name, ...
    'DataFormat', 'StructureWithTime');

scope_config([modelName, '/Speed_Scope'], 'Speed', '[0, 300]', '10000');
scope_config([modelName, '/Throttle_Scope'], 'Throttle', '[0, 100]', '10000');
scope_config([modelName, '/Brake_Scope'], 'Brake', '[0, 100]', '10000');
scope_config([modelName, '/RPM_Scope'], 'RPM', '[0, 15000]', '10000');

% Connect blocks
if using_can_hardware
    % Connect Vector CAN output to decoder
    add_line(modelName, 'CAN_Receive/1', 'DecodeCAN/1');
else
    % Connect simulated data to decoder
    add_line(modelName, 'CAN_Simulated/1', 'DecodeCAN/1');
    
    % Add a Text annotation block for warning
    add_block('simulink/Annotations/Text', [modelName, '/Warning_Text'], ...
        'Position', [100, 20, 350, 40], ...
        'Text', 'SIMULATED DATA - NOT ACTUAL CAN', ...
        'FontSize', '14', ...
        'FontWeight', 'bold', ...
        'BackgroundColor', 'yellow', ...
        'ForegroundColor', 'red');
end

% Connect function outputs to displays and scopes
add_line(modelName, 'DecodeCAN/1', 'Speed_Display/1');
add_line(modelName, 'DecodeCAN/2', 'Throttle_Display/1');
add_line(modelName, 'DecodeCAN/3', 'Brake_Display/1');
add_line(modelName, 'DecodeCAN/4', 'Gear_Display/1');
add_line(modelName, 'DecodeCAN/5', 'RPM_Display/1');

add_line(modelName, 'DecodeCAN/1', 'Speed_Scope/1');
add_line(modelName, 'DecodeCAN/2', 'Throttle_Scope/1');
add_line(modelName, 'DecodeCAN/3', 'Brake_Scope/1');
add_line(modelName, 'DecodeCAN/5', 'RPM_Scope/1');

% Add To Workspace blocks to save data
add_block('simulink/Sinks/To Workspace', [modelName, '/Speed_Data'], ...
    'Position', [650, 300, 750, 330], ...
    'VariableName', 'speed_data', ...
    'SaveFormat', 'Timeseries');

add_block('simulink/Sinks/To Workspace', [modelName, '/Throttle_Data'], ...
    'Position', [650, 350, 750, 380], ...
    'VariableName', 'throttle_data', ...
    'SaveFormat', 'Timeseries');

add_block('simulink/Sinks/To Workspace', [modelName, '/Brake_Data'], ...
    'Position', [650, 400, 750, 430], ...
    'VariableName', 'brake_data', ...
    'SaveFormat', 'Timeseries');

add_block('simulink/Sinks/To Workspace', [modelName, '/RPM_Data'], ...
    'Position', [650, 450, 750, 480], ...
    'VariableName', 'rpm_data', ...
    'SaveFormat', 'Timeseries');

% Connect signals to workspace
add_line(modelName, 'DecodeCAN/1', 'Speed_Data/1');
add_line(modelName, 'DecodeCAN/2', 'Throttle_Data/1');
add_line(modelName, 'DecodeCAN/3', 'Brake_Data/1');
add_line(modelName, 'DecodeCAN/5', 'RPM_Data/1');

% Add a mux and multi-signal scope for comparing all signals
add_block('simulink/Signal Routing/Mux', [modelName, '/Telemetry_Mux'], ...
    'Position', [900, 350, 920, 450], ...
    'Inputs', '4');

add_block('simulink/Sinks/Scope', [modelName, '/Telemetry_Overview'], ...
    'Position', [950, 350, 1000, 450]);
    
% Configure the overview scope
set_param([modelName, '/Telemetry_Overview'], ...
    'NumInputPorts', '1', ...
    'NumSamples', '10000', ...
    'YMin', '0', ...
    'YMax', '15000', ...
    'SaveName', 'TelemetryOverview', ...
    'DataFormat', 'StructureWithTime');

% Connect signals to mux
add_line(modelName, 'DecodeCAN/1', 'Telemetry_Mux/1');
add_line(modelName, 'DecodeCAN/2', 'Telemetry_Mux/2');
add_line(modelName, 'DecodeCAN/3', 'Telemetry_Mux/3');
add_line(modelName, 'DecodeCAN/5', 'Telemetry_Mux/4');

% Connect mux to overview scope
add_line(modelName, 'Telemetry_Mux/1', 'Telemetry_Overview/1');

% Try to create a simple dashboard - use a safer approach
try
    % Create a subsystem for the dashboard
    dashboardPath = [modelName, '/Dashboard'];
    add_block('built-in/Subsystem', dashboardPath, ...
        'Position', [950, 50, 1150, 300]);
    
    % Add Input ports
    add_block('simulink/Ports & Subsystems/In1', [dashboardPath, '/Speed_In'], ...
        'Position', [50, 50, 80, 70]);
    add_block('simulink/Ports & Subsystems/In1', [dashboardPath, '/Throttle_In'], ...
        'Position', [50, 100, 80, 120], 'Port', '2');
    add_block('simulink/Ports & Subsystems/In1', [dashboardPath, '/Brake_In'], ...
        'Position', [50, 150, 80, 170], 'Port', '3');
    add_block('simulink/Ports & Subsystems/In1', [dashboardPath, '/RPM_In'], ...
        'Position', [50, 200, 80, 220], 'Port', '4');

    % Add display blocks with labels
    add_block('simulink/Sinks/Display', [dashboardPath, '/Speed_Value'], ...
        'Position', [150, 50, 250, 80]);
    add_block('simulink/Sinks/Display', [dashboardPath, '/Throttle_Value'], ...
        'Position', [150, 100, 250, 130]);
    add_block('simulink/Sinks/Display', [dashboardPath, '/Brake_Value'], ...
        'Position', [150, 150, 250, 180]);
    add_block('simulink/Sinks/Display', [dashboardPath, '/RPM_Value'], ...
        'Position', [150, 200, 250, 230]);
    
    % Connect dashboard inputs to displays
    add_line(dashboardPath, 'Speed_In/1', 'Speed_Value/1');
    add_line(dashboardPath, 'Throttle_In/1', 'Throttle_Value/1');
    add_line(dashboardPath, 'Brake_In/1', 'Brake_Value/1');
    add_line(dashboardPath, 'RPM_In/1', 'RPM_Value/1');
    
    % Connect main model outputs to dashboard
    add_line(modelName, 'DecodeCAN/1', 'Dashboard/1');
    add_line(modelName, 'DecodeCAN/2', 'Dashboard/2');
    add_line(modelName, 'DecodeCAN/3', 'Dashboard/3');
    add_line(modelName, 'DecodeCAN/5', 'Dashboard/4');
    
catch dashError
    warning('Could not create dashboard. This is an optional feature: %s', dashError.message);
end

% Add model annotations
set_param(modelName, 'ShowPortLabels', 'on');

% Save the model
save_system(modelName);

% Display completion message with instructions
fprintf('\n✅ %s model has been created successfully!\n\n', modelName);
fprintf('To use the model:\n');
fprintf('1. Start the Python script: python CAN_Send.py\n');
fprintf('2. Run this Simulink model to visualize the data\n');
fprintf('3. The data will be saved in workspace for further analysis\n\n');

% Open the model
open_system(modelName);
