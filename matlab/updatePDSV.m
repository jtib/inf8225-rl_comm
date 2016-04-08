function [PDSV] = updatePDSV(PDSV,T_known,knownCost,unknownCost,pd_sIdx,spIdx,alpha,discount_factor)
% PDS Learning update (post-decision state learning update)
% [PDSV] = updatePDSV(PDSV,T_known,knownCost,unknownCost,pd_sIdx,spIdx,alpha,discount_factor)
% --------------------------------------------------
% Input:
%   PDSV                    -- post-decision state value function
%                                   PDSV(pd_sIdx)
%   T_known                 -- known transition probability function
%                                   T_known(s,a,pd_s)
%   knownCost               -- known cost function
%                                   knownCost(s,a)
%   unknownCost             -- sample of unknown cost
%   pd_sIdx                 -- post-decision state index
%   spIdx                   -- next state index
%   alpha                   -- learning rate
%   discount_factor         -- discount factor for long-term optimization
%
% Output:
%   PDSV                    -- updated post-decision state value function

PDSQ = knownCost(spIdx,:)' + squeeze(T_known(spIdx,:,:))*PDSV;

V = min( PDSQ );

PDSV(pd_sIdx) = (1-alpha)*PDSV(pd_sIdx) + alpha*(unknownCost + discount_factor*V);