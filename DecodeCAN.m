function [speed, throttle, brake, rpm] = decodeCAN(data)
    speed = double(data(1));
    throttle = double(data(2));
    brake = double(data(3));
    rpm = double(bitshift(data(5), 8) + data(6));
end
