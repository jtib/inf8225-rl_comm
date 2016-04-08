function [index] = rando(pdf)
%  function [index] = rando(p)
%  generates a random variable in 1, 2, ..., n given a distribution 
%  vector. 

if ~(sum(pdf) + 1E-12 > 1 & 1 > sum(pdf) - 1E-12)
    error('pdf is does not sum to 1');  
end

cdf = cumsum(pdf);
index = min(find(cdf >= rand));

