% F1_Telemetry_CAN_Live.m
% Creates a Simulink model for F1 telemetry with direct CAN integration
% This version provides more reliable live data streaming from CAN_Send.py

% Define the model name
modelName = 'F1_Telemetry_CAN_Live';

% Close existing model if open
if bdIsLoaded(modelName)
    close_system(modelName, 0);
end

% Create new model
new_system(modelName);
open_system(modelName);

% Configure model settings for real-time execution
set_param(modelName, 'SolverType', 'Fixed-step');
set_param(modelName, 'FixedStep', '0.05'); % 20Hz update rate
set_param(modelName, 'StopTime', 'inf');   % Run until manually stopped

% Create a global variable for CAN data storage
global can_data_buffer;
can_data_buffer = uint8([0 0 0 0 0 0 0 0]); % Initialize empty

% Create global variables for decoded values (for display outside model)
global speed_value throttle_value brake_value gear_value rpm_value;
speed_value = 0;
throttle_value = 0;
brake_value = 0;
gear_value = 0;
rpm_value = 0;

% Make these variables available in workspace
assignin('base', 'can_data_buffer', can_data_buffer);
assignin('base', 'speed_value', speed_value);
assignin('base', 'throttle_value', throttle_value);
assignin('base', 'brake_value', brake_value);
assignin('base', 'gear_value', gear_value);
assignin('base', 'rpm_value', rpm_value);

% Create a From Workspace block using the global variable
add_block('simulink/Sources/From Workspace', [modelName '/CAN_Data'], ...
    'Position', [100, 100, 200, 140], ...
    'VariableName', 'can_data_buffer_ts', ...
    'SampleTime', '0.05', ...
    'Interpolate', 'off', ...
    'OutputAfterFinalValue', 'Holding final value', ...
    'BackgroundColor', 'green');

% Create MATLAB Function block for data decoding
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
        '    persistent lastValidData;', newline, ...
        '    if isempty(lastValidData)', newline, ...
        '        lastValidData = [0 0 0 1 0];', newline, ...
        '    end', newline, ...
        '    ', newline, ...
        '    % Extract values from CAN message', newline, ...
        '    if ~isempty(u) && length(u) >= 6', newline, ...
        '        speed = double(u(1));', newline, ...
        '        throttle = double(u(2));', newline, ...
        '        brake = double(u(3));', newline, ...
        '        gear = double(u(4));', newline, ...
        '        rpm = double(bitshift(u(5), 8) + u(6));', newline, ...
        '        ', newline, ...
        '        % Store valid data', newline, ...
        '        lastValidData = [speed, throttle, brake, gear, rpm];', newline, ...
        '    else', newline, ...
        '        % Use last valid data if current data is invalid', newline, ...
        '        speed = lastValidData(1);', newline, ...
        '        throttle = lastValidData(2);', newline, ...
        '        brake = lastValidData(3);', newline, ...
        '        gear = lastValidData(4);', newline, ...
        '        rpm = lastValidData(5);', newline, ...
        '    end', newline, ...
        '    ', newline, ...
        '    % Update global variables for external access', newline, ...
        '    global speed_value throttle_value brake_value gear_value rpm_value;', newline, ...
        '    speed_value = speed;', newline, ...
        '    throttle_value = throttle;', newline, ...
        '    brake_value = brake;', newline, ...
        '    gear_value = gear;', newline, ...
        '    rpm_value = rpm;', newline, ...
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

% Add enhanced scopes with history
add_block('simulink/Sinks/Scope', [modelName '/Speed_Scope'], ...
    'Position', [650, 50, 700, 100], ...
    'BackgroundColor', 'lightBlue');
set_param([modelName '/Speed_Scope'], 'NumInputPorts', '1');
set_param([modelName '/Speed_Scope'], 'SaveToWorkspace', 'on');
set_param([modelName '/Speed_Scope'], 'SaveName', 'speed_hist');
set_param([modelName '/Speed_Scope'], 'LimitDataPoints', 'off');

add_block('simulink/Sinks/Scope', [modelName '/Throttle_Scope'], ...
    'Position', [650, 120, 700, 170], ...
    'BackgroundColor', 'lightGreen');
set_param([modelName '/Throttle_Scope'], 'NumInputPorts', '1');
set_param([modelName '/Throttle_Scope'], 'SaveToWorkspace', 'on');
set_param([modelName '/Throttle_Scope'], 'SaveName', 'throttle_hist');
set_param([modelName '/Throttle_Scope'], 'LimitDataPoints', 'off');

add_block('simulink/Sinks/Scope', [modelName '/Brake_Scope'], ...
    'Position', [650, 190, 700, 240], ...
    'BackgroundColor', 'red', ...
    'ForegroundColor', 'white');
