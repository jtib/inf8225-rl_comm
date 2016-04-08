function [policyT, policyR, stationaryDistr] = calcStationaryDistr(policy, T, R, initState)
% function [policyT, policyR, stationaryDistr] = calcStationaryDistr(policy, T)
% Calculates the stationary distribution for a given transition probability
% function and policy, for a specific initial state.
% -------------------------------------------------------------------------
% Input:
%   policy      -- Markov decision policy
%   T           -- probability transition function T(s,a,s')
%   R           -- reward function R(s,a)
%   initState   -- initial state s
% Output:
%   policyT            -- probability transition function given the stationary policy
%                          newT(s,s') = T(s,policy(s),s')
%   policyR            -- reward function newR(s) = R
%   stationaryDistr    -- stationary distribution

numStates = size(T,1);
numActions = size(T,2);

policyT = [];
for si = 1:numStates
    policyT(si,:) = squeeze( T(si,policy(si),:) )';
    policyR(si) = R(si,policy(si));
end

stationaryDistr = policyT^64000;

stationaryDistr = stationaryDistr(initState,:);