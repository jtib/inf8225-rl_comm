% Comment out the following in experiment_PDSlearning.m:
%   clear -- at the beginning of the file
%   Pon -- initial assignment
%   cost_constraint -- initial assignment

clear;

constraintSet = [1:9];
Pon = 80/1000; % W
for i = constraintSet    
    outmat = ['results_PDSlearning_constraint' num2str(constraintSet(i)) '_Pon' num2str(Pon*1000) '_nonstationary.mat']
    cost_constraint = i/25 % for buffer size B = 25
    
    experiment_PDSlearning;
    
    save (outmat)
    
    keep Pon i constraintSet; % Deletes all variables except those in the argument list
    close all;
end