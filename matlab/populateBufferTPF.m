function [T_b] = populateBufferTPF(departure_distr)
% function [T_b] = populateBufferTPF(departure_distr)
% -------------------------------------------------------------
% Populate the buffer state transition probability function (TPF):
%
% Inputs (from parameters.m):
%   departure_distr    -- distribution of departures (NOT in parameters.m)
%   arrivalDistr      -- distribution of arrivals
%   bufferStates       -- buffer state set
%   pmStates           -- power management state set
%   BEPActions         -- BEP action set
%   pmActions          -- power management action set
%   txActions          -- transmission action (throughput) set
%   M                  -- maximum number of packet arrivals
%   B                  -- buffer size
%
% Outputs:
%   T_b                 -- buffer TPF:
%                               T_b(b',BEP,y,z,b,x)
%
% NOTE: The buffer transition is independent of the channel state
% given the BEP

load parameters;

tic;

% Initialize to zero
T_b = zeros( length(bufferStates),...
             length(BEPActions),length(pmActions),length(txActions),...
             length(bufferStates),length(pmStates) );

for bIdx = 1:length(bufferStates)
    b = bufferStates(bIdx); % b (current state)
	for BEPIdx = 1:length(BEPActions)
        BEP = BEPActions(BEPIdx);
        for zIdx = 1:length(txActions)
            z = txActions(zIdx);
            for bpIdx = 1:length(bufferStates)
                bp = bufferStates(bpIdx); % b' (next state)
                
                if bp < B       
                    departures = [0:z];
                    arrivals = bp - max([b - departures],0);
                    [inds] = find(arrivals >= 0 & arrivals <= M);
                    if length(inds) == 0
                        continue;
                    end
                    arrivals = arrivals(inds);
                    departures = departures(inds);
                    
                    % Populate for  (x ~= ON or y ~= S_ON) -- departures = 0
                    if bp >= b
                        T_b(bpIdx,BEPIdx,S_OFF,zIdx,bIdx,OFF) = arrivalDistr(arrivals(1)+1);
                        T_b(bpIdx,BEPIdx,S_ON,zIdx,bIdx,OFF) = arrivalDistr(arrivals(1)+1);
                        T_b(bpIdx,BEPIdx,S_OFF,zIdx,bIdx,ON) = arrivalDistr(arrivals(1)+1);
                    end
                    
                    % Populate for (x == ON and y == S_ON)
                    T_b(bpIdx,BEPIdx,S_ON,zIdx,bIdx,ON) = sum( arrivalDistr(arrivals+1)'.*departure_distr(departures+1,BEPIdx,zIdx) );
                elseif bp == B                
                          
                    for departures = [0:z]
                        arrivals = [B - max([b-departures],0):M];
                        [inds] = find(arrivals >= 0 & arrivals <= M);
                        if length(inds) == 0
                            continue;
                        end
                        arrivals = arrivals(inds);
                    
                        % Populate for  (x ~= ON or y ~= S_ON) -- departures = 0
                        if bp >= b & departures == 0
                            T_b(bpIdx,BEPIdx,S_OFF,zIdx,bIdx,OFF) = T_b(bpIdx,BEPIdx,S_OFF,zIdx,bIdx,OFF)+...
                                                                sum(arrivalDistr(arrivals+1));
                            T_b(bpIdx,BEPIdx,S_ON,zIdx,bIdx,OFF) = T_b(bpIdx,BEPIdx,S_ON,zIdx,bIdx,OFF)+...
                                                                sum(arrivalDistr(arrivals+1));
                            T_b(bpIdx,BEPIdx,S_OFF,zIdx,bIdx,ON) = T_b(bpIdx,BEPIdx,S_OFF,zIdx,bIdx,ON)+...
                                                                sum(arrivalDistr(arrivals+1));
                        end
                        
                        % Populate for (x == ON and y == S_ON)
                        T_b(bpIdx,BEPIdx,S_ON,zIdx,bIdx,ON) = T_b(bpIdx,BEPIdx,S_ON,zIdx,bIdx,ON)+...
                                                                sum(arrivalDistr(arrivals+1).*departure_distr(departures+1,BEPIdx,zIdx));
                    end
                end
            end
            
            % sanity check
            for x = pmStates
                for y = pmActions
                    if sum(T_b(:,BEPIdx,x,zIdx,bIdx,y)) < 1 - 1E-12 | sum(T_b(:,BEPIdx,x,zIdx,bIdx,y)) > 1 + 1E-12
                        error('ERROR: buffer transition does not sum to 1'); 
                    end
                end
            end
        end
	end
end
fprintf('populateBufferTPF: elapsed time = %f\n',toc);