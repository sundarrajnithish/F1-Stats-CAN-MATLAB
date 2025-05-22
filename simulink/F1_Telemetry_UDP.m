% F1_Telemetry_UDP.m
% Creates a Simulink model for F1 telemetry that receives data via UDP
% Works without Vector CAN hardware

% Define a model name
modelName = 'F1_Telemetry_UDP';

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

% Create global variables for data access
global telemetry_data;
telemetry_data = struct('speed', 0, 'throttle', 0, 'brake', 0, 'gear', 1, 'rpm', 0, 'driver', 0);
assignin('base', 'telemetry_data', telemetry_data);

% Create a MATLAB Function block that reads from our global telemetry_data
add_block('simulink/User-Defined Functions/MATLAB Function', [modelName '/Data_Source'], ...
    'Position', [100, 100, 200, 160], ...
    'BackgroundColor', 'green');

% Set MATLAB Function content for data source
source_path = getfullname([modelName '/Data_Source']);
open_system(source_path);
pause(1);

rt = sfroot;
chart = rt.find('-isa', 'Stateflow.EMChart', 'Path', [modelName '/Data_Source']);
if ~isempty(chart)
    chart.Script = [
        'function [speed, throttle, brake, gear, rpm, driver] = Data_Source()', newline, ...
        '    % Access global telemetry data that is updated by the UDP receiver', newline, ...
        '    global telemetry_data;', newline, ...
        '    ', newline, ...
        '    % Extract values from telemetry data struct', newline, ...
        '    speed = double(telemetry_data.speed);', newline, ...
        '    throttle = double(telemetry_data.throttle);', newline, ...
        '    brake = double(telemetry_data.brake);', newline, ...
        '    gear = double(telemetry_data.gear);', newline, ...
        '    rpm = double(telemetry_data.rpm);', newline, ...
        '    driver = double(telemetry_data.driver);', newline, ...
        'end'
    ];
else
    error('Could not find or configure the MATLAB Function block');
end

% Add display blocks
add_block('simulink/Sinks/Display', [modelName '/Speed'], ...
    'Position', [500, 50, 600, 70], ...
    'Format', '%.1f km/h');
add_block('simulink/Sinks/Display', [modelName '/Throttle'], ...
    'Position', [500, 100, 600, 120], ...
    'Format', '%.0f %%');
add_block('simulink/Sinks/Display', [modelName '/Brake'], ...
    'Position', [500, 150, 600, 170], ...
    'Format', '%.0f %%');
add_block('simulink/Sinks/Display', [modelName '/Gear'], ...
    'Position', [500, 200, 600, 220]);
add_block('simulink/Sinks/Display', [modelName '/RPM'], ...
    'Position', [500, 250, 600, 270], ...
    'Format', '%.0f rpm');
add_block('simulink/Sinks/Display', [modelName '/Driver'], ...
    'Position', [500, 300, 600, 320], ...
    'Format', '#%.0f');

% Add enhanced scopes with history
add_block('simulink/Sinks/Scope', [modelName '/Speed_Scope'], ...
    'Position', [650, 50, 700, 100], ...
    'BackgroundColor', 'lightBlue');

add_block('simulink/Sinks/Scope', [modelName '/Throttle_Scope'], ...
    'Position', [650, 120, 700, 170], ...
    'BackgroundColor', 'lightGreen');

add_block('simulink/Sinks/Scope', [modelName '/Brake_Scope'], ...
    'Position', [650, 190, 700, 240], ...
    'BackgroundColor', 'red', ...
    'ForegroundColor', 'white');

add_block('simulink/Sinks/Scope', [modelName '/RPM_Scope'], ...
    'Position', [650, 260, 700, 310], ...
    'BackgroundColor', 'yellow');

% Connect blocks to data source
add_line(modelName, 'Data_Source/1', 'Speed/1');
add_line(modelName, 'Data_Source/2', 'Throttle/1');
add_line(modelName, 'Data_Source/3', 'Brake/1');
add_line(modelName, 'Data_Source/4', 'Gear/1');
add_line(modelName, 'Data_Source/5', 'RPM/1');
add_line(modelName, 'Data_Source/6', 'Driver/1');

