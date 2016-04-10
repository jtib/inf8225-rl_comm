function Q = fast_qlearning(T, R, discount_factor, iterations)
% Fast Q-learning

fprintf('Fast Q-learning\n');

% Useful values
numStates = size(T,1);
numActions = size(T,2);

% Initialization
Q0 = (1/(1-discount_factor))*R;
Q = Q0;
%delta = zeros(1,iterations);
k = 2;
done = false;
change_track = 0;
phi = zeros(1,iterations);
phi(1) = 1;
change = zeros(numStates,numActions);
lprime = zeros(numStates,numActions);
V = max(Q,[],2);
lambda = 0.1;

% Main loop
while ~done
    alpha = 1/k;
    for si = 1:numStates % state index
        for ai = 1:numActions % action index
            nsi = sum(rand >= cumsum([0, reshape(T(si,ai,:),1,numStates)])); % next state index
            V_next = max(Q,[],2);
            r = R(si,ai);
            % Global update
            % Local update for all actions
            Q(nsi,:) = Q(nsi,:) + alpha*(change_track - change(nsi,:)).*lprime(nsi,:);
            change(si,:) = change_track;
            % Post-local update
            e_prime = r + discount_factor*V_next(nsi) - Q(si,ai);
            e = r + discount_factor*V_next(nsi) - V(si);
            phi(k) = discount_factor*lambda*phi(k-1);
            change_track = change_track + e*phi(k);
            % Local update
            Q(si,ai) = Q(si,ai) + alpha*(change_track - change(si,ai))*lprime(si,ai) + alpha*e_prime;
            change(si,ai) = change_track;
            lprime(si,ai) = lprime(si,ai) + 1/phi(k);
            V = V_next;
            V = V_next;
        end
    end
    done = (k > iterations) 
    k = k+1
end

