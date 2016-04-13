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
fprintf('Populating cost\n');
[cost,cost_expand] = populateCost(bufferCost, powerCost, lambda(end));
fprintf('Separating policies\n');
[BEPIdx_p, pmIdx_p, txIdx_p] = separatePolicies(p);
% Compute using fast Q-learning
% tic; [p3,V3,Q3,iter3,delta3] = fast_qlearning(T, -cost, discount_factor,10); toc;
% Compute using classic Q-learning
tic; [p3, V3, Q3, iter3, delta3] = classic_qlearning(T, -cost, discount_factor, 10000); t3 = toc;
% Populate the afterstate value function
V_expand = reshape(V,[length(bufferStates),length(channelStates),length(pmStates)]);
[afterstateV] = calcAfterstateValueFunction( arrivalDistr,departureDistr,T_h,V_expand );

% Find stationary distribution
[newT, newR, stationaryDistr] = calcStationaryDistr(p, T, cost, initStateON); % The stationary distribution depends on starting in the ON or OFF state

% Calculate delay-power operating point
powCost = reshape(powerCost,[numStates,numActions]);
[holdingCost, overflowCost, delay, power] = calcOperatingPoint(stationaryDistr, powCost, departureDistr, p)

% Plotting deltas for comparison (indicative, not sole criterion for efficiency)
figure(1)
subplot(2,1,1)
plot(1:iter0,delta0);
title('Delta for value iteration');
subplot(2,1,2)
plot(1:iter1,delta1);
title('Delta for enhanced policy iteration');
figure(2)
subplot(3,1,1)
plot(1:iter,delta);
title('Delta for constrained policy iteration');
subplot(3,1,2)
plot(1:iter2,delta2);
title('Delta for synchronous speedy Q-learning');
subplot(3,1,3)
plot(2:iter3,delta3(2:end));
title('Delta for classic Q-learning');


%print('-f1','deltas','-djpeg90');
