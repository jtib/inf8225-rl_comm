function alpha = alphaSchedule(numVisits)
% Determines the learning rate schedule
%   Note: numVisits in [0, inf]
%         numVisits is the number of visits to the current state-action pair
%
%   The alpha schedule must satisfy the following conditions:
%   (i)     sum( alpha(:) ) = infinity
%   (ii)    sum( alpha(:).^2) < infinity
%
%   The beta schedule and alpha schedule must satisfy the following
%   joint conditions:
%   (i)     sum( alpha(:).^2 + beta(:).^2 ) < infinity
%   (ii)    lim n -> infinity (beta(n)./alpah(n)) = 0

maxAlpha = 1;
minAlpha = 0.005;
offset = 6;
alpha = (offset ./ (numVisits+offset)).*(log(numVisits+1)+1);
alpha = min(alpha,maxAlpha);
alpha = max(alpha,minAlpha);

% % % alpha = 1 / (numVisits^0.9); % conservative learning (alpha decays at slow speed)
% alpha = 1 / (numVisits^0.7); % medium aggressive (alpha decays at medium speed)
% % % alpha = 1 ./ sqrt(numVisits); % aggressive learning (alpha decays slowly)