% F1 Telemetry Simulink Model (No Toolbox Required)
% This script creates a simple model that uses hardcoded data instead of requiring
% the Vehicle Network Toolbox or other CAN blocks

clc; clear;

% Create a new Simulink model
modelName = 'F1_Telemetry_Simple';

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

%% Create data source blocks

% Data source selector (File or Simulated)
add_block('simulink/Signal Routing/Manual Switch', [modelName, '/DataSourceSwitch'], ...
    'Position', [margin+spacing, margin+2*vertSpace, margin+spacing+blockW, margin+2*vertSpace+blockH]);

% Add From File option
add_block('simulink/Sources/From File', [modelName, '/FromFile'], ...
    'Position', [margin, margin+vertSpace, margin+blockW, margin+vertSpace+blockH], ...
    'FileName', 'driver_1_telemetry.csv', ...
    'SampleTime', '0.1');

% Add Simulated option using repeating sequences
add_block('simulink/Sources/Repeating Sequence', [modelName, '/Speed_Seq'], ...
    'Position', [margin, margin+3*vertSpace, margin+blockW, margin+3*vertSpace+blockH], ...
    'OutValues', '[0, 100, 200, 150, 50]', ...
    'TimeValues', '[0, 2, 4, 6, 8]', ...
    'LookUpMeth', 'Use Input Below, Interpolate');

add_block('simulink/Sources/Repeating Sequence', [modelName, '/Throttle_Seq'], ...
    'Position', [margin, margin+4*vertSpace, margin+blockW, margin+4*vertSpace+blockH], ...
    'OutValues', '[0, 100, 80, 0, 20]', ...
    'TimeValues', '[0, 2, 4, 6, 8]', ...
    'LookUpMeth', 'Use Input Below, Interpolate');

add_block('simulink/Sources/Repeating Sequence', [modelName, '/Brake_Seq'], ...
    'Position', [margin, margin+5*vertSpace, margin+blockW, margin+5*vertSpace+blockH], ...
    'OutValues', '[0, 0, 20, 100, 50]', ...
    'TimeValues', '[0, 2, 4, 6, 8]', ...
    'LookUpMeth', 'Use Input Below, Interpolate');

add_block('simulink/Sources/Repeating Sequence', [modelName, '/RPM_Seq'], ...
    'Position', [margin, margin+6*vertSpace, margin+blockW, margin+6*vertSpace+blockH], ...
    'OutValues', '[5000, 12000, 10000, 6000, 8000]', ...
    'TimeValues', '[0, 2, 4, 6, 8]', ...
    'LookUpMeth', 'Use Input Below, Interpolate');

% Add Clock as time source for sequences
add_block('simulink/Sources/Clock', [modelName, '/Clock'], ...
    'Position', [margin-spacing, margin+4.5*vertSpace, margin-spacing+blockW, margin+4.5*vertSpace+blockH]);

% Mux for simulated signals
add_block('simulink/Signal Routing/Mux', [modelName, '/Sim_Mux'], ...
    'Position', [margin+spacing, margin+4.5*vertSpace, margin+spacing+20, margin+4.5*vertSpace+60], ...
    'Inputs', '4');

%% Create Demux to split signals
add_block('simulink/Signal Routing/Demux', [modelName, '/Demux'], ...
    'Position', [margin+2*spacing, margin+2*vertSpace, margin+2*spacing+30, margin+2*vertSpace+120], ...
    'Outputs', '4');

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
    'Position', [margin+3*spacing, margin, margin+3*spacing+blockW, margin+blockH]);
set_param([modelName, '/Speed_Label'], 'AttributesFormatString', 'Speed (km/h)');

% Throttle label
add_block('simulink/Signal Attributes/Signal Conversion', [modelName, '/Throttle_Label'], ...
    'Position', [margin+3*spacing, margin+vertSpace, margin+3*spacing+blockW, margin+vertSpace+blockH]);
set_param([modelName, '/Throttle_Label'], 'AttributesFormatString', 'Throttle (%)');

% Brake label
add_block('simulink/Signal Attributes/Signal Conversion', [modelName, '/Brake_Label'], ...
    'Position', [margin+3*spacing, margin+2*vertSpace, margin+3*spacing+blockW, margin+2*vertSpace+blockH]);
set_param([modelName, '/Brake_Label'], 'AttributesFormatString', 'Brake (%)');

% RPM label
add_block('simulink/Signal Attributes/Signal Conversion', [modelName, '/RPM_Label'], ...
    'Position', [margin+3*spacing, margin+3*vertSpace, margin+3*spacing+blockW, margin+3*vertSpace+blockH]);
set_param([modelName, '/RPM_Label'], 'AttributesFormatString', 'RPM');

%% Create all connections
% Connect clock to all sequences
add_line(modelName, 'Clock/1', 'Speed_Seq/1', 'autorouting', 'on');
add_line(modelName, 'Clock/1', 'Throttle_Seq/1', 'autorouting', 'on');
add_line(modelName, 'Clock/1', 'Brake_Seq/1', 'autorouting', 'on');
add_line(modelName, 'Clock/1', 'RPM_Seq/1', 'autorouting', 'on');

% Connect sequences to mux
add_line(modelName, 'Speed_Seq/1', 'Sim_Mux/1', 'autorouting', 'on');
add_line(modelName, 'Throttle_Seq/1', 'Sim_Mux/2', 'autorouting', 'on');
add_line(modelName, 'Brake_Seq/1', 'Sim_Mux/3', 'autorouting', 'on');
add_line(modelName, 'RPM_Seq/1', 'Sim_Mux/4', 'autorouting', 'on');

% Connect data source options to switch
add_line(modelName, 'Sim_Mux/1', 'DataSourceSwitch/1', 'autorouting', 'on');
add_line(modelName, 'FromFile/1', 'DataSourceSwitch/2', 'autorouting', 'on');

% Connect switch to demux
add_line(modelName, 'DataSourceSwitch/1', 'Demux/1', 'autorouting', 'on');

% Connect Demux outputs to labels
add_line(modelName, 'Demux/1', 'Speed_Label/1', 'autorouting', 'on');
add_line(modelName, 'Demux/2', 'Throttle_Label/1', 'autorouting', 'on');
add_line(modelName, 'Demux/3', 'Brake_Label/1', 'autorouting', 'on');
add_line(modelName, 'Demux/4', 'RPM_Label/1', 'autorouting', 'on');

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
disp('1. This model works on ALL MATLAB versions - no special toolboxes required');
disp('2. Two data sources available:');
disp('   - Generated pattern using Repeating Sequence blocks (default)');
disp('   - CSV file data (set Manual Switch to position 2)');
disp('3. To use CSV file:');
disp('   - Make sure driver_1_telemetry.csv is in your MATLAB path');
disp('   - Or double-click the From File block to change the file path');
disp('4. The model displays Speed, Throttle, Brake and RPM from F1 telemetry');
disp('5. Data is logged to the MATLAB workspace');
disp('6. To save the logged data after simulation:');
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
