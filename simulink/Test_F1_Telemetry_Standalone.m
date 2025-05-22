% Test_F1_Telemetry_Standalone.m
% Generates realistic F1 telemetry data for the standalone model

% Create time vector (30 seconds at 10Hz)
t = (0:0.1:30)';
numSamples = length(t);

% Create a circuit profile (0-1 range representing track position)
% where 0 is slow corners and 1 is straights
circuit = zeros(numSamples, 1);

% Create a realistic circuit pattern with straights and corners
% Montreal circuit inspired profile with straights and chicanes
for i = 1:numSamples
    % Create a pattern that repeats every 10 seconds (lap time)
    lapPos = mod(t(i), 10) / 10;
    
    if lapPos < 0.2  % Main straight
        circuit(i) = 0.9 + 0.1*sin(lapPos*10*pi);
    elseif lapPos < 0.3  % Hard braking for turn 1
        circuit(i) = 0.9 - 8*(lapPos-0.2);
    elseif lapPos < 0.4  % Turn 1 and 2 chicane
        circuit(i) = 0.1 + 0.1*sin(lapPos*20*pi);
    elseif lapPos < 0.55  % Short straight
        circuit(i) = 0.3 + 5*(lapPos-0.4);
    elseif lapPos < 0.65  % Hard braking and slow corner
        circuit(i) = 0.8 - 7*(lapPos-0.55);
    elseif lapPos < 0.75  % Technical section
        circuit(i) = 0.1 + 0.15*sin(lapPos*30*pi);
    elseif lapPos < 0.9  % Back straight
        circuit(i) = 0.25 + 7*(lapPos-0.75);
    else  % Final chicane
        circuit(i) = 0.95 - 8*(lapPos-0.9)^2;
    end
end

% Add some noise to make it more realistic
circuit = circuit + 0.05*randn(size(circuit));
circuit = max(0, min(1, circuit));  % Keep in 0-1 range

% Create telemetry based on circuit profile
% Speed: slowest in corners, fastest on straights (80-320 km/h)
speed = 80 + 240 * circuit + 5*randn(size(circuit));

% Throttle: high on straights, low in corners
throttle = 100 * (circuit.^0.5) + 5*randn(size(circuit));

% Brake: inverse of throttle, with phase shift (braking happens before corners)
brake_circuit = [circuit(5:end); zeros(4,1)]; % Phase-shifted for brake anticipation
brake = 100 * (1 - brake_circuit) + 5*randn(size(circuit));

% Gear: from 1 (slow corners) to 8 (straights)
gear = 1 + 7 * circuit + 0.3*randn(size(circuit));

% RPM: correlates with speed (2000-13000 rpm)
rpm = 2000 + 11000 * circuit + 200*randn(size(circuit));

% Convert to integer format like the Python code
speed = round(min(255, max(0, speed)));
throttle = round(min(100, max(0, throttle)));
brake = round(min(100, max(0, brake)));
gear = round(min(8, max(1, gear)));
rpm = round(min(15000, max(2000, rpm)));

% Create visualization of the simulated data
figure('Name', 'F1 Telemetry Simulation', 'Position', [100 100 800 600]);

subplot(5,1,1);
plot(t, speed, 'b'); grid on;
title('Speed (km/h)');
ylabel('km/h');
ylim([0 300]);

subplot(5,1,2);
plot(t, throttle, 'g'); grid on;
title('Throttle (%)');
ylabel('%');
ylim([0 100]);

subplot(5,1,3);
plot(t, brake, 'r'); grid on;
title('Brake (%)');
ylabel('%');
ylim([0 100]);

subplot(5,1,4);
plot(t, gear, 'm'); grid on;
title('Gear');
ylabel('Gear');
ylim([0 9]);

subplot(5,1,5);
plot(t, rpm, 'c'); grid on;
title('RPM');
xlabel('Time (s)');
ylabel('RPM');
ylim([0 15000]);

% Format data for CAN message simulation
data = zeros(numSamples, 8);
for i = 1:numSamples
    data(i,1) = uint8(speed(i));
    data(i,2) = uint8(throttle(i));
    data(i,3) = uint8(brake(i));
    data(i,4) = uint8(gear(i));
    
    rpm_val = rpm(i);
    data(i,5) = uint8(floor(rpm_val / 256)); % High byte
    data(i,6) = uint8(mod(rpm_val, 256));    % Low byte
    data(i,7) = 0;
    data(i,8) = 0;
end

% Create timeseries object
f1_data = timeseries(data, t);
f1_data.Name = 'F1 Telemetry Data';

% Save to workspace
assignin('base', 'f1_data', f1_data);

% Display instructions
fprintf('\n==== F1 Telemetry Test Data Generated ====\n\n');
fprintf('Data has been created in the workspace as "f1_data".\n');
fprintf('Now you can run the F1_Telemetry_Standalone model to visualize it.\n');
fprintf('To run the model, type:\n');
fprintf('>> sim(''F1_Telemetry_Standalone'')\n\n');

% Ask if user wants to run the model
run_model = input('Would you like to run the model now? (y/n): ', 's');

if strcmpi(run_model, 'y')
    fprintf('Running F1_Telemetry_Standalone model...\n');
    sim('F1_Telemetry_Standalone');
    fprintf('Simulation complete!\n');
end
