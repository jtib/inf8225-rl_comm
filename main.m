%load parameters;

initStateON = sub2ind([length(bufferStates),length(channelStates),length(pmStates)], 1,1,ON);
initStateOFF = sub2ind([length(bufferStates),length(channelStates),length(pmStates)], 1,1,OFF);

if skipPopulate == 0
	% Get departure distribution
	[departureDistr] = populateDepartureDistr;
	
	% Define cost function
	[bufferCost, expGoodput] = populateBufferCost(arrivalDistr,departureDistr); % arrivalDistr NEEDS TO BE TESTED
	[powerCost, txPower] = populatePowerCost;
	[cost,cost_expand] = populateCost(bufferCost, powerCost, lambda);
	
	% Define transition probability function
	[T_b] = populateBufferTPF(departureDistr);
	[T_h] = populateChannelTPF;
	[T_x] = populatePowerManageTPF(1.0);
	[T,T_expand] = populateStateTPF(T_b,T_h,T_x);
	clear T_expand;
end

% Compute policy using conventional value iteration
% tic; [p, V, Q, iter] = valueIter(T,-cost,discount_factor); toc;
% tic; [p, V, Q, iter] = policy_iteration(T, -cost, discount_factor, 0); toc;
[p, V, Q, lambda, iter] = constrainedPolicyIter(T,...
                                                -reshape(powerCost,[numStates,numActions]),... % Benefit (objective)
                                                reshape(bufferCost,[numStates,numActions]),... % Constraint
                                                cost_constraint,...
                                                initStateON,...
                                                discount_factor,...
                                                lo,...
                                                hi);
[cost,cost_expand] = populateCost(bufferCost, powerCost, lambda(end));
[BEPIdx_p, pmIdx_p, txIdx_p] = separatePolicies(p);

% Populate the afterstate value function
V_expand = reshape(V,[length(bufferStates),length(channelStates),length(pmStates)]);
[afterstateV] = calcAfterstateValueFunction( arrivalDistr,departureDistr,T_h,V_expand );

% Find stationary distribution
[newT, newR, stationaryDistr] = calcStationaryDistr(p, T, cost, initStateON); % The stationary distribution depends on starting in the ON or OFF state

% Calculate delay-power operating point
powCost = reshape(powerCost,[numStates,numActions]);
[holdingCost, overflowCost, delay, power] = calcOperatingPoint(stationaryDistr, powCost, departureDistr, p)