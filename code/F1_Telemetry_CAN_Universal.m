% F1 Telemetry Universal Simulink CAN Interface
% This script creates a Simulink model with CAN support that attempts to use
% whatever CAN blocks are available in your MATLAB installation

% Clear workspace and command window
clc; clear;

% Create a new Simulink model
modelName = 'F1_Telemetry_CAN_Universal';

% Check if model already exists and close it
if bdIsLoaded(modelName)
    close_system(modelName, 0);
end

% Create new model
new_system(modelName);
open_system(modelName);

% Model configuration
set_param(modelName, 'Solver', 'FixedStep');
set_param(modelName, 'FixedStep', '0.1');

% Parameters for positioning blocks
blockW = 30;  % Block width
blockH = 30;  % Block height
spacing = 70; % Horizontal spacing
vertSpace = 100; % Vertical spacing
margin = 50;  % Margin from left

%% Determine which CAN toolbox is available
canMethod = 'none';

% Check for Vehicle Network Toolbox with Vector support
if exist('vnt3/CAN Receive', 'file') == 4
    canMethod = 'vector';
% Check for Vehicle Network Toolbox with SLCAN
elseif exist('slcan/CAN Receive', 'file') == 4
    canMethod = 'slcan';
% Check for Instrument Control Toolbox
elseif exist('instrument/Serial Receive', 'file') == 4
    canMethod = 'serialcan';
end

disp(['CAN method detected: ', canMethod]);

%% Create CAN Receive block based on available toolbox
switch canMethod
    case 'vector'
        add_block('vnt3/CAN Receive', [modelName, '/CAN_Receive'], ...
            'Position', [margin, margin, margin+blockW*2, margin+blockH*2], ...
            'HardwareID', 'Vector', ...
            'DeviceChannel', '2', ...
            'BitRate', '500000', ...
            'SampleTime', '0.1');
        
    case 'slcan'
        add_block('slcan/CAN Receive', [modelName, '/CAN_Receive'], ...
            'Position', [margin, margin, margin+blockW*2, margin+blockH*2], ...
            'CANChannel', '1', ...
            'BitRate', '500000', ...
            'SampleTime', '0.1');
        
    case 'serialcan'
        % For Instrument Control Toolbox, we need to create a custom subsystem
        add_block('simulink/Ports & Subsystems/Subsystem', [modelName, '/CAN_Receive'], ...
            'Position', [margin, margin, margin+blockW*2, margin+blockH*2]);
        
        % Configure the subsystem
        sys = [modelName, '/CAN_Receive'];
        delete_line(sys, 'In1/1', 'Out1/1');
        delete_block([sys, '/In1']);
        
        % Add Serial Receive block
        add_block('instrument/Serial Receive', [sys, '/Serial_Receive'], ...
            'Position', [50, 50, 150, 100]);
        
        % Add out port
        add_block('simulink/Ports & Subsystems/Out1', [sys, '/Out1'], ...
            'Position', [200, 50, 220, 70]);
        
        % Connect blocks
        add_line(sys, 'Serial_Receive/1', 'Out1/1');
        
    otherwise
        % Fallback to simulated data
        add_block('simulink/Sources/Sine Wave', [modelName, '/CAN_Receive'], ...
            'Position', [margin, margin, margin+blockW*2, margin+blockH*2], ...
            'Amplitude', '127.5', ...
            'Bias', '127.5', ...
            'Frequency', '0.1', ...
            'SampleTime', '0.1', ...
            'OutDataTypeStr', 'uint8');
        
        % Add warning annotation
        add_block('simulink/Annotations/Note', [modelName, '/Warning'], ...
            'Position', [margin, margin+2*vertSpace, margin+200, margin+2*vertSpace+50]);
        set_param([modelName, '/Warning'], 'Text', 'No CAN toolbox found. Using simulated data.');
end

%% Create parser blocks
% This subsystem will parse the CAN message bytes into usable signals
add_block('simulink/Ports & Subsystems/Subsystem', [modelName, '/Parser'], ...
    'Position', [margin+2*spacing, margin, margin+2*spacing+2*blockW, margin+2*blockH]);

% Configure parser subsystem
parser = [modelName, '/Parser'];
delete_line(parser, 'In1/1', 'Out1/1');
delete_block([parser, '/Out1']);

% Add selector blocks to extract data from CAN message
% Speed (byte 1)
add_block('simulink/Signal Routing/Selector', [parser, '/Speed_Selector'], ...
    'Position', [150, 50, 200, 80], ...
    'IndexMode', 'Zero-based', ...
    'Indices', '0');

