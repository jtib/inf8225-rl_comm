function beta = betaSchedule(n)
% Determines the Lagrangian update parameter schedule
%   Note: n in [1, inf]
%         n is number of timesteps passed
%
%   The beta schedule must satisfy the following conditions:
%   (i)     sum( beta(:) ) = infinity
%   (ii)    sum( beta(:).^2) < infinity
%
%   The beta schedule and alpha schedule must satisfy the following
%   joint conditions:
%   (i)     sum( alpha(:).^2 + beta(:).^2 ) < infinity
%   (ii)    lim n -> infinity (beta(n)./alpha(n)) = 0

maxBeta = 2; % 10 is too large, 5 is too large --> multiplier jumps too frequently.
             % 1 is too small --> multiplier does not converge fast enough
minBeta = 0.0005;
beta = max(maxBeta ./ ceil(n),minBeta);