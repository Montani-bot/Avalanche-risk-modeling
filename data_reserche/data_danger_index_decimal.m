
clear; clc; close all;
%%% data sur les risque d'avalanche en fonction du jour dans chaque regions
%%% de suisse 2022-2024 
filename = '/home/pablo/Bureau/data_project_avalanche/Danger_level_decimal_notinorder.csv';
data = readtable(filename);
%disp(data)

%%% ne garde que les information sur la zone val d'annivier (secteur 4124)
data_Annivier = data(data.sector_id == 4124, :);
%disp(data_Annivier)

%%%Trie le tableau par date 
sorted_data_annivier = sortrows(data_Annivier, 'date');

disp(sorted_data_annivier) 