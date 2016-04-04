function [kpolicy] = populate_k_policy(k)
% function [k_policy] = populate_k_policy(k)
% This function creates a policy based on the solution in:
%   K. Nahrstedt, W. Yuan, S. Shah, Y. Xue, and K. Chen, "QoS support in
%   multimedia wireless environments," in Multimedia over IP and Wireless
%   Networks, ed. M. van der Schaar and P. Chou, Academic Press, 2007.
%
% The solution waits until there are k packets in the buffer, then wakes up
% and transmits all of them, and then goes back to sleep.
%
% Inputs:
%   k               -- threshold buffer state
%
% Outputs:
%   kpolicy         -- policy based on Klara's solution

load parameters;

for sIdx = 1:numStates
   
    [bIdx, hIdx, xIdx] = ind2sub([length(bufferStates),length(channelStates),length(pmStates)],sIdx);
    
	if bufferStates(bIdx) >= k & pmStates(xIdx) == OFF
        % Wake up
        BEPIdx = 1;
        yIdx = S_ON;
        zIdx = 1;
	elseif bufferStates(bIdx) >= k & pmStates(xIdx) == ON
        % Transmit maximum number of packets possible
        BEPIdx = 1;
        yIdx = S_ON;
        zIdx = min(bufferStates(bIdx),max(txActions))+1;
	elseif bufferStates(bIdx) < k & pmStates(xIdx) == OFF
        % Keep off
        BEPIdx = 1;
        yIdx = S_OFF;
        zIdx = 1;
	elseif bufferStates(bIdx) < k & pmStates(xIdx) == ON
        if bufferStates(sim.bIdx(n-1)) - txActions(sim.zIdx(n-1)) == 0
            % Turn off if the post-decision state in previous
            % period is 0 (i.e. buffer was empty before new arrivals)
            sim.BEPIdx(n) = 1;
            sim.yIdx(n) = S_OFF;
            sim.zIdx(n) = 1;
        else
            % Transmit maximum number of packets possible
            sim.BEPIdx(n) = 1;
            sim.yIdx(n) = S_ON;
            sim.zIdx(n) = min(bufferStates(bIdx),max(txActions))+1;
        end
	end
end