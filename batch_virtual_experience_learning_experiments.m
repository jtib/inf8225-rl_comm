% Comment out the following in experiment_PDSlearning.m
%   clear -- at beginning of file
%   virtualUpdateFreq -- initial assignment statement

clear;

virtualUpdateFreq = 250;
experiment_PDSlearning;
clear T_known T_known_expand
save results_PDSlearning_arr2_constraint4_virtualFreq250_improve
close all;
clear all;

virtualUpdateFreq = 125;
experiment_PDSlearning;
clear T_known T_known_expand
save results_PDSlearning_arr2_constraint4_virtualFreq125_improve
close all;
clear all;

virtualUpdateFreq = 75;
experiment_PDSlearning;
clear T_known T_known_expand
save results_PDSlearning_arr2_constraint4_virtualFreq75_improve
close all;
clear all;

virtualUpdateFreq = 25;
experiment_PDSlearning;
clear T_known T_known_expand
save results_PDSlearning_arr2_constraint4_virtualFreq25_improve
close all;
clear all;

virtualUpdateFreq = 10;
experiment_PDSlearning;
clear T_known T_known_expand
save results_PDSlearning_arr2_constraint4_virtualFreq10_improve
close all;
clear all;

virtualUpdateFreq = 1;
experiment_PDSlearning;
clear T_known T_known_expand
save results_PDSlearning_arr2_constraint4_virtualFreq1_improve
close all;
clear all;