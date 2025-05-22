%% F1 Telemetry Universal Simulink Model Creator
% This script creates a Simulink model that can work across multiple versions of MATLAB
% without requiring specific toolboxes or hardware support

% Clear workspace and command window
clc; clear;

% Create a new Simulink model
modelName = 'F1_Telemetry_Universal';

% Check if model already exists and close it
if bdIsLoaded(modelName)
    close_system(modelName, 0);
end

% Create new model
new_system(modelName);
open_system(modelName);

%% Add blocks for CAN simulation (without requiring Vector hardware)
% We'll use a Constant block to represent each incoming CAN data value
% and Manual Switches to toggle between simulated values and empty signals

% Model configuration
set_param(modelName, 'Solver', 'FixedStep', 'FixedStep', '0.1');

% Parameters for positioning blocks
blockW = 30;  % Block width
blockH = 30;  % Block height
spacing = 70; % Horizontal spacing
vertSpace = 100; % Vertical spacing
margin = 50;  % Margin from left

%% Create reception simulation blocks (Alternative to CAN hardware)
% Add a Clock block to simulate time
add_block('simulink/Sources/Clock', [modelName, '/Clock'], ...
    'Position', [margin, margin, margin+blockW, margin+blockH]);

% Add Manual Switch for data source selection
add_block('simulink/Signal Routing/Manual Switch', [modelName, '/DataSourceSwitch'], ...
    'Position', [margin+spacing, margin, margin+spacing+blockW, margin+blockH]);

% Input port for external data (in case user wants to connect real CAN data)
add_block('simulink/Sources/In1', [modelName, '/External_Input'], ...
    'Position', [margin, margin+vertSpace, margin+blockW, margin+vertSpace+blockH]);

% Create subsystem for simulated data
add_block('simulink/Ports & Subsystems/Subsystem', [modelName, '/SimulatedData'], ...
    'Position', [margin, margin+2*vertSpace, margin+2*blockW, margin+2*vertSpace+2*blockH]);

%% Configure simulated data subsystem
sim_sys = [modelName, '/SimulatedData'];
delete_line(sim_sys, 'In1/1', 'Out1/1');
delete_block([sim_sys, '/In1']);
delete_block([sim_sys, '/Out1']);

% Add Sine Wave for Speed simulation
add_block('simulink/Sources/Sine Wave', [sim_sys, '/Speed_Sine'], ...
    'Position', [50, 50, 80, 80], ...
    'Amplitude', '100', ... % Simulate speed 0-200 km/h
    'Bias', '100', ...
    'Frequency', '0.1', ...
    'SampleTime', '0.1');

% Add Sine Wave for Throttle simulation
add_block('simulink/Sources/Sine Wave', [sim_sys, '/Throttle_Sine'], ...
    'Position', [50, 150, 80, 180], ...
    'Amplitude', '50', ... % Simulate throttle 0-100%
    'Bias', '50', ...
    'Frequency', '0.2', ...
    'SampleTime', '0.1', ...
    'Phase', 'pi/2');

% Add Sine Wave for Brake simulation
add_block('simulink/Sources/Sine Wave', [sim_sys, '/Brake_Sine'], ...
    'Position', [50, 250, 80, 280], ...
    'Amplitude', '50', ... % Simulate brake 0-100%
    'Bias', '50', ...
    'Frequency', '0.2', ...
    'SampleTime', '0.1', ...
    'Phase', 'pi');

% Add Sine Wave for RPM simulation
add_block('simulink/Sources/Sine Wave', [sim_sys, '/RPM_Sine'], ...
    'Position', [50, 350, 80, 380], ...
    'Amplitude', '5000', ... % Simulate RPM range
    'Bias', '7000', ...
    'Frequency', '0.15', ...
    'SampleTime', '0.1');

% Add Mux to combine signals
add_block('simulink/Signal Routing/Mux', [sim_sys, '/Mux'], ...
    'Position', [150, 180, 170, 250], ...
    'Inputs', '4');

