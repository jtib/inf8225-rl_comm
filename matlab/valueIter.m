function [p, V, Q, iter, delta] = valueIter(T,R,discount_factor)
% function [p, V, Q, iter] = valueIter(T,R,discount_factor)
% --------------------------------------------------------
% Inputs:
%	T -- The transition probability function
%		T(current state index, current action index, next state index)
%	R -- The reward function
%		R(current state index, current action index)
%	discount_factor -- a real number in [0,1)
% Outputs:
%	p -- The optimal policy
%		optimal action index = p(current state index)
%	V -- The optimal state-value function
%		V(current state index)
%	Q -- The optimal action-value function
%		Q(current state index, current action index)
%	iter -- The number of iterations required to converge

fprintf('Value iteration\n');

numStates = size(R,1);
numActions = size(R,2);

V = [max(R') / (1 - discount_factor)]'; %-1e9*size(numStates,1);

delta = 1e9;
thresh = 5e-3;
iter = 0;
numBackups = 0;
while (delta > thresh)
    iter = iter + 1;
    oldV = V;
	    
%     numBackups(iter) = 0;
%     for si = 1:numStates
%         for ai = 1:numActions
%             Q(si,ai) = R(si,ai) + discount_factor*sum( squeeze(T(si,ai,:)).*V );
%             numBackups(iter) = numBackups(iter) + 1;
%         end
% 	end
    Q = Q_from_V(oldV,T,R,discount_factor);
    numBackups(iter) = numStates*numActions;
    
    [V, p] = max(Q, [], 2);
    
    delta(iter) = max(abs(V - oldV));
    
    %fprintf('iter = %d; backups = %d; delta = %d;\n', iter, numBackups(iter), delta(iter));
end
fprintf('total backups = %d\n', sum(numBackups));

