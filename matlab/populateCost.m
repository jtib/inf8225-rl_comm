function [cost, cost_expand] = populateCost(bufferCost, powerCost, lambda)
% function [cost, cost_expand] = populateCost(bufferCost, powerCost)
% -------------------------------------------------------------
% Populate the expected cost defined as:
%
% cost = powerCost + lambda*bufferCost
%
% Inputs:
%   bufferCost          -- buffer cost
%   powerCost           -- power cost (watts)
%   lambda              -- weight
%
% Outputs:
%   cost                -- cost
%                               cost(s,a)
%   cost_expand         -- cost_expand:
%                               cost_expand(b,h,x,BEP,y,z)
%
%   WHERE: s = (b,h,x) and a = (BEP,y,z)

load parameters;

tic;

cost_expand = powerCost + lambda*bufferCost;

cost = reshape(cost_expand,[numStates,numActions]);

fprintf('populateCost: elapsed time = %f \n',toc);