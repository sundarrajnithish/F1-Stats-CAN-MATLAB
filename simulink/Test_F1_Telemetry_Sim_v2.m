% Test_F1_Telemetry_Sim_v2.m
% This script tests the F1_Telemetry_Sim_v2 model with simulated data
% that matches the format of the CAN_Send.py output

% Define the model name
modelName = 'F1_Telemetry_Sim_v2';

% Check if the model exists
if ~exist([modelName '.slx'], 'file')
    fprintf('❌ Model file %s.slx not found. Run F1_Telemetry_Direct_Fix_v2.m first.\n', modelName);
    return;
end

% Check if model is loaded, if not, load it
if ~bdIsLoaded(modelName)
    fprintf('Opening %s model...\n', modelName);
    open_system(modelName);
end

% Create test data to simulate multiple drivers
fprintf('Creating test data simulation for multiple drivers...\n');

% Set up parameters for simulation
numDrivers = 3;
lapDuration = 10; % seconds per driver
samplesPerSec = 10; % 10 Hz to match CAN_Send.py

% Create a cell array to store data for all drivers
driverData = cell(numDrivers, 1);

% Generate simulated telemetry for each driver with different characteristics
driverNames = {'Max (1)', 'Lewis (44)', 'Charles (16)'};
driverColors = {'b', 'r', 'y'};

% Create figure for verification plot
figure('Name', 'Simulated F1 Telemetry Data', 'Position', [100, 100, 800, 600]);
subplot(5,1,1); hold on; grid on; title('Speed (km/h)');
subplot(5,1,2); hold on; grid on; title('Throttle (%)');
subplot(5,1,3); hold on; grid on; title('Brake (%)');
subplot(5,1,4); hold on; grid on; title('Gear');
subplot(5,1,5); hold on; grid on; title('RPM'); xlabel('Time (s)');

% Generate data for each driver
allData = [];
tAll = [];

for d = 1:numDrivers
    fprintf('Generating data for driver %s\n', driverNames{d});
    
    % Create time vector for this driver
    tStart = (d-1) * (lapDuration + 2); % Add 2 sec gap between drivers
    tEnd = tStart + lapDuration;
    t = linspace(tStart, tEnd, lapDuration * samplesPerSec);
    
    % Create driver-specific characteristics
    switch d
        case 1 % Aggressive driver (Max)
            % More aggressive throttle/brake application
            speedBase = 200;
            throttleFactor = 0.9;
            brakeFactor = 0.8;
            rpmFactor = 1.1;
        case 2 % Smooth driver (Lewis)
            % Smoother inputs, more consistent
            speedBase = 195;
            throttleFactor = 0.7;
            brakeFactor = 0.6;
            rpmFactor = 1.0;
        case 3 % Balanced driver (Charles)
            speedBase = 190;
            throttleFactor = 0.8;
            brakeFactor = 0.7;
            rpmFactor = 0.95;
    end
    
    % Create base track pattern (0 to 1) representing a lap
    % with acceleration zones, braking zones, and corners
    lap_pattern = 0.5 + 0.5 * sin(2 * pi * (t - tStart) / lapDuration * 3);
    
    % Generate speed with some noise (km/h)
    speed = speedBase * (0.7 + 0.3 * lap_pattern) + 10 * randn(size(t));
    
    % Generate throttle - high in straights, low in corners (%)
    throttle = 100 * throttleFactor * (lap_pattern > 0.5) .* lap_pattern + 5 * randn(size(t));
    
    % Generate brake - inverse of throttle with phase shift (%)
    brake = 100 * brakeFactor * (lap_pattern < 0.5) .* (1 - lap_pattern) + 3 * randn(size(t));
    
    % Generate gear (1-8)
    gear = ceil(1 + 7 * lap_pattern + 0.2 * randn(size(t)));
    
    % Generate RPM (3000-15000)
    rpm = 3000 + 12000 * rpmFactor * lap_pattern + 500 * randn(size(t));
    
    % Ensure values are within bounds
    speed = min(max(speed, 0), 255);
    throttle = min(max(throttle, 0), 100);
    brake = min(max(brake, 0), 100);
    gear = min(max(gear, 1), 8);
    rpm = min(max(rpm, 3000), 15000);
    
    % Convert to integer values as in the Python script
    speed = round(speed);
    throttle = round(throttle);
    brake = round(brake);
    gear = round(gear);
    rpm = round(rpm);
    
    % Create raw CAN data format (bytes)
    can_data = zeros(length(t), 8);
    for i = 1:length(t)
        can_data(i,1) = uint8(speed(i));
        can_data(i,2) = uint8(throttle(i));
        can_data(i,3) = uint8(brake(i));
        can_data(i,4) = uint8(gear(i));
        rpm_val = uint16(rpm(i));
        can_data(i,5) = uint8(bitshift(rpm_val, -8)); % High byte
        can_data(i,6) = uint8(bitand(rpm_val, 255));  % Low byte
        can_data(i,7) = 0;
        can_data(i,8) = 0;
    end
    
    % Store all data
    driverData{d} = struct('t', t, 'can_data', can_data, 'speed', speed, ...
        'throttle', throttle, 'brake', brake, 'gear', gear, 'rpm', rpm);
    
    % Plot data for verification
    subplot(5,1,1); plot(t, speed, driverColors{d}, 'DisplayName', driverNames{d});
    subplot(5,1,2); plot(t, throttle, driverColors{d});
    subplot(5,1,3); plot(t, brake, driverColors{d});
    subplot(5,1,4); plot(t, gear, driverColors{d});
    subplot(5,1,5); plot(t, rpm, driverColors{d});
    
    % Append to combined dataset
    allData = [allData; can_data];
    tAll = [tAll, t];
