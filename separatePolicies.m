function [BEPIdx_p, pmIdx_p, txIdx_p] = separatePolicies(p)
% function [BEPIdx_p, pmIdx_p, txIdx_p] = separatePolicies(p)
% ------------------------------------------------------------
% Separate the policy a = p(s) into separate policies for BEP, y, and z,
% Where a = (BEP,y,z) and s = (b,h,x).
%
% Inputs (from parameters.m):
%   p                  -- the policy a = p(s) (NOT in parameters.m)
%   bufferStates       -- buffer state set
%   channelStates      -- channel state set
%   pmStates           -- power management state set
%   BEPActions         -- BEP action set
%   pmActions          -- power management action set
%   txActions          -- transmission action (throughput) set
%   numStates          -- number of states
%
% Outputs:
%   BEPIdx_p           -- BEP policy: BEPIdx_p(b,h,x)
%   pmIdx_p            -- pm policy (y): pmIdx_p(b,h,x)
%   txIdx_p            -- tx policy (x): txIdx_p(b,h,x)

load parameters;

p_expand = reshape(p,[length(bufferStates),length(channelStates),length(pmStates)]);
for sIdx = 1:numStates
    [bIdx, hIdx, xIdx] = ind2sub([length(bufferStates),length(channelStates),length(pmStates)], sIdx);
    aIdx = p_expand(bIdx,hIdx,xIdx);
    [BEPIdx_p(bIdx,hIdx,xIdx), pmIdx_p(bIdx,hIdx,xIdx), txIdx_p(bIdx,hIdx,xIdx)] =...
        ind2sub([length(BEPActions),length(pmActions),length(txActions)],aIdx);
end