function [Q, TD] = updateQ(Q,alpha,discount_factor,cost,currStateIdx,currActionIdx,nextStateIdx)
% Q-learning update step
% [Q, TD] = updateQ(Q,alpha,discount_factor,cost,currStateIdx,currActionIdx,nextStateIdx)
% --------------------------------------------------
% Input:
%   Q -- initial Q-values
%   alpha -- learning rate
%   discount_factor -- discount factor for long-term optimization
%   cost -- immediate cost
%   currStateIdx -- current state index for the Q-value update
%   currActionIdx -- current action index for the Q-value update
%   nextStateIdx -- next state index for the Q-value update
% Output:
%   Q -- updated Q-values
%   TDerror -- temporal difference error

% determine the minimum Q value for the next state over the possible
% actions
[optAction, optActionIdx] = min( Q(nextStateIdx,:) );

% calculate the temporal-difference error
TD = cost + discount_factor*Q(nextStateIdx,optActionIdx) - Q(currStateIdx,currActionIdx);

% update step
Q(currStateIdx,currActionIdx) = Q(currStateIdx,currActionIdx) + alpha*TD;