% Setup CAN channel
ch = canChannel('Vector', 'Virtual 1', 1);
configBusSpeed(ch, 500000);
start(ch);

disp("Receiving telemetry... Press Ctrl+C to stop.");

% Initialize data storage
t = [];
speed_vals = [];
throttle_vals = [];
brake_vals = [];
rpm_vals = [];

startTime = datetime('now');

fig = figure('Name', 'Real-Time F1 Telemetry', 'NumberTitle', 'off');
figure(fig);

subplot(4,1,1);
h1 = plot(nan, nan, 'b'); ylabel('Speed (km/h)'); title('Vehicle Speed'); grid on;

subplot(4,1,2);
h2 = plot(nan, nan, 'g'); ylabel('Throttle (%)'); title('Throttle'); grid on;

subplot(4,1,3);
h3 = plot(nan, nan, 'r'); ylabel('Brake (%)'); title('Brake'); grid on;

subplot(4,1,4);
h4 = plot(nan, nan, 'k'); ylabel('RPM'); xlabel('Time (s)'); title('RPM'); grid on;

xlim_window = 30;  % seconds

while ishandle(fig) % Run until figure is closed
    if ch.MessagesAvailable > 0
        msg = receive(ch, 1);
        data = msg.Data;

        if numel(data) >= 6
            speed = double(data(1));
            throttle = double(data(2));
            brake = double(data(3));
            rpm = double(bitshift(data(5), 8) + data(6));
            elapsed = seconds(datetime('now') - startTime);

            % Append data
            t(end+1) = elapsed;
            speed_vals(end+1) = speed;
            throttle_vals(end+1) = throttle;
            brake_vals(end+1) = brake;
            rpm_vals(end+1) = rpm;

            % Filter data for plotting window
            idx = t > (elapsed - xlim_window);
            t_plot = t(idx);

            set(h1, 'XData', t_plot, 'YData', speed_vals(idx));
            set(h2, 'XData', t_plot, 'YData', throttle_vals(idx));
            set(h3, 'XData', t_plot, 'YData', brake_vals(idx));
            set(h4, 'XData', t_plot, 'YData', rpm_vals(idx));

            for ax = 1:4
                subplot(4,1,ax);
                xlim([max(0, elapsed - xlim_window), elapsed]);
            end

            drawnow; % Force plot update

            fprintf('Speed: %3d | Throttle: %3d | Brake: %3d | RPM: %5d\n', ...
                speed, throttle, brake, rpm);
        end
    else
        pause(0.05);
    end
end

stop(ch);
delete(ch);
clear ch;
