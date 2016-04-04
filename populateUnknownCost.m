function [unknownCost, unknownCost_expand] = populateUnknownCost(lambda,arrivalDistr)
% function [unknownCost, unknownCost_expand] = populateUnknownCost(lambda,arrivalDistr)
% -------------------------------------------------------------
% Populate the known cost function:
%
% Inputs:
%   lambda             -- lagrange multiplier
%   arrivalDistr       -- distribution of arrivals
%
% Outputs:
%   unknownCost          -- unknown cost:
%                               unknownCost(pd_s)
%   unknownCost_expand   -- unknown cost expanded:
%                               unknownCost_expand(pd_b,pd_h,pd_x)

% Don't erase the argument lambda with lambda in parameters.mat
% Don't erase the argument arrivalDistr with arrivalDistr in parameters.mat
tempLambda = lambda;
tempArrivalDistr = arrivalDistr;
load parameters; 
lambda = tempLambda;
arrivalDistr = tempArrivalDistr;

tic;

overflowCost = zeros(length(bufferStates),length(channelStates),length(pmStates));
for pd_bIdx = 1:length(bufferStates)
    for pd_hIdx = 1:length(channelStates)
        for pd_xIdx = 1:length(pmStates)
            for arrivals = [0:M]
                overflows = max(pd_bIdx + arrivals - B, 0);                
                overflowCost(pd_bIdx,pd_hIdx,pd_xIdx) = overflowCost(pd_bIdx,pd_hIdx,pd_xIdx)+...
                        arrivalDistr(arrivals+1)*( overflows/B )*(discount_factor/(1-discount_factor));
            end
        end
    end
end

unknownCost_expand = lambda*overflowCost;
unknownCost = unknownCost_expand(:);

fprintf('populate unknown cost (from post-decision state to next state): elapsed time = %f\n',toc);