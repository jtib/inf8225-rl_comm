function [departureDistr] = populateDepartureDistr()
% function [departureDistr] = populateDepartureDistr()
% -------------------------------------------------------------
% Populate the departure distribution:
%
% Inputs (from parameters.m):
%   BEPActions          -- set of BEP actions
%   txActions           -- set of txActions
%   L                   -- packet size in bits
%
% Outputs:
%   departureDistr     -- distribution of departures
%                               departureDistr(f,BEP,z), f = departures
%                               with support [0, 1, ... , z] packets
%
% NOTE: The departure distribution is independent of the channel state
% given BEP

load parameters;

% Initialize to zero
departureDistr = zeros( length(txActions),length(BEPActions),length(txActions) );

for z = txActions
    zIdx = find(txActions == z);
    for BEP = BEPActions
        BEPIdx = find(BEPActions == BEP);
        PLR = BEP2PLR(BEP,L);
        
        n = z;
        
        %%%% Non-deterministic %%%%
        % k = 0 departures
        if n ~= 0
            departureDistr(1,BEPIdx,zIdx) = PLR^n; % n > 0 transmissions
        else
            departureDistr(1,BEPIdx,zIdx) = 1; % n = 0 transmissions
        end
        
        % k > 0 departures
        for k = [1:z]
            departureDistr(k+1,BEPIdx,zIdx) = nchoosek(n,k) * (1-PLR).^k * (PLR)^(n-k);
        end
        
        %%%% Deterministic %%%%
%         departureDistr(zIdx,BEPIdx,zIdx) = 1;
    end
end

% sanity check
for z = txActions
    zIdx = find(txActions == z);
    for BEP = BEPActions
        BEPIdx = find(BEPActions == BEP);
        
        if sum(departureDistr(:,BEPIdx,zIdx)) < 1-1E-12 | sum(departureDistr(:,BEPIdx,zIdx)) > 1+1E-12
            sum(departureDistr(:,BEPIdx,zIdx))
            error('ERROR: departure distribution does not sum to 1'); 
        end
    end
end

        