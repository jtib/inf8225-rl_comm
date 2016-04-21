load parameters;

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
tic; [p0, V0, Q0, iter0, delta0] = valueIter(T,-cost,discount_factor); t0 = toc;
% Compute using policy iteration
tic; [p1, V1, Q1, iter1, delta1] = policy_iteration(T, -cost, discount_factor, 0); t1 = toc;
% Compute using the article's algorithm
tic; [p, V, Q, lambda, iter, delta] = constrainedPolicyIter(T,...
                                                -reshape(powerCost,[numStates,numActions]),... % Benefit (objective)
                                                reshape(bufferCost,[numStates,numActions]),... % Constraint
                                                cost_constraint,...
                                                initStateON,...
                                                discount_factor,...
                                                lo,...
                                                hi);
                                            t = toc;
% Compute using synchronous speedy Q-learning                                            
tic; [p2,V2,Q2,iter2, delta2] = SSQL(T,-cost,discount_factor,10); t2 = toc;
% Compute using classic Q-learning
tic; [p3, V3, Q3, iter3, delta3] = classic_qlearning(T, -cost, discount_factor, 10000); t3 = toc;

% Final useful variables
fprintf('Populating cost\n');
[cost,cost_expand] = populateCost(bufferCost, powerCost, lambda(end));

fprintf('Separating policies\n');
fprintf('Value iteration\n');
[BEPIdx_p0, pmIdx_p0, txIdx_p0] = separatePolicies(p0);
fprintf('Enhanced policy iteration\n');
[BEPIdx_p1, pmIdx_p1, txIdx_p1] = separatePolicies(p1);
fprintf('Constrained policy iteration\n');
[BEPIdx_p, pmIdx_p, txIdx_p] = separatePolicies(p);
fprintf('SSQL\n');
[BEPIdx_p2, pmIdx_p2, txIdx_p2] = separatePolicies(p2);
fprintf('Classic Q-learning\n');
[BEPIdx_p3, pmIdx_p3, txIdx_p3] = separatePolicies(p3);



% Populate the afterstate value function
V_expand = reshape(V,[length(bufferStates),length(channelStates),length(pmStates)]);
[afterstateV] = calcAfterstateValueFunction( arrivalDistr,departureDistr,T_h,V_expand );

V_expand0 = reshape(V0,[length(bufferStates),length(channelStates),length(pmStates)]);
[afterstateV0] = calcAfterstateValueFunction( arrivalDistr,departureDistr,T_h,V_expand0 );

V_expand1 = reshape(V1,[length(bufferStates),length(channelStates),length(pmStates)]);
[afterstateV1] = calcAfterstateValueFunction( arrivalDistr,departureDistr,T_h,V_expand1 );

V_expand2 = reshape(V2,[length(bufferStates),length(channelStates),length(pmStates)]);
[afterstateV2] = calcAfterstateValueFunction( arrivalDistr,departureDistr,T_h,V_expand2 );

V_expand3 = reshape(V3,[length(bufferStates),length(channelStates),length(pmStates)]);
[afterstateV3] = calcAfterstateValueFunction( arrivalDistr,departureDistr,T_h,V_expand3 );


% Find stationary distribution
[newT, newR, stationaryDistr] = calcStationaryDistr(p, T, cost, initStateON); % The stationary distribution depends on starting in the ON or OFF state

[newT0, newR0, stationaryDistr0] = calcStationaryDistr(p0, T, cost, initStateON);

[newT1, newR1, stationaryDistr1] = calcStationaryDistr(p1, T, cost, initStateON);

[newT2, newR2, stationaryDistr2] = calcStationaryDistr(p2, T, cost, initStateON);

[newT3, newR3, stationaryDistr3] = calcStationaryDistr(p3, T, cost, initStateON);

% Calculate delay-power operating point
powCost = reshape(powerCost,[numStates,numActions]);
[holdingCost, overflowCost, delay, power] = calcOperatingPoint(stationaryDistr, powCost, departureDistr, p)

[holdingCost0, overflowCost0, delay0, power0] = calcOperatingPoint(stationaryDistr0, powCost, departureDistr, p0)

[holdingCost1, overflowCost1, delay1, power1] = calcOperatingPoint(stationaryDistr1, powCost, departureDistr, p1)

[holdingCost2, overflowCost2, delay2, power2] = calcOperatingPoint(stationaryDistr2, powCost, departureDistr, p2)

[holdingCost3, overflowCost3, delay3, power3] = calcOperatingPoint(stationaryDistr3, powCost, departureDistr, p3)

