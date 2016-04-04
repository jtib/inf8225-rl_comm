function [arrivalRate] = updateArrivalRate(arrivalRate,minRate,maxRate,var)
% function [arrivalRate] = updateArrivalRate(arrivalRate,minRate,maxRate,var)
% -------------------------------------------------------------------------
% Updates arrivalRate each time slot to achieve non-stationary arrivalRate.
% The update is done using an AR(1) model for arrivalRate
% 
% Input:
%   arrivalRate -- arrivalRate
%   minRate -- min possible arrival rate
%   maxRate -- max possible arrival rate
%   var -- Gaussian noise variance
%
% Output:
%   arrivalRate -- updated arrivalRate
%
% Note: Reasonable values of var:
%   var = 10^-7 -- very slow varying channel
%   var = 10^-6 -- slow varying channel
%   var = 10^-5 -- medium varying channel
%   var = 10^-4 -- fast varying channel
%   var = 10^-3 -- very fast varying channel

noise = sqrt(var)*randn(1,1);

arrivalRate = arrivalRate + noise;  % add noise
arrivalRate = min( max(minRate,arrivalRate), maxRate );   % bound between minRate and maxRate