function [holdingCost, overflowCost, delay, power] = calcOperatingPoint(stationaryDistr, powCost, departureDistr, policy)
% function [holdingCost, overflowCost, delay, power] = calcOperatingPoint(stationaryDistr, powerCost, departureDistr, policy)
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
%   holdingCost     -- expected holding cost for policy (i.e. max(b-f,0))
%   overflowCost    -- expected overflow cost for policy (i.e. discount/(1-discount)*(max(b-f,0)+l-B]))
%   delay           -- expected delay for policy (i.e. holding cost + overflow cost)
%   power           -- expected power for policy

load parameters;

% Get power cost in each state for the policy
policyPowerCost = zeros(1,numStates);
for s = 1:numStates
    policyPowerCost(s) = powCost(s,policy(s));
end

% Get holding cost, overflow cost, and delay in each state for the policy
policyHoldingCost = zeros(1,numStates);
policyOverflowCost = zeros(1,numStates);
policyDelay = zeros(1,numStates);
[BEPIdx_p, pmIdx_p, txIdx_p] = separatePolicies(policy); % Get BEP, pm, and tx policies
for s = [1:numStates]
    [bIdx, hIdx, xIdx] = ind2sub([length(bufferStates),length(channelStates),length(pmStates)],s);
    b = bufferStates(bIdx);
    
    f = [0:txActions(txIdx_p(s))]'; % possible goodputs
    policyHoldingCost(s) =  sum( departureDistr(f+1,BEPIdx_p(s),txIdx_p(s)).*max(b - f,0) ); % expected delay for state s
    
    for arrival = [0:M]
        policyOverflowCost(s) = policyOverflowCost(s)+...
            arrivalDistr(arrival+1)*sum( departureDistr(f+1,BEPIdx_p(s),txIdx_p(s)).*max( max([b-f],0) + arrival - B, 0) );
    end
    
    policyDelay(s) = policyHoldingCost(s) + policyOverflowCost(s); % Equivalent delay for infinite sized buffer
    
    if sum(departureDistr(f+1,BEPIdx_p(s),txIdx_p(s))) ~= 1
        error('ERROR: does not sum to 1');
    end
end

% Get expected holding cost for policy
holdingCost = sum(policyHoldingCost.*stationaryDistr);      % expected holding cost
overflowCost = sum(policyOverflowCost.*stationaryDistr);    % expected overflow cost
delay = sum(policyDelay.*stationaryDistr);                  % expected delay
power = sum(policyPowerCost.*stationaryDistr);              % expected power