set_param([modelName '/Brake_Scope'], 'NumInputPorts', '1');
set_param([modelName '/Brake_Scope'], 'SaveToWorkspace', 'on');
set_param([modelName '/Brake_Scope'], 'SaveName', 'brake_hist');
set_param([modelName '/Brake_Scope'], 'LimitDataPoints', 'off');

add_block('simulink/Sinks/Scope', [modelName '/RPM_Scope'], ...
    'Position', [650, 260, 700, 310], ...
    'BackgroundColor', 'yellow');
set_param([modelName '/RPM_Scope'], 'NumInputPorts', '1');
set_param([modelName '/RPM_Scope'], 'SaveToWorkspace', 'on');
set_param([modelName '/RPM_Scope'], 'SaveName', 'rpm_hist');
set_param([modelName '/RPM_Scope'], 'LimitDataPoints', 'off');

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

% Add To Workspace block to save results
add_block('simulink/Sinks/To Workspace', [modelName '/Results'], ...
    'Position', [500, 300, 600, 340], ...
    'VariableName', 'telemetry_results', ...
    'SampleTime', '0.05');

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

% Add annotation
add_block('built-in/Note', [modelName, '/Live_CAN_Note'], ...
    'Position', [100, 50, 250, 70], ...
    'Text', 'LIVE CAN DATA CONNECTION', ...
    'FontSize', '12', ...
    'BackgroundColor', 'green', ...
    'ForegroundColor', 'white');

% Save model
save_system(modelName);

% CAN reception logic
disp('Starting CAN data receiver...');

% Initialize CAN hardware
try
    % Initialize Vector CAN hardware
    global ch;
    ch = canChannel('Vector', 'Virtual 1', 1);
    configBusSpeed(ch, 500000);
    
    % Setup a callback function for when CAN messages arrive
    ch.ReceivedMsgsFcnCount = 1;
    ch.ReceivedMsgsFcn = @canMsgCallbackLive;
    
    % Start the CAN channel
    start(ch);
    disp('CAN hardware initialized successfully.');
    
    % Save the channel in base workspace
    assignin('base', 'ch', ch);
    
    % Create initial timeseries for the model
    t = 0:0.05:1; % Initial 1 second of data
    data = repmat(uint8([0 0 0 1 0 0 0 0]), length(t), 1);
    can_data_buffer_ts = timeseries(data, t);
    assignin('base', 'can_data_buffer_ts', can_data_buffer_ts);
    
    % Setup a timer to continuously update the timeseries
    canUpdateTimer = timer;
    canUpdateTimer.Period = 0.05; % 20Hz update
    canUpdateTimer.ExecutionMode = 'fixedRate';
    canUpdateTimer.TimerFcn = @updateTimeseriesData;
    start(canUpdateTimer);
    
    % Save the timer in base workspace
    assignin('base', 'canUpdateTimer', canUpdateTimer);
    
    % Setup cleanup function
    cleanupObj = onCleanup(@() cleanupCANLive());
    assignin('base', 'canCleanupObj', cleanupObj);
    
catch canErr
    warning('Error setting up CAN hardware: %s', canErr.message);
    warning('Falling back to simulated data.');
    
    % Create a simulated data source
    simTimer = timer;
    simTimer.Period = 0.1;
    simTimer.ExecutionMode = 'fixedRate';
    simTimer.TimerFcn = @simulateCANData;
    start(simTimer);
    assignin('base', 'simTimer', simTimer);
    
    % Initial data for the model
    t = 0:0.05:1; % Initial 1 second of data
    data = repmat(uint8([0 0 0 1 0 0 0 0]), length(t), 1);
    can_data_buffer_ts = timeseries(data, t);
    assignin('base', 'can_data_buffer_ts', can_data_buffer_ts);
    
    % Setup a timer to continuously update the timeseries
    canUpdateTimer = timer;
    canUpdateTimer.Period = 0.05; % 20Hz update
    canUpdateTimer.ExecutionMode = 'fixedRate';
    canUpdateTimer.TimerFcn = @updateTimeseriesData;
    start(canUpdateTimer);
    assignin('base', 'canUpdateTimer', canUpdateTimer);
    
    % Setup cleanup function
    cleanupObj = onCleanup(@() cleanupSimLive());
    assignin('base', 'canCleanupObj', cleanupObj);
end

% Start the model
disp('Starting the Simulink model...');
set_param(modelName, 'SimulationCommand', 'start');

disp('=== F1 Telemetry CAN Live System Running ===');
disp('The model is now running and will display live data from CAN_Send.py.');
disp('Make sure your Python script is running:');
disp('   python CAN_Send.py');
disp(' ');
disp('To stop the system and clean up resources:');
disp('   stopF1CANLive');

