clc; clear;

% List of driver numbers in order
driver_numbers = {'55', '1', '16', '63', '11', '23', '81', '44', '4', '14', ...
                  '22', '40', '27', '77', '2', '24', '10', '31', '20', '18'};

% Setup CAN channel
ch = canChannel('Vector', 'Virtual 1', 1);
configBusSpeed(ch, 500000);
start(ch);

disp("Receiving F1 telemetry... Will auto-quit after 5 seconds of inactivity.");

% Initialize
log_all = table();
lastReceiveTime = datetime('now');
driverIdx = 1;
driverLogs = {};  % Cell array to store logs for each driver

% Create figure with subplots
fig = figure('Name', 'F1 Telemetry Viewer', 'NumberTitle', 'off', 'Position', [100 100 1000 600]);
tiledlayout(2,2);

sp1 = nexttile; title('Speed (km/h)'); grid on;
sp2 = nexttile; title('Throttle (%)'); grid on;
sp3 = nexttile; title('Brake (%)'); grid on;
sp4 = nexttile; title('RPM'); grid on;

% Initialize animated lines for live plotting
a1 = animatedline(sp1, 'Color', 'b');
a2 = animatedline(sp2, 'Color', 'g');
a3 = animatedline(sp3, 'Color', 'r');
a4 = animatedline(sp4, 'Color', 'm');

xlabel(sp1, 'Time (s)');
xlabel(sp2, 'Time (s)');
xlabel(sp3, 'Time (s)');
xlabel(sp4, 'Time (s)');

% Time reference
t0 = datetime('now');

while ishandle(fig)
    if ch.MessagesAvailable > 0
        msg = receive(ch, 1);
        nowTime = datetime('now');
        dt = seconds(nowTime - lastReceiveTime);

        % Detect gap between drivers (1.5 sec)
        if dt > 1.5 && ~isempty(log_all)
            disp(['--- Logging complete for Driver ', driver_numbers{driverIdx}, ' ---']);
            driverLogs{end+1} = log_all;
            log_all = table();
            driverIdx = driverIdx + 1;

            % Clear live plots for next driver
            clearpoints(a1); clearpoints(a2); clearpoints(a3); clearpoints(a4);
            if driverIdx > length(driver_numbers)
                disp('--- All drivers logged. Exiting. ---');
                break;
            end
        end

        data = msg.Data;
        if numel(data) >= 6
            speed = double(data(1));
            throttle = double(data(2));
            brake = double(data(3));
            rpm = double(bitshift(data(5), 8) + data(6));
            timestamp = nowTime;
            t_rel = seconds(timestamp - t0);

            % Append new row to table
            log_all = [log_all; table(timestamp, speed, throttle, brake, rpm)];

            % Update live plots
            addpoints(a1, t_rel, speed);
            addpoints(a2, t_rel, throttle);
            addpoints(a3, t_rel, brake);
            addpoints(a4, t_rel, rpm);
            drawnow limitrate;
        end

        lastReceiveTime = nowTime;
    else
        % Timeout check
        if seconds(datetime('now') - lastReceiveTime) > 5
            disp('--- No data received for 5 seconds. Exiting telemetry logger. ---');
            if ~isempty(log_all)
                driverLogs{end+1} = log_all;
            end
            break;
        end
        pause(0.05);
    end
end

% Cleanup
stop(ch);
delete(ch);
clear ch;

% Save logs
for i = 1:length(driverLogs)
    filename = sprintf('driver_%s_telemetry.csv', driver_numbers{i});
    writetable(driverLogs{i}, filename);
    disp(['Saved: ', filename]);
end