% Throttle (byte 2)
add_block('simulink/Signal Routing/Selector', [parser, '/Throttle_Selector'], ...
    'Position', [150, 150, 200, 180], ...
    'IndexMode', 'Zero-based', ...
    'Indices', '1');

% Brake (byte 3)
add_block('simulink/Signal Routing/Selector', [parser, '/Brake_Selector'], ...
    'Position', [150, 250, 200, 280], ...
    'IndexMode', 'Zero-based', ...
    'Indices', '2');

% RPM (bytes 5 & 6)
add_block('simulink/Signal Routing/Selector', [parser, '/RPM_High_Selector'], ...
    'Position', [150, 350, 200, 380], ...
    'IndexMode', 'Zero-based', ...
    'Indices', '4');

add_block('simulink/Signal Routing/Selector', [parser, '/RPM_Low_Selector'], ...
    'Position', [150, 450, 200, 480], ...
    'IndexMode', 'Zero-based', ...
    'Indices', '5');

% Bitshift RPM high byte and add low byte
add_block('simulink/Math Operations/Shift Arithmetic', [parser, '/RPM_Shift'], ...
    'Position', [250, 350, 300, 380], ...
    'ShiftDirection', 'Left', ...
    'ShiftValue', '8');

add_block('simulink/Math Operations/Add', [parser, '/RPM_Add'], ...
    'Position', [350, 400, 400, 430]);

% Add Output ports
add_block('simulink/Ports & Subsystems/Out1', [parser, '/Speed_Out'], ...
    'Position', [250, 50, 270, 70]);
add_block('simulink/Ports & Subsystems/Out2', [parser, '/Throttle_Out'], ...
    'Position', [250, 150, 270, 170]);
add_block('simulink/Ports & Subsystems/Out3', [parser, '/Brake_Out'], ...
    'Position', [250, 250, 270, 270]);
add_block('simulink/Ports & Subsystems/Out4', [parser, '/RPM_Out'], ...
    'Position', [450, 400, 470, 420]);

% Connect selector blocks to outputs
add_line(parser, 'In1/1', 'Speed_Selector/1');
add_line(parser, 'In1/1', 'Throttle_Selector/1');
add_line(parser, 'In1/1', 'Brake_Selector/1');
add_line(parser, 'In1/1', 'RPM_High_Selector/1');
add_line(parser, 'In1/1', 'RPM_Low_Selector/1');

add_line(parser, 'Speed_Selector/1', 'Speed_Out/1');
add_line(parser, 'Throttle_Selector/1', 'Throttle_Out/1');
add_line(parser, 'Brake_Selector/1', 'Brake_Out/1');

% RPM calculation
add_line(parser, 'RPM_High_Selector/1', 'RPM_Shift/1');
add_line(parser, 'RPM_Shift/1', 'RPM_Add/1');
add_line(parser, 'RPM_Low_Selector/1', 'RPM_Add/2');
add_line(parser, 'RPM_Add/1', 'RPM_Out/1');

%% Create Data Type Conversion blocks
% Speed conversion
add_block('simulink/Signal Attributes/Data Type Conversion', [modelName, '/Speed_Convert'], ...
    'Position', [margin+3*spacing, margin, margin+3*spacing+blockW, margin+blockH], ...
    'OutDataTypeStr', 'double');

% Throttle conversion
add_block('simulink/Signal Attributes/Data Type Conversion', [modelName, '/Throttle_Convert'], ...
    'Position', [margin+3*spacing, margin+vertSpace, margin+3*spacing+blockW, margin+vertSpace+blockH], ...
    'OutDataTypeStr', 'double');

% Brake conversion
add_block('simulink/Signal Attributes/Data Type Conversion', [modelName, '/Brake_Convert'], ...
    'Position', [margin+3*spacing, margin+2*vertSpace, margin+3*spacing+blockW, margin+2*vertSpace+blockH], ...
    'OutDataTypeStr', 'double');

% RPM conversion
add_block('simulink/Signal Attributes/Data Type Conversion', [modelName, '/RPM_Convert'], ...
    'Position', [margin+3*spacing, margin+3*vertSpace, margin+3*spacing+blockW, margin+3*vertSpace+blockH], ...
    'OutDataTypeStr', 'double');

%% Create display scopes
% Speed scope
add_block('simulink/Sinks/Scope', [modelName, '/Speed_Scope'], ...
    'Position', [margin+5*spacing, margin, margin+5*spacing+blockW, margin+blockH], ...
    'OpenAtSimulationStart', 'on');
