% F1_Telemetry_Simple.m
% Creates a minimal Simulink model for F1 telemetry that works on any MATLAB version

% Define a simple model name
modelName = 'F1_Telemetry_Simple';

% Close existing model if open
if bdIsLoaded(modelName)
    close_system(modelName, 0);
end

% Create new model
new_system(modelName);
open_system(modelName);

% Configure minimal model settings
set_param(modelName, 'SolverType', 'Fixed-step');
set_param(modelName, 'FixedStep', '0.1');
set_param(modelName, 'StopTime', '30');

% Create a constant block with simulated CAN data
add_block('simulink/Sources/Constant', [modelName '/CAN_Data'], ...
    'Value', 'uint8([120 50 25 3 43 180 0 0])', ...
    'OutDataTypeStr', 'uint8', ...
    'Position', [100, 100, 200, 140], ...
    'BackgroundColor', 'yellow');

% Create MATLAB Function block for data decoding (simpler design)
add_block('simulink/User-Defined Functions/MATLAB Function', [modelName '/Decoder'], ...
    'Position', [300, 100, 400, 140]);

% Set MATLAB Function content
decoder_path = getfullname([modelName '/Decoder']);
open_system(decoder_path);
pause(1);

rt = sfroot;
chart = rt.find('-isa', 'Stateflow.EMChart', 'Path', [modelName '/Decoder']);
if ~isempty(chart)
    chart.Script = [
        'function [speed, throttle, brake, gear, rpm] = Decoder(u)', newline, ...
        '    speed = double(u(1));', newline, ...
        '    throttle = double(u(2));', newline, ...
        '    brake = double(u(3));', newline, ...
        '    gear = double(u(4));', newline, ...
        '    rpm = double(bitshift(u(5), 8) + u(6));', newline, ...
        'end'
    ];
else
    error('Could not find or configure the MATLAB Function block');
end

% Add display blocks
add_block('simulink/Sinks/Display', [modelName '/Speed'], ...
    'Position', [500, 50, 600, 70]);
add_block('simulink/Sinks/Display', [modelName '/Throttle'], ...
    'Position', [500, 100, 600, 120]);
add_block('simulink/Sinks/Display', [modelName '/Brake'], ...
    'Position', [500, 150, 600, 170]);
add_block('simulink/Sinks/Display', [modelName '/Gear'], ...
    'Position', [500, 200, 600, 220]);
add_block('simulink/Sinks/Display', [modelName '/RPM'], ...
    'Position', [500, 250, 600, 270]);

% Add basic scopes (with minimal configuration)
add_block('simulink/Sinks/Scope', [modelName '/Speed_Scope'], ...
    'Position', [650, 50, 700, 100]);
add_block('simulink/Sinks/Scope', [modelName '/Throttle_Scope'], ...
    'Position', [650, 120, 700, 170]);
add_block('simulink/Sinks/Scope', [modelName '/Brake_Scope'], ...
    'Position', [650, 190, 700, 240]);
add_block('simulink/Sinks/Scope', [modelName '/RPM_Scope'], ...
    'Position', [650, 260, 700, 310]);

% Connect blocks
add_line(modelName, 'CAN_Data/1', 'Decoder/1');

% Connect outputs to displays and scopes
add_line(modelName, 'Decoder/1', 'Speed/1');
add_line(modelName, 'Decoder/2', 'Throttle/1');
add_line(modelName, 'Decoder/3', 'Brake/1');
add_line(modelName, 'Decoder/4', 'Gear/1');
add_line(modelName, 'Decoder/5', 'RPM/1');

% Connect to scopes
add_line(modelName, 'Decoder/1', 'Speed_Scope/1');
add_line(modelName, 'Decoder/2', 'Throttle_Scope/1');
add_line(modelName, 'Decoder/3', 'Brake_Scope/1');
add_line(modelName, 'Decoder/5', 'RPM_Scope/1');

% Add From Workspace block for testing with real data
add_block('simulink/Sources/From Workspace', [modelName '/From_Workspace'], ...
    'Position', [100, 200, 200, 240], ...
    'VariableName', 'f1_data');

% Add a manual switch to select between constant and workspace data
add_block('simulink/Signal Routing/Manual Switch', [modelName '/Data_Source_Switch'], ...
    'Position', [250, 150, 270, 170]);

% Connect both data sources to the switch
add_line(modelName, 'CAN_Data/1', 'Data_Source_Switch/1');
add_line(modelName, 'From_Workspace/1', 'Data_Source_Switch/2');

% Connect switch to decoder
delete_line(modelName, 'CAN_Data/1', 'Decoder/1');  % Remove direct connection
add_line(modelName, 'Data_Source_Switch/1', 'Decoder/1');

% Add To Workspace block to save results
add_block('simulink/Sinks/To Workspace', [modelName '/Results'], ...
    'Position', [500, 300, 600, 340], ...
    'VariableName', 'telemetry_results');

% Create a Bus Creator to collect all signals
add_block('simulink/Signal Routing/Bus Creator', [modelName '/Signal_Bus'], ...
    'Position', [450, 280, 460, 360], ...
    'Inputs', '5');

% Connect signals to bus
for i = 1:5
    add_line(modelName, ['Decoder/' num2str(i)], ['Signal_Bus/' num2str(i)]);
end

% Connect bus to workspace
add_line(modelName, 'Signal_Bus/1', 'Results/1');

% Generate sample data
t = (0:0.1:30)';
num_samples = length(t);

% Create simple patterns
speed = round(120 + 50 * sin(t/3));
throttle = round(50 + 40 * sin(t/2));
brake = round(max(0, min(100, 50 - 40 * sin(t/2))));
gear = round(4 + 3 * sin(t/4));
rpm = round(8000 + 4000 * sin(t/3));

% Build CAN message format
data = zeros(num_samples, 8);
for i = 1:num_samples
    data(i,1) = uint8(min(255, max(0, speed(i))));
    data(i,2) = uint8(min(100, max(0, throttle(i))));
    data(i,3) = uint8(min(100, max(0, brake(i))));
    data(i,4) = uint8(min(8, max(1, gear(i))));
    
    rpm_val = min(15000, max(0, rpm(i)));
    data(i,5) = uint8(floor(rpm_val / 256));
    data(i,6) = uint8(mod(rpm_val, 256));
    data(i,7) = 0;
    data(i,8) = 0;
end

% Create timeseries
f1_data = timeseries(data, t);
assignin('base', 'f1_data', f1_data);

% Save model
save_system(modelName);

% Display instructions
fprintf('\n=== F1 Telemetry Simple Model Created ===\n\n');
fprintf('This is a minimal version that should work with any MATLAB version.\n');
fprintf('To use with simulated data:\n');
fprintf('1. Set the manual switch to use the upper input (constant data)\n');
fprintf('2. Run the model\n\n');
fprintf('To use with sample telemetry data:\n');
fprintf('1. Set the manual switch to use the lower input (from workspace)\n');
fprintf('2. Run the model\n\n');
fprintf('To use with your CAN_Send.py script:\n');
fprintf('1. You will need to replace the constant block with CAN hardware blocks\n');
fprintf('   or modify the script to load data from a file\n\n');

% Open the model
open_system(modelName);