% Create a helper function to stop everything
stopFcn = sprintf(['function stopF1CANLive()\n', ...
    '    try\n', ...
    '        set_param(''%s'', ''SimulationCommand'', ''stop'');\n', ...
    '        fprintf(''Simulink model stopped.\\n'');\n', ...
    '    catch\n', ...
    '        fprintf(''Model already stopped.\\n'');\n', ...
    '    end\n', ...
    '    \n', ...
    '    try\n', ...
    '        global ch;\n', ...
    '        if ~isempty(ch) && isvalid(ch)\n', ...
    '            stop(ch);\n', ...
    '            delete(ch);\n', ...
    '            fprintf(''CAN channel stopped and deleted.\\n'');\n', ...
    '        end\n', ...
    '    catch\n', ...
    '        fprintf(''Error stopping CAN channel.\\n'');\n', ...
    '    end\n', ...
    '    \n', ...
    '    try\n', ...
    '        t = timerfindall;\n', ...
    '        if ~isempty(t)\n', ...
    '            stop(t);\n', ...
    '            delete(t);\n', ...
    '            fprintf(''Timers stopped and deleted.\\n'');\n', ...
    '        end\n', ...
    '    catch\n', ...
    '        fprintf(''Error stopping timers.\\n'');\n', ...
    '    end\n', ...
    '    \n', ...
    '    fprintf(''Cleanup complete.\\n'');\n', ...
    'end'], modelName);

% Save the stop function
fid = fopen('stopF1CANLive.m', 'w');
fprintf(fid, '%s', stopFcn);
fclose(fid);

% Define the callback function for CAN messages
function canMsgCallbackLive(src, ~)
    global can_data_buffer;
    
    % Get the message
    msg = receive(src, 1);
    
    % Check if this is our expected message ID (0x123 = 291 decimal)
    if msg.ID == hex2dec('123') && length(msg.Data) >= 6
        % Update our data
        can_data_buffer = uint8(msg.Data);
        
        % Extract data for debugging/monitoring (optional)
        speed = double(can_data_buffer(1));
        throttle = double(can_data_buffer(2));
        brake = double(can_data_buffer(3));
        gear = double(can_data_buffer(4));
        rpm = double(bitshift(can_data_buffer(5), 8) + can_data_buffer(6));
        
        % Uncomment to debug/print data
        % fprintf('CAN data: Speed=%d, Throttle=%d, Brake=%d, Gear=%d, RPM=%d\n', ...
        %     speed, throttle, brake, gear, rpm);
    end
end

% Simulated data generator (used when CAN hardware fails)
function simulateCANData(~, ~)
    global can_data_buffer;
    
    % Get the current time for generating dynamic values
    t = rem(now*86400, 100); % Current time in seconds mod 100
    
    % Generate sinusoidal patterns for realistic data
    speed = round(120 + 50 * sin(t/3));
    throttle = round(50 + 40 * sin(t/2));
    brake = round(max(0, min(100, 50 - 40 * sin(t/2))));
    gear = round(3 + 3 * sin(t/4));
    rpm = round(8000 + 4000 * sin(t/3));
    
    % Scale values to appropriate range
    speed = min(255, max(0, speed));
    throttle = min(100, max(0, throttle));
    brake = min(100, max(0, brake));
    gear = min(8, max(1, gear));
    rpm = min(15000, max(0, rpm));
    
    % Format as CAN message
    rpm_high = floor(rpm / 256);
    rpm_low = mod(rpm, 256);
    
    % Update the buffer with new values
    can_data_buffer = uint8([speed, throttle, brake, gear, rpm_high, rpm_low, 0, 0]);
    
    % Uncomment to debug/print data
    % fprintf('Sim data: Speed=%d, Throttle=%d, Brake=%d, Gear=%d, RPM=%d\n', ...
    %     speed, throttle, brake, gear, rpm);
end

% Update the timeseries for the model
function updateTimeseriesData(~, ~)
    global can_data_buffer;
    
    % Create a timeseries with the latest data
    t = now * 86400; % Current time in seconds
    can_data_buffer_ts = timeseries(can_data_buffer', t);
    
    % Update in the base workspace
    assignin('base', 'can_data_buffer_ts', can_data_buffer_ts);
end

% Define cleanup function for CAN mode
function cleanupCANLive()
    try
        % Stop and delete the timers if they exist
        t = timerfindall;
        if ~isempty(t)
            stop(t);
            delete(t);
        end
        
        % Stop and delete the CAN channel if it exists
        global ch;
        if ~isempty(ch) && isvalid(ch)
            stop(ch);
            delete(ch);
        end
    catch
        % Ignore errors during cleanup
    end
    
    disp('CAN resources cleaned up.');
end

% Define cleanup function for simulation mode
function cleanupSimLive()
    try
        % Stop and delete the timers if they exist
        t = timerfindall;
        if ~isempty(t)
            stop(t);
            delete(t);
        end
    catch
        % Ignore errors during cleanup
    end
    
    disp('Simulation resources cleaned up.');
end
