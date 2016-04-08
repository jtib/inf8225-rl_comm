function [T_unknown, T_unknown_expand] = populateUnknownTPF(T_h,arrivalDistr)
% function [T_unknown, T_unknown_expand] = populateUnknownTPF(T_h,arrivalDistr)
% -------------------------------------------------------------
% Populate the unknown state transition probability function (TPF):
%
% Inputs:
%   arrivalDistr       -- distribution of arrivals
%   T_h                -- channel state transition probability function
%                               T_h(h',pd_h)
%
% Outputs:
%   T_unknown          -- unknown TPF:
%                               T_unknown(s, pd_s) =
%                               T_h(h',pd_h)*arrivalDistr(b'-pd_b)
%                               *I(x',pd_x)
%
%   T_known_expand     -- unknown TPF:
%                               T_unknown_expand(pd_b,pd_h,pd_x,b',h',x')

% Do not overwrite arrivalDistr argument with arrivalDistr in parameters.mat
tempArrivalDistr = arrivalDistr;
load parameters;
arrivalDistr = tempArrivalDistr;

tic;

% Initialize to zero
numStates = length(bufferStates)*length(channelStates)*length(pmStates);
numActions = length(BEPActions)*length(pmActions)*length(txActions);
T_unknown = zeros( numStates, numStates );
T_unknown_expand = zeros( length(bufferStates), length(channelStates), length(pmStates),...
                          length(bufferStates), length(channelStates), length(pmStates) );


for pd_bIdx = 1:length(bufferStates) % post-decision buffer state
    for pd_hIdx = 1:length(channelStates) % post-decision channel state
        for pd_xIdx = 1:length(pmStates) 
            xpIdx = pd_xIdx; % post-decision pm state is equal to next pm state
            for hpIdx = 1:length(channelStates) % next channel state
                for arrivals = [0:length(arrivalDistr)-1] % packet arrivals
                
                    bpIdx = min(pd_bIdx + arrivals,B); % next buffer state
                                                                 
                    T_unknown_expand(pd_bIdx,pd_hIdx,pd_xIdx,bpIdx,hpIdx,xpIdx) = ...
                            T_h(hpIdx,pd_hIdx)*arrivalDistr(arrivals+1) +...
                            T_unknown_expand(pd_bIdx,pd_hIdx,pd_xIdx,bpIdx,hpIdx,xpIdx);
                end
            end
        end
    end
end
             
T_unknown = reshape(T_unknown_expand,[numStates,numStates]);
for pd_sIdx = 1:numStates
    if sum(T_unknown(pd_sIdx,:))  < 1 - 1E-12 | sum(T_unknown(pd_sIdx,:)) > 1 + 1E-12
        error('ERROR: The state TPF does not sum to 1');
    end
end

fprintf('populate unknown TPF (from post-decision state to next state): elapsed time = %f\n',toc);