function [T_h] = updateT_h(T_h,var)
% function [T_h] = updateT_h(T_h,var)
% ------------------------------------
% Updates T_h each time slot to achieve non-stationary channel conditions.
% The update is done using an AR(1) model for each T_h(h',h)
% 
% Input:
%   T_h -- channel transition matrix T_h(h',h)
%   var -- Gaussian noise variance
%
% Output:
%   T_h -- updated transmition matrix T_h(h',h)
%
% Note: Reasonable values of var:
%   var = 10^-8 -- very slow varying channel
%   var = 10^-7 -- slow varying channel
%   var = 10^-6 -- medium varying channel
%   var = 10^-5 -- fast varying channel
%   var = 10^-4 -- very fast varying channel

noise = sqrt(var)*randn(size(T_h));

T_h = T_h + noise;  % add noise
T_h = max(0,T_h);   % prevent negative entries
for i = 1:length(T_h) % normalize
    T_h(:,i) = T_h(:,i)./sum(T_h(:,i));
end
