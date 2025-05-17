function CAN_Simulink_RealTime_Fix()
    mdl = 'F1_Telemetry_Sim';
    new_system(mdl);
    open_system(mdl);

    % Add Inport block for CAN data
    add_block('simulink/Sources/In1', [mdl '/CAN_Data'], 'Position', [30 150 60 170]);

    % Add MATLAB Function block
    add_block('simulink/User-Defined Functions/MATLAB Function', [mdl '/DecodeCAN'], 'Position', [150 140 250 190]);

    % Add Outports for outputs
    add_block('simulink/Sinks/Out1', [mdl '/Speed'], 'Position', [350 90 380 110]);
    add_block('simulink/Sinks/Out1', [mdl '/Throttle'], 'Position', [350 130 380 150]);
    add_block('simulink/Sinks/Out1', [mdl '/Brake'], 'Position', [350 170 380 190]);
    add_block('simulink/Sinks/Out1', [mdl '/RPM'], 'Position', [350 210 380 230]);

    % Connect CAN data input to DecodeCAN block
    add_line(mdl, 'CAN_Data/1', 'DecodeCAN/1');

    % Save model
    save_system(mdl);

    disp('Model created. Now manually edit the MATLAB Function block to define multiple outputs.');
    disp('Then connect the outputs to the Outport blocks manually.');
end
