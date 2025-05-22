function stopF1UDP_Fix()
    try
        set_param('F1_Telemetry_UDP_Fix', 'SimulationCommand', 'stop');
        fprintf('Simulink model stopped.\n');
    catch
        fprintf('Model already stopped.\n');
    end
    
    try
        udpReceiver = evalin('base', 'udpReceiver');
        if ~isempty(udpReceiver)
            release(udpReceiver);
            fprintf('UDP receiver released.\n');
        end
    catch
        fprintf('No UDP receiver to release.\n');
    end
    
    try
        t = timerfindall;
        if ~isempty(t)
            stop(t);
            delete(t);
            fprintf('Timers stopped and deleted.\n');
        end
    catch
        fprintf('Error stopping timers.\n');
    end
    
    fprintf('Cleanup complete.\n');
end