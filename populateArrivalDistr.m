function [arrivalDistr] = populateArrivalDistr(arrivalRate,M)
% function [arrivalDistr] = populateArrivalDistr(arrivalRate)
% -------------------------------------------------------------
% Populate the arrival distribution using a Poisson distribution:
%
% Inputs:
%   B                   -- maximum number of arrivals
%   arrivalRate         -- average arrival rate
%
% Outputs:
%   arrivalDistr        -- distribution of arrivals
%                               with support [0, 1, ... , M] packets

arrivalDistr = zeros(1,M+1);
for arrivals = [0:M-1]
    % packet arrival distribution with support [0, 1, ... M] packets   
    arrivalDistr(arrivals+1) = ...
        (arrivalRate.^arrivals)*exp(-arrivalRate)/factorial(arrivals);
end
arrivalDistr(M+1) = 1 - sum(arrivalDistr(1:end-1));