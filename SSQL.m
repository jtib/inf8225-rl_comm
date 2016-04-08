function Q = SSQL(T, R, discount_factor, iterations)
% SSQL - Synchronous speedy Q-learning
% Inputs:
% T: Transition probability function
%    T(current state index, current action index, next state index)
% R: Reward matrix
%    R(current state index, current action index)
% discount_factor: Discount factor
% iterations: Number of iterations

% Useful values
numStates = size(T,1);
numActions = size(T,2);

% Initialization
Q0 = (1/(1-discount_factor))*R;
Q_prev = Q0;
Q = Q0;
Q_next = zeros(numStates,numActions);
% Main loop
for k = 1:iterations
   alpha = 1/k;
   for si = 1:numStates % state index
       for ai = 1:numActions % action index
           tmp = T(si,ai,:);
           tmp = reshape(tmp,1,416);
           next_state_index = sum(rand >= cumsum([0, tmp]));
           BM_prev = R(si,ai) + discount_factor*max(Q_prev(next_state_index,:));
           % Empirical Bellman operator
           BM = R(si,ai) + discount_factor*max(Q(next_state_index,:));
           % SQL update rule
           Q_next(si,ai) = Q(si,ai) + alpha*(R(si,ai) - Q(si,ai)) + (1-alpha)*(BM-BM_prev);
           Q_prev = Q;
           Q = Q_next;
       end
   end
end  
end
