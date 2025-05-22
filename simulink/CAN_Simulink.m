% Define model name
modelName = 'F1_Telemetry_Sim';

% Close and delete model if it already exists
if bdIsLoaded(modelName)
    bdclose(modelName);
end
if exist([modelName '.slx'], 'file')
    delete([modelName '.slx']);
end

% Create and open new model
new_system(modelName);
open_system(modelName);

% Add Constant block (simulated CAN data)
add_block('simulink/Sources/Constant', [modelName '/CAN_Message'], ...
    'Value', 'uint8([255 99 0 0 43 180 0 0])', ...
    'OutDataTypeStr', 'uint8', ...
    'Position', [100 100 180 140]);

% Add MATLAB Function block
funcBlockPath = [modelName '/DecodeCAN'];
add_block('simulink/User-Defined Functions/MATLAB Function', funcBlockPath, ...
    'Position', [250 100 500 200]);

% Set the function code inside MATLAB Function block properly using Simulink API
open_system(funcBlockPath); % Ensure it's open so the API can access it

% Wait for Simulink to register the new function block
pause(1);

rt = sfroot;
model = rt.find('-isa', 'Simulink.BlockDiagram', 'Name', modelName);
funcBlk = model.find('-isa','Stateflow.EMChart','Path', funcBlockPath);

code = [
    'function [speed, throttle, brake, rpm] = DecodeCAN(data)', newline, ...
    '%#codegen', newline, ...
    'speed = double(data(1));', newline, ...
    'throttle = double(data(2));', newline, ...
    'brake = double(data(3));', newline, ...
    'rpm = double(bitshift(data(5), 8) + data(6));'
];
funcBlk.Script = code;

% Add Display blocks
outputNames = {'speed', 'throttle', 'brake', 'rpm'};
for i = 1:length(outputNames)
    add_block('simulink/Sinks/Display', [modelName '/' outputNames{i} '_Display'], ...
        'Position', [600 60 + 70*(i-1) 650 90 + 70*(i-1)]);
end

% Connect blocks
add_line(modelName, 'CAN_Message/1', 'DecodeCAN/1');
for i = 1:length(outputNames)
    add_line(modelName, ['DecodeCAN/' num2str(i)], [outputNames{i} '_Display/1']);
end

% Save and show
save_system(modelName);
open_system(modelName);
