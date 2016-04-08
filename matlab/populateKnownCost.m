function [knownCost] = populateKnownCost(lambda,powerCost,holdingCost)
% function [knownCost] = populateKnownCost(lambda,powerCost,holdingCost)
% -------------------------------------------------------------
% Populate the known cost function:
%
% Inputs:
%   lambda             -- lagrange multiplier
%   powerCost          -- power cost
%                               powerCost(s,a)
%   holdingCost        -- holding cost
%                               holdingCost(s,a)
%
% Outputs:
%   knownCost          -- known cost:
%                               knownCost(s,a)

% Don't erase the argument lambda with lambda in parameters.mat
tempLambda = lambda;
load parameters; 
lambda = tempLambda;

knownCost = powerCost + lambda*holdingCost;
