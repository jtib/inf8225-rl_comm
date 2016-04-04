function [powerCost, txPower] = populatePowerCost()
% function [powerCost, txPower] = populatePowerCost()
% -------------------------------------------------------------
% Populate the expected power cost defined as:
%
% powerCost = 
%   Pon + Ptx(h,BEP,z), if (x == ON and y == S_ON)
%   Ptr, if (x == ON and y == S_OFF) or (x == OFF and y == S_ON)
%   Poff, if (x == OFF and y == S_OFF)
%
%
% Inputs (from parameters.m):
%   bufferStates       -- buffer state set
%   channelStates      -- channel state set
%   pmStates           -- power management state set
%   BEPActions         -- BEP action set
%   pmActions          -- power management action set
%   txActions          -- transmission action (throughput) set
%   L                  -- packet size (bits)
%   M                  -- buffer size
%   deltaT             -- time slot duration (seconds)
%   Ptr = .75+1e-12;   -- Transition power (watts)
%   Pon = .75;         -- On power (watts)
%   Poff = .2;         -- Off power (watts)
%   
% Outputs:
%   powerCost          -- expected buffer reward:
%                               powerCost(b,h,x,BEP,y,z)
%   txPower            -- expected transmission power:
%                               txPower(h,BEP,z)
% NOTE: (a) powerCost does not actually depend on b.
%

load parameters;

tic;

powerCost = zeros(length(bufferStates),length(channelStates),length(pmStates),...
                     length(BEPActions),length(pmActions),length(txActions));
txPower = zeros(length(channelStates),length(BEPActions),length(txActions));

% Populate for (x == OFF and y == S_ON) and (x == OFF and y == S_OFF) 
powerCost(:,:,:,:,:,:) = Ptr;

% Populate for (x == OFF and y == S_OFF)
powerCost(:,:,OFF,:,S_OFF,:) = Poff;

% Populate for (x == ON and y == S_ON)
for bIdx = 1:length(bufferStates)
    b = bufferStates(bIdx);
    for hIdx = 1:length(channelStates)
        h = channelStates(hIdx);
        for BEPIdx = 1:length(BEPActions)
            BEP = BEPActions(BEPIdx);
            for z = txActions
                
                % (i)   zIdx -> beta;
                % (ii)  beta + BEP -> txPower;
                zIdx = find(txActions == z);
                
                beta = getBeta(z,L,Ts,deltaT);
                txPower(hIdx,BEPIdx,zIdx) = getTxPower(beta,BEP,h,Ts,N0);
                powerCost(bIdx,hIdx,ON,BEPIdx,S_ON,zIdx) = Pon + txPower(hIdx,BEPIdx,zIdx);
            end
        end
    end
end

fprintf('populatePowerCost: elapsed time = %f\n',toc);