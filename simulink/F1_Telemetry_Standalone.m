% F1_Telemetry_Standalone.m
% Creates a standalone Simulink model for F1 telemetry visualization
% This version doesn't rely on CAN hardware or Vector toolbox

% Define a new model name to avoid conflicts
modelName = 'F1_Telemetry_Standalone';

% Close existing model if open
if bdIsLoaded(modelName)
    close_system(modelName, 0);
end

% Create new model
new_system(modelName);
open_system(modelName);

% Configure model settings
set_param(modelName, 'SolverType', 'Fixed-step');
set_param(modelName, 'FixedStep', '0.1');
set_param(modelName, 'StopTime', '30');

% Create a simulation data source
add_block('simulink/Sources/From Workspace', [modelName '/Telemetry_Data'], ...
    'Position', [100, 100, 250, 140], ...
    'VariableName', 'f1_data');

% Create MATLAB Function block for data decoding
add_block('simulink/User-Defined Functions/MATLAB Function', [modelName '/Decoder'], ...
    'Position', [300, 100, 400, 140]);

% Set MATLAB Function content
decoder_path = getfullname([modelName '/Decoder']);
open_system(decoder_path);
pause(1);

rt = sfroot;
chart = rt.find('-isa', 'Stateflow.EMChart', 'Path', [modelName '/Decoder']);
chart.Script = [
    'function [speed, throttle, brake, gear, rpm] = Decoder(u)', newline, ...
    '% Decode CAN message format used in CAN_Send.py', newline, ...
    '    speed = double(u(1));', newline, ...
    '    throttle = double(u(2));', newline, ...
    '    brake = double(u(3));', newline, ...
    '    gear = double(u(4));', newline, ...
    '    rpm = double(bitshift(u(5), 8) + u(6));', newline, ...
    'end'
];

% Add display blocks
positions = {
    [500, 50, 600, 70],   % Speed
    [500, 100, 600, 120], % Throttle
    [500, 150, 600, 170], % Brake
    [500, 200, 600, 220], % Gear
    [500, 250, 600, 270]  % RPM
};

labels = {'Speed', 'Throttle', 'Brake', 'Gear', 'RPM'};

% Create display blocks
for i = 1:5
    add_block('simulink/Sinks/Display', [modelName '/' labels{i}], ...
        'Position', positions{i});
end

% Add scopes
scope_positions = {
    [700, 50, 750, 100],   % Speed
    [700, 120, 750, 170],  % Throttle
    [700, 190, 750, 240],  % Brake
    [700, 260, 750, 310]   % RPM
};

scope_names = {'Speed_Scope', 'Throttle_Scope', 'Brake_Scope', 'RPM_Scope'};
scope_limits = {'[0 255]', '[0 100]', '[0 100]', '[0 15000]'};

% Create scopes
for i = 1:4
    if i ~= 3  % Skip gear scope
        add_block('simulink/Sinks/Scope', [modelName '/' scope_names{i}], ...
            'Position', scope_positions{i}, ...
            'OpenAtSimulationStart', 'on');
        
        % Configure scope
        set_param([modelName '/' scope_names{i}], ...
            'YLim', scope_limits{i}, ...
            'YLimMode', 'manual');
    end
end

% Connect blocks
add_line(modelName, 'Telemetry_Data/1', 'Decoder/1');

% Connect outputs to displays and scopes
for i = 1:5
    add_line(modelName, ['Decoder/' num2str(i)], [labels{i} '/1']);
    
    % Connect to scopes (except for gear)
    if i ~= 4
        scope_idx = (i > 4) ? i-1 : i;  % Adjust for missing gear scope
        add_line(modelName, ['Decoder/' num2str(i)], [scope_names{scope_idx} '/1']);
    end
end

% Create a dashboard subsystem
dash = [modelName '/Dashboard'];
add_block('built-in/Subsystem', dash, 'Position', [900, 100, 1000, 200]);

% Add inports to dashboard
for i = 1:4
    idx = (i == 4) ? 5 : i; % Adjust for RPM being 5th output
    label = labels{idx};
    add_block('simulink/Ports & Subsystems/In1', [dash '/' label '_In'], ...
        'Position', [50, 50+70*(i-1), 70, 70+70*(i-1)], ...
        'Port', num2str(i));
    
    % Add display in dashboard
    add_block('simulink/Sinks/Display', [dash '/' label '_Value'], ...
        'Position', [120, 50+70*(i-1), 220, 70+70*(i-1)]);
    
    % Connect dashboard components
    add_line(dash, [label '_In/1'], [label '_Value/1']);
end

% Connect dashboard inputs from main model
add_line(modelName, 'Decoder/1', 'Dashboard/1'); % Speed
add_line(modelName, 'Decoder/2', 'Dashboard/2'); % Throttle
add_line(modelName, 'Decoder/3', 'Dashboard/3'); % Brake
add_line(modelName, 'Decoder/5', 'Dashboard/4'); % RPM

% Add To Workspace blocks to save data
add_block('simulink/Sinks/To Workspace', [modelName '/SaveData'], ...
    'Position', [500, 300, 600, 340], ...
    'VariableName', 'sim_results', ...
    'SaveFormat', 'Structure With Time');

% Create a Bus Creator to collect all signals
add_block('simulink/Signal Routing/Bus Creator', [modelName '/SignalBus'], ...
    'Position', [450, 280, 460, 360], ...
    'Inputs', '5', ...
    'DisplayOption', 'bar');

% Connect signals to bus
for i = 1:5
    add_line(modelName, ['Decoder/' num2str(i)], ['SignalBus/' num2str(i)]);
end

% Connect bus to workspace
add_line(modelName, 'SignalBus/1', 'SaveData/1');

% Add annotations
add_annotation = @(text, pos) add_block('built-in/Note', [modelName, '/Note_', num2str(randi(1000))], ...
    'Position', pos, 'Text', text);

add_annotation('F1 Telemetry Visualization - Standalone Model', [250, 20, 650, 40]);
add_annotation('Run Test_F1_Telemetry_Standalone.m to generate data', [250, 50, 650, 70]);

% Save the model
save_system(modelName);

% Generate test data
fprintf('\n==== F1 Telemetry Standalone Model Created ====\n\n');
fprintf('To test this model:\n');
fprintf('1. Run Test_F1_Telemetry_Standalone.m to generate data\n');
fprintf('2. Then run this model to visualize the data\n\n');

% Create basic test data in workspace
t = (0:0.1:30)';
num_samples = length(t);

% Basic sinusoidal patterns for test
speed = round(150 + 70 * sin(t/3));
throttle = round(50 + 40 * sin(t/2));
brake = round(50 + 40 * sin(t/2 + pi)); % Opposite of throttle
gear = round(4 + 3 * sin(t/4));
rpm = round(8000 + 4000 * sin(t/3));

% Build data array like CAN message
data = zeros(num_samples, 8);
for i = 1:num_samples
    data(i,1) = min(255, max(0, speed(i)));
    data(i,2) = min(100, max(0, throttle(i)));
    data(i,3) = min(100, max(0, brake(i)));
    data(i,4) = min(8, max(1, gear(i)));
    
    rpm_val = min(15000, max(0, rpm(i)));
    data(i,5) = floor(rpm_val / 256);
    data(i,6) = mod(rpm_val, 256);
end

% Create timeseries
f1_data = timeseries(data, t);
f1_data.Name = 'F1 Telemetry Test Data';

% Save to workspace
assignin('base', 'f1_data', f1_data);