% Connect to scopes
add_line(modelName, 'Data_Source/1', 'Speed_Scope/1');
add_line(modelName, 'Data_Source/2', 'Throttle_Scope/1');
add_line(modelName, 'Data_Source/3', 'Brake_Scope/1');
add_line(modelName, 'Data_Source/5', 'RPM_Scope/1');

% Add To Workspace block for data logging
add_block('simulink/Sinks/To Workspace', [modelName '/Results'], ...
    'Position', [500, 350, 600, 390], ...
    'VariableName', 'telemetry_history');

% Create a Bus Creator to collect all signals
add_block('simulink/Signal Routing/Bus Creator', [modelName '/Signal_Bus'], ...
    'Position', [350, 200, 360, 280], ...
    'Inputs', '6');

% Connect signals to bus
for i = 1:6
    add_line(modelName, ['Data_Source/' num2str(i)], ['Signal_Bus/' num2str(i)]);
end

% Connect bus to workspace
add_line(modelName, 'Signal_Bus/1', 'Results/1');

% Add a note about UDP connection
add_block('built-in/Note', [modelName '/UDP_Note'], ...
    'Position', [100, 40, 300, 70], ...
    'Text', 'RECEIVING F1 TELEMETRY VIA UDP (PORT 20001)', ...
    'FontSize', '12', ...
    'BackgroundColor', 'green', ...
    'ForegroundColor', 'white');

% Save the model
save_system(modelName);

% Start UDP receiver
disp('Starting UDP receiver for F1 telemetry data...');

% Create and configure UDP receiver
try
    % Create UDP receiver object
    udpReceiver = dsp.UDPReceiver(...
        'LocalIPPort', 20001, ...
        'MessageDataType', 'uint8', ...
        'MaximumMessageLength', 1024);
    
    % Initialize the receiver
    setup(udpReceiver);
    disp('UDP receiver initialized on port 20001');
    
    % Save to base workspace for cleanup
    assignin('base', 'udpReceiver', udpReceiver);
catch udpErr
    warning('Error initializing UDP receiver: %s', udpErr.message);
    warning('Falling back to simulated data mode');
    
    % Create a simulated data source instead
    simTimer = timer;
    simTimer.Period = 0.1;
    simTimer.ExecutionMode = 'fixedRate';
    simTimer.TimerFcn = @simulateF1Data;
    start(simTimer);
    assignin('base', 'simTimer', simTimer);
end

% Create a timer to poll for UDP messages
udpTimer = timer;
udpTimer.Period = 0.05; % Check for new data at 20Hz
udpTimer.ExecutionMode = 'fixedRate';
udpTimer.TimerFcn = @receiveUDPData;
start(udpTimer);
assignin('base', 'udpTimer', udpTimer);

% Create cleanup function
cleanupObj = onCleanup(@() cleanupUDP());
assignin('base', 'udpCleanupObj', cleanupObj);

% Start the model
set_param(modelName, 'SimulationCommand', 'start');

% Display instructions
fprintf('\n=== F1 Telemetry UDP System Running ===\n\n');
fprintf('The model is now running and ready to receive UDP data.\n');
fprintf('To send data, run the Python UDP script:\n');
fprintf('   python UDP_Send.py\n\n');
fprintf('To stop the system and clean up resources:\n');
fprintf('   stopF1UDP\n\n');

