% Test_F1_Telemetry_Sim.m
% This script helps test the F1_Telemetry_Sim model with simulated data

% Define the model name
modelName = 'F1_Telemetry_Sim';

% Check if the model exists
if ~exist([modelName '.slx'], 'file')
    fprintf('❌ Model file %s.slx not found. Run CAN_Simulink_Fix.m first.\n', modelName);
    return;
end

% Check if model is loaded, if not, load it
if ~bdIsLoaded(modelName)
    fprintf('Opening %s model...\n', modelName);
    open_system(modelName);
end

% Create test data to simulate a driver's lap
fprintf('Creating test data simulation...\n');

% Define test data length and time vector
testDuration = 30; % 30 seconds of test data
t = linspace(0, testDuration, 1000); % 1000 points over test duration

% Create simulated data (speed, throttle, brake, gear, rpm)
speed = 100 + 50 * sin(t/2) + 20 * sin(t/5) + 10 * randn(size(t)); % Speed 50-150km/h with variation
throttle = 50 + 40 * sin(t/3) + 5 * randn(size(t));               % Throttle 10-90%
brake = max(0, 20 - 50 * sin(t/3) + 5 * randn(size(t)));           % Brake when throttle is low
rpm = 6000 + 2000 * sin(t/2) + 1000 * sin(t/7) + 500 * randn(size(t)); % RPM 4000-8000 with variation

% Ensure values are within bounds
speed = min(max(speed, 0), 255);
throttle = min(max(throttle, 0), 100);
brake = min(max(brake, 0), 100);
rpm = min(max(rpm, 0), 15000);

% Convert to CAN format (create raw data bytes)
can_data = zeros(length(t), 8);
for i = 1:length(t)
    can_data(i,1) = uint8(speed(i));
    can_data(i,2) = uint8(throttle(i));
    can_data(i,3) = uint8(brake(i));
    can_data(i,4) = uint8(3); % Gear (fixed at 3 for simplicity)
    rpm_value = uint16(rpm(i));
    can_data(i,5) = uint8(bitshift(rpm_value, -8)); % High byte
    can_data(i,6) = uint8(bitand(rpm_value, 255));  % Low byte
end

% Create a timeseries for simulation
sim_data = timeseries(can_data, t);
sim_data.Name = 'CAN_Simulated_Data';

% Save this to workspace for model input
assignin('base', 'sim_data', sim_data);

% Check if model has a simulated input or CAN input
try
    % Look for CAN blocks in the model
    hasCANBlocks = ~isempty(find_system(modelName, 'RegExp', 'on', 'Name', 'CAN_R.*'));
    
    % If CAN blocks exist, we need to bypass them for testing
    if hasCANBlocks
        fprintf('Model has CAN blocks. Creating test harness...\n');
        
        % Create a test harness model
        testModelName = [modelName '_Test'];
        
        % Close previous instance if exists
        if bdIsLoaded(testModelName)
            bdclose(testModelName);
        end
        
        % Create new test model
        new_system(testModelName);
        open_system(testModelName);
        
        % Add From workspace block
        add_block('simulink/Sources/From Workspace', [testModelName '/Simulated_Data'], ...
            'Position', [100 100 200 130], ...
            'VariableName', 'sim_data');
        
        % Add the original model as a referenced model
        add_block('simulink/Ports & Subsystems/Model', [testModelName '/F1_Model'], ...
            'Position', [250 100 450 200], ...
            'ModelNameDialog', modelName);
        
        % Connect simulated data to the model input
        add_line(testModelName, 'Simulated_Data/1', 'F1_Model/1');
        
        % Set solver parameters
        set_param(testModelName, 'SolverType', 'Fixed-step');
        set_param(testModelName, 'FixedStep', '0.01');
        set_param(testModelName, 'StopTime', num2str(testDuration));
        
        % Save the test model
        save_system(testModelName);
        
        fprintf('✅ Test harness created. Running simulation...\n');
        
        % Run the simulation
        sim(testModelName, testDuration);
    else
        % Model might already have simulated input, just run it
        fprintf('Running direct simulation...\n');
        
        % Check for From Workspace block
        hasFromWorkspace = ~isempty(find_system(modelName, 'RegExp', 'on', 'BlockType', 'FromWorkspace'));
        
        if ~hasFromWorkspace
            warning('Could not find an appropriate input block. You may need to modify the model.');
        end
        
        % Set stop time
        set_param(modelName, 'StopTime', num2str(testDuration));
        
        % Run the simulation
        sim(modelName, testDuration);
    end
    
    fprintf('✅ Simulation complete!\n');
    
catch e
    fprintf('❌ Error during simulation: %s\n', e.message);
end