set_param([modelName, '/Speed_Scope'], 'BackgroundColor', 'blue');

% Throttle scope  
add_block('simulink/Sinks/Scope', [modelName, '/Throttle_Scope'], ...
    'Position', [margin+5*spacing, margin+vertSpace, margin+5*spacing+blockW, margin+vertSpace+blockH], ...
    'OpenAtSimulationStart', 'on');
set_param([modelName, '/Throttle_Scope'], 'BackgroundColor', 'green');

% Brake scope
add_block('simulink/Sinks/Scope', [modelName, '/Brake_Scope'], ...
    'Position', [margin+5*spacing, margin+2*vertSpace, margin+5*spacing+blockW, margin+2*vertSpace+blockH], ...
    'OpenAtSimulationStart', 'on');
set_param([modelName, '/Brake_Scope'], 'BackgroundColor', 'red');

% RPM scope
add_block('simulink/Sinks/Scope', [modelName, '/RPM_Scope'], ...
    'Position', [margin+5*spacing, margin+3*vertSpace, margin+5*spacing+blockW, margin+3*vertSpace+blockH], ...
    'OpenAtSimulationStart', 'on');
set_param([modelName, '/RPM_Scope'], 'BackgroundColor', 'magenta');

%% Add Data Logging using To Workspace blocks
% Speed log
add_block('simulink/Sinks/To Workspace', [modelName, '/Speed_Log'], ...
    'Position', [margin+4*spacing, margin, margin+4*spacing+blockW, margin+blockH], ...
    'VariableName', 'speed_log', ...
    'SaveFormat', 'Array');

% Throttle log
add_block('simulink/Sinks/To Workspace', [modelName, '/Throttle_Log'], ...
    'Position', [margin+4*spacing, margin+vertSpace, margin+4*spacing+blockW, margin+vertSpace+blockH], ...
    'VariableName', 'throttle_log', ...
    'SaveFormat', 'Array');

% Brake log
add_block('simulink/Sinks/To Workspace', [modelName, '/Brake_Log'], ...
    'Position', [margin+4*spacing, margin+2*vertSpace, margin+4*spacing+blockW, margin+2*vertSpace+blockH], ...
    'VariableName', 'brake_log', ...
    'SaveFormat', 'Array');

% RPM log
add_block('simulink/Sinks/To Workspace', [modelName, '/RPM_Log'], ...
    'Position', [margin+4*spacing, margin+3*vertSpace, margin+4*spacing+blockW, margin+3*vertSpace+blockH], ...
    'VariableName', 'rpm_log', ...
    'SaveFormat', 'Array');

%% Add Display blocks for current values
% Speed display
add_block('simulink/Sinks/Display', [modelName, '/Speed_Display'], ...
    'Position', [margin+6*spacing, margin, margin+6*spacing+blockW+10, margin+blockH], ...
    'Format', 'short');

% Throttle display
add_block('simulink/Sinks/Display', [modelName, '/Throttle_Display'], ...
    'Position', [margin+6*spacing, margin+vertSpace, margin+6*spacing+blockW+10, margin+vertSpace+blockH], ...
    'Format', 'short');

% Brake display
add_block('simulink/Sinks/Display', [modelName, '/Brake_Display'], ...
    'Position', [margin+6*spacing, margin+2*vertSpace, margin+6*spacing+blockW+10, margin+2*vertSpace+blockH], ...
    'Format', 'short');

% RPM display
add_block('simulink/Sinks/Display', [modelName, '/RPM_Display'], ...
    'Position', [margin+6*spacing, margin+3*vertSpace, margin+6*spacing+blockW+10, margin+3*vertSpace+blockH], ...
    'Format', 'short');

%% Add Labels to identify data
% Speed label
add_block('simulink/Signal Attributes/Signal Conversion', [modelName, '/Speed_Label'], ...
    'Position', [margin+2*spacing, margin, margin+2*spacing+blockW, margin+blockH]);
set_param([modelName, '/Speed_Label'], 'AttributesFormatString', 'Speed (km/h)');

% Throttle label
add_block('simulink/Signal Attributes/Signal Conversion', [modelName, '/Throttle_Label'], ...
    'Position', [margin+2*spacing, margin+vertSpace, margin+2*spacing+blockW, margin+vertSpace+blockH]);
set_param([modelName, '/Throttle_Label'], 'AttributesFormatString', 'Throttle (%)');

% Brake label
add_block('simulink/Signal Attributes/Signal Conversion', [modelName, '/Brake_Label'], ...
    'Position', [margin+2*spacing, margin+2*vertSpace, margin+2*spacing+blockW, margin+2*vertSpace+blockH]);
