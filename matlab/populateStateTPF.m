function [T,T_expand] = populateStateTPF(T_b,T_h,T_x)
% function [T,T_expand] = populateStateTPF(T_b,T_h,T_x)
% -------------------------------------------------------------
% Populate the buffer state transition probability function (TPF):
%
% Inputs (from parameters.m):
%   T_b                -- buffer TPF (NOT in parameters.m)
%   T_h                -- channel TPF (NOT in parameters.m)
%   T_x                -- power management TPF (NOT in parameters.m)
%   bufferStates       -- buffer state set
%   channelStates      -- channel state set
%   pmStates           -- power management state set
%   BEPActions         -- BEP action set
%   pmActions          -- power management action set
%   txActions          -- transmission action (throughput) set
%   M                  -- maximum number of packet arrivals
%   B                  -- buffer size
%
% Outputs:
%   T                  -- state TPF:
%                               T(s,a,s')
%   T_expand           -- state TPF:
%                               T(b,h,x,BEP,y,z,b',h',x')
%
%   WHERE: s = (b,h,x) and a = (BEP,y,z) and s' = (b',h',x')

load parameters;

tic;

% Initialize to zero
numStates = length(bufferStates)*length(channelStates)*length(pmStates);
numActions = length(BEPActions)*length(pmActions)*length(txActions);
T = zeros( numStates, numActions, numStates );
T_expand = zeros( length(bufferStates), length(channelStates), length(pmStates),...
                 length(BEPActions), length(pmActions), length(txActions),...
                 length(bufferStates), length(channelStates), length(pmStates) );
             
for bIdx = 1:length(bufferStates)
    for xIdx = 1:length(pmStates)
        for BEPIdx = 1:length(BEPActions)
            for yIdx = 1:length(pmActions)
                for zIdx = 1:length(txActions)
                    for bpIdx = 1:length(bufferStates)
                        for xpIdx = 1:length(pmStates)
                            T_expand(bIdx,:,xIdx,BEPIdx,yIdx,zIdx,bpIdx,:,xpIdx) = ...
                                T_b(bpIdx,BEPIdx,yIdx,zIdx,bIdx,xIdx)*T_x(xpIdx,yIdx,xIdx);
                        end
                    end
                end
            end
        end
    end
end
         
for hIdx = 1:length(channelStates)
    for hpIdx = 1:length(channelStates)
        T_expand(:,hIdx,:,:,:,:,:,hpIdx,:) = ...
            T_expand(:,hIdx,:,:,:,:,:,hpIdx,:)*T_h(hpIdx,hIdx);
    end
end

T = reshape(T_expand,[numStates,numActions,numStates]);

% sanity check
for aIdx = 1:numActions
    for sIdx = 1:numStates
		if sum(T(sIdx,aIdx,:)) < 1 - 1E-12 | sum(T(sIdx,aIdx,:)) > 1 + 1E-12
            error('ERROR: The state TPF does not sum to 1');
		end
    end
end

fprintf('populateStateTPF elapsed time = %f\n',toc);