end

% Add legends to plots
subplot(5,1,1); legend('show', 'Location', 'eastoutside');

% Create combined timeseries for simulation
fprintf('Creating combined simulation data for %d drivers...\n', numDrivers);
sim_data = timeseries(allData, tAll);
sim_data.Name = 'F1_CAN_Simulated_Data';

% Save to workspace
assignin('base', 'sim_data', sim_data);
assignin('base', 'driverData', driverData);

% Find input port to the DecodeCAN block
if ~isempty(find_system(modelName, 'BlockType', 'Constant'))
    % Find the existing constant block and modify it
    constBlock = find_system(modelName, 'BlockType', 'Constant');
    if ~isempty(constBlock)
        fprintf('Modifying existing constant block to use simulated data...\n');
        
        % Create a From Workspace block
        fromWSBlockPath = [modelName, '/Sim_Data_Input'];
        try
            % Remove existing constant block
            delete_block(constBlock{1});
            
            % Add From Workspace block
            add_block('simulink/Sources/From Workspace', fromWSBlockPath, ...
                'Position', [100, 100, 200, 130], ...
                'VariableName', 'sim_data');
            
            % Find DecodeCAN block input port
            decodeCAN = find_system(modelName, 'BlockType', 'SubSystem', 'Name', 'DecodeCAN');
            if ~isempty(decodeCAN)
                % Connect workspace data to DecodeCAN
                add_line(modelName, 'Sim_Data_Input/1', 'DecodeCAN/1', 'autorouting', 'on');
                fprintf('Connected simulated data to DecodeCAN block\n');
            else
                fprintf('Could not find DecodeCAN block\n');
            end
        catch wsError
            fprintf('Error setting up simulation: %s\n', wsError.message);
        end
    end
else
    fprintf('Could not find constant block to replace\n');
end

% Set simulation parameters
total_sim_time = max(tAll) + 1;
fprintf('Setting simulation time to %.1f seconds\n', total_sim_time);
set_param(modelName, 'StopTime', num2str(total_sim_time));

% Run the simulation
try
    fprintf('\n✅ Starting simulation...\n');
    fprintf('This will simulate %d drivers with different driving styles.\n', numDrivers);
    fprintf('Please check the scopes in the model to see the telemetry data.\n\n');
    
    sim(modelName);
    
    fprintf('Simulation complete!\n');
catch simErr
    fprintf('Error during simulation: %s\n', simErr.message);
end