% Add output port
add_block('simulink/Ports & Subsystems/Out1', [sim_sys, '/Out1'], ...
    'Position', [200, 205, 220, 225]);

% Connect sine waves to mux
add_line(sim_sys, 'Speed_Sine/1', 'Mux/1');
add_line(sim_sys, 'Throttle_Sine/1', 'Mux/2');
add_line(sim_sys, 'Brake_Sine/1', 'Mux/3');
add_line(sim_sys, 'RPM_Sine/1', 'Mux/4');

% Connect mux to output
add_line(sim_sys, 'Mux/1', 'Out1/1');

%% Create Demux to split signals
add_block('simulink/Signal Routing/Demux', [modelName, '/Demux'], ...
    'Position', [margin+3*spacing, margin+vertSpace, margin+3*spacing+30, margin+vertSpace+120], ...
    'Outputs', '4');

%% Create display scopes that mimic the MATLAB plots
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
% Connect blocks
add_line(modelName, 'SimulatedData/1', 'DataSourceSwitch/1', 'autorouting', 'on');
add_line(modelName, 'External_Input/1', 'DataSourceSwitch/2', 'autorouting', 'on');
add_line(modelName, 'DataSourceSwitch/1', 'Demux/1', 'autorouting', 'on');

% Connect Demux outputs to labels and displays
% Speed
add_line(modelName, 'Demux/1', 'Speed_Label/1', 'autorouting', 'on');
add_line(modelName, 'Speed_Label/1', 'Speed_Log/1', 'autorouting', 'on');
add_line(modelName, 'Speed_Label/1', 'Speed_Scope/1', 'autorouting', 'on');
add_line(modelName, 'Speed_Label/1', 'Speed_Display/1', 'autorouting', 'on');

% Throttle
add_line(modelName, 'Demux/2', 'Throttle_Label/1', 'autorouting', 'on');
add_line(modelName, 'Throttle_Label/1', 'Throttle_Log/1', 'autorouting', 'on');
add_line(modelName, 'Throttle_Label/1', 'Throttle_Scope/1', 'autorouting', 'on');
add_line(modelName, 'Throttle_Label/1', 'Throttle_Display/1', 'autorouting', 'on');

% Brake
add_line(modelName, 'Demux/3', 'Brake_Label/1', 'autorouting', 'on');
add_line(modelName, 'Brake_Label/1', 'Brake_Log/1', 'autorouting', 'on');
add_line(modelName, 'Brake_Label/1', 'Brake_Scope/1', 'autorouting', 'on');
add_line(modelName, 'Brake_Label/1', 'Brake_Display/1', 'autorouting', 'on');

% RPM
add_line(modelName, 'Demux/4', 'RPM_Label/1', 'autorouting', 'on');
add_line(modelName, 'RPM_Label/1', 'RPM_Log/1', 'autorouting', 'on');
add_line(modelName, 'RPM_Label/1', 'RPM_Scope/1', 'autorouting', 'on');
add_line(modelName, 'RPM_Label/1', 'RPM_Display/1', 'autorouting', 'on');

% Connect Clock to scopes for time reference
add_line(modelName, 'Clock/1', 'Speed_Scope/trigger', 'autorouting', 'on');
add_line(modelName, 'Clock/1', 'Throttle_Scope/trigger', 'autorouting', 'on');
add_line(modelName, 'Clock/1', 'Brake_Scope/trigger', 'autorouting', 'on');
add_line(modelName, 'Clock/1', 'RPM_Scope/trigger', 'autorouting', 'on');

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
disp('1. This model works with all MATLAB versions as it does not require special toolboxes');
disp('2. By default, it uses simulated data to mimic F1 telemetry');
disp('3. To use real CAN data:');
disp('   - Connect your CAN device');
disp('   - Create a custom block that outputs the 4 values');
disp('   - Connect it to the External_Input port');
disp('   - Switch the Manual Switch to position 2');
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
