function [afterstateV] = calcAfterstateValueFunction(arrivalDistr,departureDistr,T_h,V)
% function [afterstate_p, afterstateV] = ...
%         calcAfterstateValueFunction(arrivalDistr,departureDistr,T_h,V)
% -------------------------------------------------------------------------
% Calculate the afterstate value function given the conventional value
% function
%
% Inputs:
%   arrivalDistr        -- arrival distribution
%   departureDistr      -- departure distribution %%% THIS IS NOT NEEDED!
%   T_h                 -- channel TPF
%   V                   -- expanded value function
%                               V(b,h,x)
%
% Outputs:
%   afterstate_V        -- afterstate value function
%
% NOTE: Assumes that the power state transition is deterministic

load parameters;

afterstateV = zeros(length(bufferStates),length(channelStates),length(pmStates));

for after_bIdx = 1:length(bufferStates) % max([b-f],0) - buffer state after departures
    for after_hIdx = 1:length(channelStates) % h - current channel state
        for after_xIdx = 1:length(pmStates) % x' - pm state after transition
            temp = 0;
            for arrivals = [0:M]
                temp = temp + arrivalDistr(arrivals+1)*...
                    sum( T_h(:,after_hIdx).*V(min(after_bIdx+arrivals,B+1),:,after_xIdx)' );
            end
            afterstateV(after_bIdx,after_hIdx,after_xIdx) = temp;
        end
    end
end

% for afterstate_b = bufferStates % max([b - f],0)
%     for afterstate_h = channelStates % h
%         for afterstate_x = pmStates % x'
%             arrivals = [0:length(arrivalDistr)-1];
%             tempV = sum( arrivalDistr.*V(min(afterstate_b + arrivals),afterstate_h
%             
%         end
%     end
% end