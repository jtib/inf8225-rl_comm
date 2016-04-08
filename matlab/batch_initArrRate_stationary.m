clear;

initArrRateSet = [1 2 3 4 5 6];
for initArrRate = initArrRateSet
    outmat = ['results_PDSlearning_initArrRate' num2str(initArrRate) '_nonstationary.mat']
    
    experiment_PDSlearning;
    
    save (outmat)
    
    keep initArrRate initArrRateSet; % Deletes all variables except those in the argument list
    close all;
end