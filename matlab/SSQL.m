function [p,V,Q,iter,delta] = SSQL(T, R, discount_factor, iterations)
% SSQL - Synchronous speedy Q-learning
% Inputs:
% T: Transition probability function
%    T(current state index, current action index, next state index)
% R: Reward matrix
%    R(current state index, current action index)
% discount_factor: Discount factor
% iterations: Number of iterations

if nargin < 4
    iterations = 10;
end

fprintf('Synchronous speedy Q-learning\n');

% Useful values
numStates = size(T,1);
numActions = size(T,2);

% Initialization
Q0 = (1/(1-discount_factor))*R;
Q_prev = Q0;
Q = Q0;
Q_next = zeros(numStates,numActions);
delta = zeros(1,iterations);
k = 1;
done = false;
% Main loop
while ~done
   alpha = 1/k;
   nsis = next_state_indices(numStates,numActions,T);
   for si = 1:numStates % state index
       BM_prev_mat_ai = R(si,:) + discount_factor*max(Q_prev(nsis(si,:),:));
       BM_mat_ai = R(si,:) + discount_factor*max(Q(nsis(si,:),:));
       Q_next(si,:) = Q(si,:) + alpha*(R(si,:) - Q(si,:)) + (1-alpha)*(BM_mat_ai - BM_prev_mat_ai);
       Q_prev = Q;
       Q = Q_next;
   end
   delta(k) = max(abs(Q(:) - Q_prev(:)));
   fprintf('iter = %d; delta = %d;\n', k, delta(k));
   done = (k > iterations | approxeq(Q, Q_prev, 1e-5));
   k = k+1
end
[V,p] = max(Q,[],2);
iter = k-1;
delta = delta(1:iter);
end