% Create stop function
stopFcn = sprintf(['function stopF1UDP()\n', ...
    '    try\n', ...
    '        set_param(''%s'', ''SimulationCommand'', ''stop'');\n', ...
    '        fprintf(''Simulink model stopped.\\n'');\n', ...
    '    catch\n', ...
    '        fprintf(''Model already stopped.\\n'');\n', ...
    '    end\n', ...
    '    \n', ...
    '    try\n', ...
    '        udpReceiver = evalin(''base'', ''udpReceiver'');\n', ...
    '        if ~isempty(udpReceiver)\n', ...
    '            release(udpReceiver);\n', ...
    '            fprintf(''UDP receiver released.\\n'');\n', ...
    '        end\n', ...
    '    catch\n', ...
    '        fprintf(''No UDP receiver to release.\\n'');\n', ...
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

% Save stop function
fid = fopen('stopF1UDP.m', 'w');
fprintf(fid, '%s', stopFcn);
fclose(fid);

% Function to receive UDP data
function receiveUDPData(~, ~)
    try
        % Access global variables
        global telemetry_data;
        
        % Get the UDP receiver from base workspace
        udpReceiver = evalin('base', 'udpReceiver');
        
        % Check if we have new data
        if ~isempty(udpReceiver)
            % Receive data
            [data, ~, ~] = step(udpReceiver);
            
            % Process if we got data
            if ~isempty(data)
                if length(data) >= 11 % Expect at least 11 bytes
                    % Parse the data according to the protocol
                    % Format: !BBBBHBxB (speed, throttle, brake, gear, rpm, driver, 0)
                    speed = double(data(1));
                    throttle = double(data(2));
                    brake = double(data(3));
                    gear = double(data(4));
                    
                    % RPM is a 2-byte value (big endian)
                    rpm = double(bitshift(uint16(data(5)), 8) + uint16(data(6)));
                    
                    % Driver number
                    driver = double(data(7));
                    
                    % Update the global variables
                    telemetry_data.speed = speed;
                    telemetry_data.throttle = throttle;
                    telemetry_data.brake = brake;
                    telemetry_data.gear = gear;
                    telemetry_data.rpm = rpm;
                    telemetry_data.driver = driver;
                    
                    % Uncomment for debugging
                    % fprintf('UDP: Speed=%d, Throttle=%d, Brake=%d, Gear=%d, RPM=%d, Driver=%d\n', ...
                    %     speed, throttle, brake, gear, rpm, driver);
                end
            end
        end
    catch err
        % Just log the error and continue
        fprintf('UDP receive error: %s\n', err.message);
    end
end

% Function to simulate F1 data
function simulateF1Data(~, ~)
    global telemetry_data;
    
    % Get the current time for generating dynamic values
    t = rem(now*86400, 100); % Current time in seconds mod 100
    
    % Generate sinusoidal patterns for realistic data
    speed = round(120 + 50 * sin(t/3));
    throttle = round(50 + 40 * sin(t/2));
    brake = round(max(0, min(100, 50 - 40 * sin(t/2))));
    gear = round(3 + 3 * sin(t/4));
    rpm = round(8000 + 4000 * sin(t/3));
    
    % Change driver occasionally
    if mod(t, 10) < 0.1
        driver = mod(round(t/10), 20) + 1;
    else
        driver = telemetry_data.driver;
    end
    
    % Scale values to appropriate range
    speed = min(255, max(0, speed));
    throttle = min(100, max(0, throttle));
    brake = min(100, max(0, brake));
    gear = min(8, max(1, gear));
    rpm = min(15000, max(0, rpm));
    
    % Update the telemetry data
    telemetry_data.speed = speed;
    telemetry_data.throttle = throttle;
    telemetry_data.brake = brake;
    telemetry_data.gear = gear;
    telemetry_data.rpm = rpm;
    telemetry_data.driver = driver;
end

% Cleanup function
function cleanupUDP()
    try
        % Stop the model if it's running
        try
            set_param(modelName, 'SimulationCommand', 'stop');
        catch
            % Model might already be closed
        end
        
        % Release the UDP receiver
        try
            udpReceiver = evalin('base', 'udpReceiver');
            if ~isempty(udpReceiver)
                release(udpReceiver);
            end
        catch
            % UDP receiver might not exist
        end
        
        % Stop and delete all timers
        try
            t = timerfindall;
            if ~isempty(t)
                stop(t);
                delete(t);
            end
        catch
            % Timer might not exist
        end
    catch
        % Ignore errors during cleanup
    end
    
    fprintf('UDP resources cleaned up.\n');
end
