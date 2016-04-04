function [T_known, T_known_expand] = populateKnownTPF(T_x,departure_distr)
% function [T_known, T_known_expand] = populateKnownTPF(T_x,departure_distr)
% -------------------------------------------------------------
% Populate the known state transition probability function (TPF):
%
% Inputs:
%   departure_distr    -- distribution of departures
%   T_x                -- power management TPF
%                               T_x(pd_x,y,x)
%
% Outputs:
%   T_known            -- known TPF:
%                               T_known(s, a, pd_s) =
%                               T_x(pd_x,x,y)*departure_distr(b-pd_b,BEP,z)
%                               *I(pd_h,h)
%
%   T_known_expand     -- known TPF:
%                               T_known_expand(b,h,x,BEP,y,z,pd_b,pd_h,pd_x)

load parameters;

tic;

% Initialize to zero
numStates = length(bufferStates)*length(channelStates)*length(pmStates);
numActions = length(BEPActions)*length(pmActions)*length(txActions);
T_known = zeros( numStates, numActions, numStates );
T_known_expand = zeros( length(bufferStates), length(channelStates), length(pmStates),...
                 length(BEPActions), length(pmActions), length(txActions),...
                 length(bufferStates), length(channelStates), length(pmStates) );

             
for bIdx = 1:length(bufferStates)
    b = bufferStates(bIdx); % b (current state)
	for BEPIdx = 1:length(BEPActions)
        BEP = BEPActions(BEPIdx);
        for zIdx = 1:length(txActions)
            z = txActions(zIdx);
            for hIdx = 1:length(channelStates)
                for departures = [0:z]
                
                    pd_bIdx = max(b - departures,0)+1;
                    pd_b = bufferStates(pd_bIdx); % pd_b (post decision buffer state)
                      
                    pd_hIdx = hIdx;
                    pd_h = channelStates(pd_hIdx);
                                                                
                    % Populate for (x ~= ON or y ~= S_ON)
                    %   NOTE: Non-zero probability occurs only if departures = 0
                    if departures == 0
                        T_known_expand(bIdx,hIdx,OFF,BEPIdx,S_OFF,zIdx,pd_bIdx,pd_hIdx,OFF) = ...
                            T_x(OFF,S_OFF,OFF);
                        T_known_expand(bIdx,hIdx,ON,BEPIdx,S_OFF,zIdx,pd_bIdx,pd_hIdx,OFF) = ...
                            T_x(OFF,S_OFF,ON);
                        T_known_expand(bIdx,hIdx,OFF,BEPIdx,S_ON,zIdx,pd_bIdx,pd_hIdx,ON) = ...
                            T_x(ON,S_ON,OFF);
                    end
                                      
                    % Populate for (x == ON and y == S_ON)
                    % departures = min(zIdx, bIdx-pd_bIdx+1);
                    T_known_expand(bIdx,hIdx,ON,BEPIdx,S_ON,zIdx,pd_bIdx,pd_hIdx,ON) = ...
                            T_x(ON,S_ON,ON)*departure_distr(departures+1,BEPIdx,zIdx) +...
                            T_known_expand(bIdx,hIdx,ON,BEPIdx,S_ON,zIdx,pd_bIdx,pd_hIdx,ON);  
                end
            end
        end
	end
end
             
T_known = reshape(T_known_expand,[numStates,numActions,numStates]);

% Sanity check
for sIdx = 1:numStates
    for aIdx = 1:numActions     
        if sum(T_known(sIdx,aIdx,:))  < 1 - 1E-12 | sum(T_known(sIdx,aIdx,:)) > 1 + 1E-12
            error('ERROR: The state TPF does not sum to 1');
        end
    end
end

fprintf('populate known TPF (from state to post-decision state): elapsed time = %f\n',toc);