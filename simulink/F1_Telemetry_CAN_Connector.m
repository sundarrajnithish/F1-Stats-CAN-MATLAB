% F1_Telemetry_CAN_Connector.m
% This script modifies F1_Telemetry_Simple to connect with real CAN data
% from CAN_Send.py

% Check if F1_Telemetry_Simple model exists and is loaded
modelName = 'F1_Telemetry_Simple';
if ~bdIsLoaded(modelName)
    % Try to load the model
    try
        load_system(modelName);
    catch
        error('F1_Telemetry_Simple model not found. Please run F1_Telemetry_Simple.m first.');
    end
end

% Check if model is running
isModelRunning = (strcmp(get_param(modelName, 'SimulationStatus'), 'running'));
if isModelRunning
    fprintf('Stopping the currently running model...\n');
    set_param(modelName, 'SimulationCommand', 'stop');
    pause(1); % Give it time to stop
end

fprintf('Configuring %s to receive live CAN data...\n', modelName);

% Check if we have the CAN related blocks in the model
try
    % Try to add a CAN Receiver block (a simpler approach using From Workspace)
    canBlockExists = ~isempty(find_system(modelName, 'BlockType', 'S-Function', 'Name', 'CAN_Receiver'));
    
    if ~canBlockExists
        % Set up manual CAN reception
        fprintf('Adding CAN reception functionality...\n');
        
        % Create a workspace variable to hold CAN data
        global can_data;
        can_data = uint8([120 50 25 3 43 180 0 0]);
        assignin('base', 'can_data', can_data);
        
        % Set up a timer to update the CAN data
        canTimer = timer;
        canTimer.Period = 0.1; % 10 Hz, same as Python script
        canTimer.ExecutionMode = 'fixedRate';
        canTimer.TimerFcn = @updateCANData;
        
        % Save the timer in base workspace
        assignin('base', 'canTimer', canTimer);
        
        % Modify the model to use our updated can_data variable
        try
            % Update the constant block with can_data
            constBlock = find_system(modelName, 'BlockType', 'Constant', 'Name', 'CAN_Data');
            if ~isempty(constBlock)
                set_param(constBlock{1}, 'Value', 'can_data');
            end
            
            % Change block coloring to indicate real data reception
            set_param(constBlock{1}, 'BackgroundColor', 'green');
            set_param(constBlock{1}, 'ForegroundColor', 'white');
            
            % Add a text annotation to indicate live data mode
            try
                notePath = [modelName, '/Live_Mode'];
                if isempty(find_system(modelName, 'Name', 'Live_Mode'))
                    add_block('built-in/Note', notePath, ...
                        'Position', [100, 50, 250, 70], ...
                        'Text', 'CONNECTED TO LIVE CAN DATA', ...
                        'FontSize', '12', ...
                        'BackgroundColor', 'green', ...
                        'ForegroundColor', 'white');
                end
            catch annotationErr
                fprintf('Could not add annotation: %s\n', annotationErr.message);
            end
            
            % Set the manual switch to the workspace input if it exists
            switchBlock = find_system(modelName, 'BlockType', 'Manual Switch');
            if ~isempty(switchBlock)
                % Switch to position 1 (up) for constant value input
                set_param(switchBlock{1}, 'sw', '0');
            end
            
            fprintf('Model configured for live CAN data reception.\n');
        catch blockErr
            fprintf('Error configuring model blocks: %s\n', blockErr.message);
        end
    end
catch
    fprintf('Error adding CAN reception capability.\n');
end

% Initialize the Vector CAN channel
try
    % Initialize the Vector CAN channel
    fprintf('Initializing Vector CAN channel...\n');
    
    % Create a CAN channel object
    global ch;
    ch = canChannel('Vector', 'Virtual 1', 1);
    configBusSpeed(ch, 500000);
    
    % Setup a callback function for when CAN messages arrive
    ch.ReceivedMsgsFcnCount = 1; % Call function after each message
    ch.ReceivedMsgsFcn = @canMsgCallback;
    
    % Start the CAN channel
    start(ch);
    fprintf('CAN channel started. Waiting for messages from CAN_Send.py...\n');
    
    % Save the channel in base workspace
    assignin('base', 'ch', ch);
    
    % Start the timer
    start(canTimer);
    fprintf('CAN data update timer started.\n');
    
    % Setup cleanup function
    cleanupObj = onCleanup(@() cleanupCAN());
    assignin('base', 'canCleanupObj', cleanupObj);
catch canErr
    fprintf('Error setting up CAN communication: %s\n', canErr.message);
    fprintf('Make sure Vector CAN hardware and drivers are installed.\n');
    fprintf('Falling back to simulated data.\n');
end

% Start the model
fprintf('Starting the model...\n');
set_param(modelName, 'SimulationCommand', 'start');

fprintf('\n===== F1 Telemetry CAN Connection Setup Complete =====\n\n');
fprintf('The model is now running and should display live data from CAN_Send.py.\n');
fprintf('Make sure your Python script is running:\n');
fprintf('   python CAN_Send.py\n\n');
fprintf('To stop the model and clean up CAN resources:\n');
fprintf('   stopF1CAN\n\n');

% Create a helper function to stop everything
stopFcn = sprintf(['function stopF1CAN()\n', ...
    '    try\n', ...
    '        set_param(''%s'', ''SimulationCommand'', ''stop'');\n', ...
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
    '        t = timerfind(''Name'', '''');\n', ...
    '        if ~isempty(t)\n', ...
    '            stop(t);\n', ...
    '            delete(t);\n', ...
    '            fprintf(''Timer stopped and deleted.\\n'');\n', ...
    '        end\n', ...
    '    catch\n', ...
    '        fprintf(''Error stopping timer.\\n'');\n', ...
    '    end\n', ...
    '    \n', ...
    '    fprintf(''Cleanup complete.\\n'');\n', ...
    'end'], modelName);

% Save the stop function
fid = fopen('stopF1CAN.m', 'w');
fprintf(fid, '%s', stopFcn);
fclose(fid);

% Define the callback function for CAN messages
function canMsgCallback(src, ~)
    global can_data;
    
    % Get the message
    msg = receive(src, 1);
    
    % Check if this is our expected message ID (0x123 = 291 decimal)
    if msg.ID == hex2dec('123') && length(msg.Data) >= 6
        % Update our data
        can_data = uint8(msg.Data);
        
        % Optional - print data (commented out to reduce console spam)
        % fprintf('Received CAN data: Speed=%d, Throttle=%d, Brake=%d, RPM=%d\n', ...
        %     can_data(1), can_data(2), can_data(3), ...
        %     double(bitshift(can_data(5), 8) + can_data(6)));
    end
end

% Define timer function to update CAN data
function updateCANData(~, ~)
    % Nothing to do here - the canMsgCallback function 
    % will update can_data when messages arrive
end

% Define cleanup function
function cleanupCAN()
    try
        % Stop and delete the timer if it exists
        t = timerfind('Name', '');
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
    
    fprintf('CAN resources cleaned up.\n');
end
