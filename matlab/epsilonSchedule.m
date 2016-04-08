function epsilon = epsilonSchedule(numVisits)
% Determines the exploration schedule
%   Note: numVisits in [0, inf]
%         numVisits is number of visits to the current state

threshold = 1000;
X = floor( numVisits ./ threshold ); % integer division result
n = numVisits - threshold*X; % remainder

epsilon = ( 15 ./ (n + X + 15) );

