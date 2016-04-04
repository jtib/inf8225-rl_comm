function [delay, power] = calcDelayPowerPoint(stationaryDistr, powerCost, departureDistr, policy)
% function [delay, power] = calcDelayPowerPoint(stationaryDistr, powerCost, departureDistr, policy)
% Calculates delay-power operating point.
% -------------------------------------------------------------------------
% Input:
%   stationaryDistr  -- stationary distribution
%                           stationaryDistr(s)
%   powerCost       -- power cost
%                           powerCost(s,a)
%   departureDistr  -- departure distribution
%                           departure_distr(f,BEP,z)
%   policy          -- Markov decision policy
%                           policy(s)
% Output:
%   delay          -- expected delay for policy (i.e. expected max(b - f,0))
%   power          -- expected power for policy

load parameters;

% Get power cost in each state for the policy
for s = 1:numStates
    policyPowerCost(s) = powerCost(s,policy(s));
end

% Get expected power
power = sum(policyPowerCost.*stationaryDistr);

% Get BEP, pm, and tx policies
[BEPIdx_p, pmIdx_p, txIdx_p] = separatePolicies(policy);

% Get delay in each state for the policy
for s = [1:numStates]
    [bIdx, hIdx, xIdx] = ind2sub([length(bufferStates),length(channelStates),length(pmStates)],s);
    b = bufferStates(bIdx);
    
    f = [0:txActions(txIdx_p(s))]'; % possible goodputs
    policyDelay(s) =  sum( departureDistr(f+1,BEPIdx_p(s),txIdx_p(s)).*max(b - f,0) ); % expected delay for state s
    
    if sum(departureDistr(f+1,BEPIdx_p(s),txIdx_p(s))) ~= 1
        error('ERROR: does not sum to 1');
    end
end

% Get expected delay for policy
delay = sum(policyDelay.*stationaryDistr);
