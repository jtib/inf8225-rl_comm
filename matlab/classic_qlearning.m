function [p,V,Q,iter,delta] = classic_qlearning(T, R, discount_factor, iterations)

if nargin < 4
    iterations = 10000;
end

fprintf('Classic Q-learning\n');

% Useful values
numStates = size(T,1);
numActions = size(T,2);

% Initialization
Q_prev = zeros(numStates, numActions);
Q = zeros(numStates, numActions);
delta = zeros(1,iterations);
k = 1;
done = false;
si = randi([1,numStates]);

while ~done
    alpha = 1/k;    
    % choosing an action
    [~,ai] = max(Q(si,:));
    % next state index
    nsi = sum(rand >= cumsum([0, reshape(T(si,ai,:),1,numStates)]));
    r = R(si,ai);
    % Updating Q
    Q(si,ai) = Q(si,ai) + alpha*(r + discount_factor*max(Q(nsi,:)) - Q(si,ai));
    si = nsi;
    delta(k) = max(abs(Q(:) - Q_prev(:)));
    done = (k > iterations | approxeq(Q, Q_prev, 1e-5));
    Q_prev = Q;
    k = k+1;
end
[V,p] = max(Q,[],2);
iter = k-1;
delta = delta(1:iter);
end