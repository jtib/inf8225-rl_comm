function [p, V, PDSV, Q, iter] = PDSvalueIter(T_known,T_unknown,R_known,R_unknown,discount_factor)
% function [p, V, PDSV, Q, iter] = PDSvalueIter(T_known,T_unknown,R_known,R_unknown,discount_factor)
% --------------------------------------------------------
% Inputs:
%	T_known         -- The known transition probability function
%                       T_known(state,action,post-decision state)
%   T_unknown       -- The unknown transition probability function
%                       T_unknown(post-decision state, next state)
%	R_known         -- The known reward function
%                       R_known(state,action)
%   R_unknown       -- The unknown reward function
%                       R_unknown(post-decision state)
%	discount_factor -- a real number in [0,1)
%
% Outputs:
%	p       -- The optimal policy
%		        optimal action index = p(current state)
%	V       -- The optimal state-value function
%		        V(current state)
%   PDSV    -- The post-decision state-value function
%               V(post-decision state)
%	Q       -- The optimal action-value function
%		        Q(current state index, current action index)
%	iter    -- The number of iterations required to converge

numStates = size(R_known,1);
numActions = size(R_known,2);

V = zeros(numStates,1);
PDSV = V;

delta = 1e9;
thresh = 5e-3;
iter = 0;
numBackups = 0;
while (delta > thresh)
    iter = iter + 1;
    oldV = V;
	
    % Get PDSV from V
    PDSV = R_unknown + discount_factor*T_unknown*oldV;
    
    % Get V from PDSV
    Q = Q_from_V(PDSV,T_known,R_known,1);
    [V, p] = max(Q, [], 2);
    
    numBackups(iter) = numStates*numActions;

    delta(iter) = max(abs(V - oldV));
    
    fprintf('iter = %d; backups = %d; delta = %d;\n', iter, numBackups(iter), delta(iter));
end
fprintf('total backups = %d\n', sum(numBackups));