set_param([modelName, '/Brake_Label'], 'AttributesFormatString', 'Brake (%)');

% RPM label
add_block('simulink/Signal Attributes/Signal Conversion', [modelName, '/RPM_Label'], ...
    'Position', [margin+2*spacing, margin+3*vertSpace, margin+2*spacing+blockW, margin+3*vertSpace+blockH]);
set_param([modelName, '/RPM_Label'], 'AttributesFormatString', 'RPM');

%% Create all connections
% Connect CAN Receive to Parser
add_line(modelName, 'CAN_Receive/1', 'Parser/1', 'autorouting', 'on');

% Connect Parser outputs to converters
add_line(modelName, 'Parser/1', 'Speed_Convert/1', 'autorouting', 'on');
add_line(modelName, 'Parser/2', 'Throttle_Convert/1', 'autorouting', 'on');
add_line(modelName, 'Parser/3', 'Brake_Convert/1', 'autorouting', 'on');
add_line(modelName, 'Parser/4', 'RPM_Convert/1', 'autorouting', 'on');

% Connect type converters to labels
add_line(modelName, 'Speed_Convert/1', 'Speed_Label/1', 'autorouting', 'on');
add_line(modelName, 'Throttle_Convert/1', 'Throttle_Label/1', 'autorouting', 'on');
add_line(modelName, 'Brake_Convert/1', 'Brake_Label/1', 'autorouting', 'on');
add_line(modelName, 'RPM_Convert/1', 'RPM_Label/1', 'autorouting', 'on');

% Connect labels to displays and scopes
% Speed
add_line(modelName, 'Speed_Label/1', 'Speed_Log/1', 'autorouting', 'on');
add_line(modelName, 'Speed_Label/1', 'Speed_Scope/1', 'autorouting', 'on');
add_line(modelName, 'Speed_Label/1', 'Speed_Display/1', 'autorouting', 'on');

% Throttle
add_line(modelName, 'Throttle_Label/1', 'Throttle_Log/1', 'autorouting', 'on');
add_line(modelName, 'Throttle_Label/1', 'Throttle_Scope/1', 'autorouting', 'on');
add_line(modelName, 'Throttle_Label/1', 'Throttle_Display/1', 'autorouting', 'on');

% Brake
add_line(modelName, 'Brake_Label/1', 'Brake_Log/1', 'autorouting', 'on');
add_line(modelName, 'Brake_Label/1', 'Brake_Scope/1', 'autorouting', 'on');
add_line(modelName, 'Brake_Label/1', 'Brake_Display/1', 'autorouting', 'on');

% RPM
add_line(modelName, 'RPM_Label/1', 'RPM_Log/1', 'autorouting', 'on');
add_line(modelName, 'RPM_Label/1', 'RPM_Scope/1', 'autorouting', 'on');
add_line(modelName, 'RPM_Label/1', 'RPM_Display/1', 'autorouting', 'on');

%% Configure scopes
configureScope([modelName, '/Speed_Scope'], 'Speed (km/h)', [0 200]);
configureScope([modelName, '/Throttle_Scope'], 'Throttle (%)', [0 100]);
configureScope([modelName, '/Brake_Scope'], 'Brake (%)', [0 100]);
configureScope([modelName, '/RPM_Scope'], 'RPM', [0 15000]);

%% Save model
save_system(modelName);
disp(['Successfully created model: ' modelName]);

% Provide instructions
disp('===== INSTRUCTIONS =====');
disp('1. This model automatically detects available CAN blocks in your MATLAB installation');
disp(['2. CAN Method detected: ' canMethod]);
disp('3. The model will display Speed, Throttle, Brake and RPM from F1 telemetry');
disp('4. Data is logged to the MATLAB workspace');
disp('5. To save the logged data after simulation:');
disp('   >> save(''f1_telemetry_log.mat'', ''speed_log'', ''throttle_log'', ''brake_log'', ''rpm_log'');');
disp('=======================');

function configureScope(scopePath, title, yLimits)
    % Configure scope settings
    scope_handle = get_param(scopePath, 'ScopeConfiguration');
    scope_handle.OpenAtSimulationStart = 1;
    scope_handle.NumInputPorts = 1;
    scope_handle.YLimMode = 'manual';
    scope_handle.YMin = yLimits(1);
    scope_handle.YMax = yLimits(2);
    scope_handle.TimeSpan = 10;
    scope_handle.Title = title;
    scope_handle.Grid = 'on';
end
