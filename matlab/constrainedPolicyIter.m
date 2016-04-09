function [p, V, Q, lambda, iter, delta, err] = constrainedPolicyIter(T,benefit,cost,cost_constraint,initState,discount_factor,lo,hi)
% function [p, V, Q, lambda, iter, err] = constrainedValueIter(T,benefit,cost,cost_constraint,initState,discount_factor,lo,hi)
% -----------------------------------------------------------------
% Perform constrained value iteration for problem of the form
%   max(discounted average benefit),
%   s.t. discounted average cost < cost_constraint/(1-discount_factor)
%
%   Solved by finding lambda and maximizing: benefit - lambda*cost
%
% Inputs:
%	T               -- The transition probability function
%		                T(s, a, s')
%   benefit         -- The benefit (the quantity to be maximized)
%                       benefit(s,a)
%   cost            -- The cost (the cost that must satisfy the constraint)
%                       cost(s, a)
%   cost_constraint -- Constraint on the discounted average cost
%   initState       -- Initial state for computing stationary distribution
%	discount_factor -- A real number in [0,1)
%   lo              -- Lower bound on lambda for bisection search
%   hi              -- Upper bound on lambda for bisection search
%
% Outputs:
%	p               -- The optimal policy
%		                optimal action index = p(current state index)
%	V               -- The optimal state-value function
%		                V(current state index)
%	Q               -- The optimal action-value function
%		                Q(current state index, current action index)
%   lambda          -- Values of lambda at each iteration
%                       lambda(iter)
%   iter            -- Number of iterations to meet constraint
%   err             -- error message (err = -1 if constraint cannot be satisfied)
% sanity check -- check if constraint is valid

fprintf('Constrained policy iteration\n');

if cost_constraint < min(cost(:)) | cost_constraint > max(cost(:))
    fprintf('min\t\tconstraint\t\tmax\n')
    fprintf('%f\t%f\t%f\n',min(cost(:)),cost_constraint,max(cost(:)));
    disp('WARNING: cost_constraint cannot be satisfied');
    
    err = -1;
    p = [];
    V = [];
    Q = [];
    iter = [];
end
err = 0;
  
numStates = size(benefit,1);
numActions = size(benefit,2);

% iter = 1;
% lambda = 0.1;
% delta = 100;
% p = ones(numStates,1);
% while iter < 30 & delta > 1e-3
%     oldp = p;
%     R = benefit - lambda(iter)*cost;
%     [p, V, Q, totIter] = policy_iteration(T, R, discount_factor, 0, oldp);
% 
% 	% Update lambda
% 	[newT, newR, stationaryDistr] = calcStationaryDistr(p, T, R, initState);
% 
%     %%%%%%%%%%%%%%%%%%%%%%%%
% %     for s = 1:numStates
% %         policyCost(s) = cost(s,p(s));
% %     end
% %     avgCost2(iter) = sum(policyCost.*stationaryDistr);
% 	%%%%%%%%%%%%%%%%%%%%%%%%
%     
%     policyCost = value_determination(p, T, cost, discount_factor);
% 	avgCost(iter) = sum(policyCost.*stationaryDistr');
% 	lambda(iter+1) = max( lambda(iter) + (1/iter^0.7)*(avgCost(iter) - cost_constraint/(1-discount_factor)), 0 );
%     delta(iter) = abs(lambda(iter+1) - lambda(iter));
%     
%     cost_error = avgCost - cost_constraint/(1-discount_factor)
%     lambda
%     delta
% 
%     iter = iter + 1;
% end
% disp('')

discounted_cost_constraint = cost_constraint/(1 - discount_factor);

mid = lo + (hi-lo)/2;       % initial mid value of lamda for bisection search
bisection_tolerance = 1e-5; % lambda error tolerance for bisection search
error_tolerance = 5;        % cost error tolerance (percent) for bisection search
p = ones(numStates,1);
done = 0;
iter = 1;
while ~done
    oldp = p;
        
    lambda(iter) = mid(iter);
    R = benefit - lambda(iter)*cost;
    [p, V, Q, totIter] = policy_iteration(T, R, discount_factor, 0, oldp);

	% Update lambda
	[newT, newR, stationaryDistr] = calcStationaryDistr(p, T, R, initState);

    %%%%%%%%%%%%%%%%%%%%%%%%
%     for s = 1:numStates
%         policyCost(s) = cost(s,p(s));
%     end
%     avgCost2(iter) = sum(policyCost.*stationaryDistr);
	%%%%%%%%%%%%%%%%%%%%%%%%
    
    policyCost = value_determination(p, T, cost, discount_factor);
	avgCost(iter) = sum(policyCost.*stationaryDistr'); % discounted average cost
	
    if avgCost(iter) <= discounted_cost_constraint % lambda is too large
        hi(iter+1) = mid(iter);
        lo(iter+1) = lo(iter);
    else % lambda is too small
        lo(iter+1) = mid(iter);
        hi(iter+1) = hi(iter);
    end
    
    mid(iter+1) = lo(iter+1) + (hi(iter+1)-lo(iter+1))/2;
    lambda(iter+1) = mid(iter+1);
    delta(iter) = abs(lambda(iter+1) - lambda(iter));
    
    cost_error = avgCost - discounted_cost_constraint;
    
    cost_error_perc = abs(cost_error/discounted_cost_constraint)*100
    lambda

    if ( abs(hi(iter) - lo(iter)) <= 2*bisection_tolerance ) | ( cost_error_perc(iter) < error_tolerance  )
        done = 1;
    else
        iter = iter + 1;
    end
    
    pause(1e-1); % Enables us to easily stop execution with CTRL-c
end
disp('')
% figure; plot(hi,'rx-'); hold on; plot(lo,'bo-');hold on; plot(mid,'gd-')


