% Test_CAN_Connection.m
% Simple test script to verify CAN hardware connectivity

disp('Testing CAN hardware connection...');

% Try to initialize the Vector CAN hardware
try
    % Create a CAN channel
    ch = canChannel('Vector', 'Virtual 1', 1);
    configBusSpeed(ch, 500000);
    
    % Start the CAN channel
    start(ch);
    disp('SUCCESS: CAN hardware initialized and started.');
    
    % Set up a callback for receiving messages
    ch.ReceivedMsgsFcnCount = 1;
    ch.ReceivedMsgsFcn = @testCanCallback;
    
    disp(' ');
    disp('Now listening for CAN messages on Virtual 1 channel...');
    disp('Run your CAN_Send.py script in a separate terminal:');
    disp('   python CAN_Send.py');
    disp(' ');
    disp('Press Ctrl+C to stop listening');
    disp(' ');
    
    % Keep running until user interrupts
    running = true;
    while running
        try
            pause(0.1); % Give time for callbacks to happen
        catch
            running = false;
            disp('Test interrupted by user.');
        end
    end
    
    % Clean up
    stop(ch);
    delete(ch);
    
catch err
    disp(['ERROR: ' err.message]);
    disp(' ');
    disp('Possible causes:');
    disp('1. Vector CAN hardware not connected');
    disp('2. Vector drivers not installed');
    disp('3. Vector CANoe/CANalyzer not running with virtual channel');
    disp('4. Vector license issues');
    disp(' ');
    disp('Solutions:');
    disp('1. Make sure Vector hardware is connected');
    disp('2. Install Vector drivers from https://www.vector.com');
    disp('3. Start Vector CANoe/CANalyzer with virtual channel enabled');
    disp('4. Use F1_Telemetry_Standalone.m for testing without CAN hardware');
end

% Test callback function
function testCanCallback(src, ~)
    try
        % Get the message
        msg = receive(src, 1);
        
        % Display message details
        fprintf('Received CAN message - ID: 0x%X, Length: %d, Data: ', msg.ID, length(msg.Data));
        fprintf('%02X ', msg.Data);
        fprintf('\n');
        
        % Interpret F1 data if it's our expected format
        if msg.ID == hex2dec('123') && length(msg.Data) >= 6
            speed = double(msg.Data(1));
            throttle = double(msg.Data(2));
            brake = double(msg.Data(3));
            gear = double(msg.Data(4));
            rpm = double(bitshift(msg.Data(5), 8) + msg.Data(6));
            
            fprintf('F1 Data - Speed: %d km/h, Throttle: %d%%, Brake: %d%%, Gear: %d, RPM: %d\n', ...
                speed, throttle, brake, gear, rpm);
        end
    catch err
        fprintf('Error in callback: %s\n', err.message);
    end
end
