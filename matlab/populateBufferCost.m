function [bufferCost, expGoodput, holdingCost, overflowCost] = populateBufferCost(arrivalDistr,departureDistr)
% function [bufferCost, expGoodput, holdingCost, overflowCost] = populateBufferCost(arrivalDistr.departureDistr)
% -------------------------------------------------------------
% Populate the expected buffer cost defined as:
%
% bufferCost = holding cost + overflow cost
%
%
% Inputs:
%   arrivalDistr       -- arrival distribution
%   departureDistr     -- departure distribution
%   
% Outputs:
%   bufferCost         -- expected buffer cost:
%                               bufferCost(b,h,x,BEP,y,z)
%   expGoodput         -- expected goodput
%                               expGoodput(BEP,z)
%   holdingCost        -- holding cost
%                               holdingCost(b,h,x,BEP,y,z)
%   overflowCost       -- overflow cost
%                               overflowCost(b,h,x,BEP,y,z)
%   
% NOTE: bufferCost does not actually depend on h.

% Don't overwrite arrivalDistr in the argument with arrivalDistr in parameters.mat
tempArrivalDistr = arrivalDistr;
load parameters;
arrivalDistr = tempArrivalDistr;

tic;

holdingCost = zeros(length(bufferStates),length(channelStates),length(pmStates),...
                     length(BEPActions),length(pmActions),length(txActions));
overflowCost = zeros(length(bufferStates),length(channelStates),length(pmStates),...
                     length(BEPActions),length(pmActions),length(txActions));
bufferCost = zeros(length(bufferStates),length(channelStates),length(pmStates),...
                     length(BEPActions),length(pmActions),length(txActions));
expGoodput = zeros(length(BEPActions),length(txActions));

% Populate for  (x ~= ON or y ~= S_ON)
for b = bufferStates
    bIdx = find(bufferStates == b);
    arrivals = [0:M];
    holdingCost(bIdx,:,:,:,:,:) = b/B;
    overflowCost(bIdx,:,:,:,:,:) = (discount_factor/(1-discount_factor))*sum(arrivalDistr.*max((b + arrivals - B),0))/B;
    bufferCost(bIdx,:,:,:,:,:) = holdingCost(bIdx,:,:,:,:,:) + overflowCost(bIdx,:,:,:,:,:);
end

% Populate for (x == ON and y == S_ON)
for bIdx = 1:length(bufferStates)
    b = bufferStates(bIdx);
    for hIdx = 1:length(channelStates)
        h = channelStates(hIdx);
        for BEPIdx = 1:length(BEPActions)
            BEP = BEPActions(BEPIdx);
            for zIdx = 1:length(txActions)
                z = txActions(zIdx);                          
                goodput = [0:z]';
                
                holdingCost(bIdx,hIdx,ON,BEPIdx,S_ON,zIdx) = ...
                    sum( departureDistr(goodput+1,BEPIdx,zIdx).*( (max([b - goodput],0))/B ) );
                
                overflowCost(bIdx,hIdx,ON,BEPIdx,S_ON,zIdx) = 0;
                for arrival = [0:M]
                    overflowCost(bIdx,hIdx,ON,BEPIdx,S_ON,zIdx) = overflowCost(bIdx,hIdx,ON,BEPIdx,S_ON,zIdx)+...
                        arrivalDistr(arrival+1)*sum( departureDistr(goodput+1,BEPIdx,zIdx).*( max( max([b - goodput],0) + arrival - B, 0 )/B ) )*(discount_factor/(1-discount_factor));
                end
                
                bufferCost(bIdx,hIdx,ON,BEPIdx,S_ON,zIdx) = ...
                    holdingCost(bIdx,hIdx,ON,BEPIdx,S_ON,zIdx) + overflowCost(bIdx,hIdx,ON,BEPIdx,S_ON,zIdx);
            end
        end
    end
end

fprintf('populateBufferCost: elapsed time = %f\n',toc);