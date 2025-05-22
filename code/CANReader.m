classdef CANReader < matlab.System & matlab.system.mixin.Propagates
    properties
        ChannelName = 'Vector';
        ChannelInterface = 'Virtual 1';
        ChannelId = 1;
        BusSpeed = 500000;
    end
    
    properties(Access = private)
        ch;
    end
    
    methods(Access = protected)
        function setupImpl(obj)
            obj.ch = canChannel(obj.ChannelName, obj.ChannelInterface, obj.ChannelId);
            configBusSpeed(obj.ch, obj.BusSpeed);
            start(obj.ch);
        end
        
        function dataOut = stepImpl(obj)
            dataOut = zeros(1,8,'uint8'); % default empty
            if obj.ch.MessagesAvailable > 0
                msg = receive(obj.ch,1);
                dataOut = msg.Data;
            end
        end
        
        function releaseImpl(obj)
            stop(obj.ch);
            delete(obj.ch);
        end
        
        function num = getNumOutputsImpl(~)
            num = 1;
        end
        
        function outSize = getOutputSizeImpl(~)
            outSize = [1 8];
        end
        
        function outType = getOutputDataTypeImpl(~)
            outType = 'uint8';
        end
        
        function outComplexity = isOutputComplexImpl(~)
            outComplexity = false;
        end
    end
end
