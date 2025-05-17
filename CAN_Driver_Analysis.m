clc; clear;

% Get list of telemetry files in current folder
files = dir('driver_*_telemetry.csv');

% Extract driver numbers from filenames
driver_nums = regexp({files.name}, 'driver_(\d+)_telemetry.csv', 'tokens');
driver_nums = [driver_nums{:}];
driver_nums = cellfun(@(c) c{1}, driver_nums, 'UniformOutput', false);

fprintf('Available drivers:\n');
for i = 1:length(driver_nums)
    fprintf('%d: Driver %s\n', i, driver_nums{i});
end

% Ask user to choose two drivers by number
idx1 = input('Enter index of first driver to compare: ');
idx2 = input('Enter index of second driver to compare: ');

if idx1 < 1 || idx1 > length(driver_nums) || idx2 < 1 || idx2 > length(driver_nums)
    error('Invalid driver selection.');
end

file1 = files(idx1).name;
file2 = files(idx2).name;

fprintf('Loading telemetry for Driver %s and Driver %s...\n', driver_nums{idx1}, driver_nums{idx2});

% Load tables
T1 = readtable(file1);
T2 = readtable(file2);

% Convert timestamp to datetime
T1.timestamp = datetime(T1.timestamp);
T2.timestamp = datetime(T2.timestamp);

% Normalize time to seconds from start
T1.t = seconds(T1.timestamp - T1.timestamp(1));
T2.t = seconds(T2.timestamp - T2.timestamp(1));

% Compute distance (approximate) from speed (km/h) and time (s)
T1.distance = cumtrapz(T1.t, T1.speed / 3.6); % km/h to m/s
T2.distance = cumtrapz(T2.t, T2.speed / 3.6);

% Create common distance vector for interpolation (overlapping range)
common_distance = linspace(max(min(T1.distance), min(T2.distance)), ...
                           min(max(T1.distance), max(T2.distance)), 500);

% Variables to compare
vars = {'speed', 'throttle', 'brake', 'rpm'};

% Helper function to average duplicate x values for interp1
make_unique = @(x, y) unique_with_avg(x, y);

% Interpolate each variable to the common distance
T1_interp = table();
T2_interp = table();

for i = 1:length(vars)
    v = vars{i};
    
    [x1, y1] = make_unique(T1.distance, T1.(v));
    [x2, y2] = make_unique(T2.distance, T2.(v));
    
    T1_interp.(v) = interp1(x1, y1, common_distance, 'linear', 'extrap');
    T2_interp.(v) = interp1(x2, y2, common_distance, 'linear', 'extrap');
end

% Plot comparison
figure('Name', sprintf('Telemetry Comparison: Driver %s vs Driver %s', driver_nums{idx1}, driver_nums{idx2}), ...
       'NumberTitle', 'off');
colors = {'b', 'r'};

for i = 1:length(vars)
    subplot(length(vars),1,i);
    plot(common_distance, T1_interp.(vars{i}), colors{1}, 'LineWidth', 1.5); hold on;
    plot(common_distance, T2_interp.(vars{i}), colors{2}, 'LineWidth', 1.5);
    ylabel(vars{i});
    grid on;
    if i == 1
        title('Driver Telemetry Comparison');
        legend(sprintf('Driver %s', driver_nums{idx1}), sprintf('Driver %s', driver_nums{idx2}), 'Location', 'best');
    end
end
xlabel('Distance (m)');

% Helper function to average duplicate x values
function [xu, yu] = unique_with_avg(x, y)
    [xu, ~, idx] = unique(x);
    yu = accumarray(idx, y, [], @mean);
end
