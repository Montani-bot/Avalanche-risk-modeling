
clear; clc; close all;
%%%data_meteo_mottec
filename = '/home/pablo/Bureau/data_project_avalanche/data_mottec.csv';
data_mottec = readtable(filename);
%disp(data_mottec)
data_mottec.date = datetime(data_mottec.reference_timestamp, 'InputFormat', 'dd.MM.yyyy HH:mm');
%
%head(data_mottec)


%% 
%%% data sur les risque d'avalanche en fonction du jour dans chaque regions
%%% de suisse 2022-2024 
filename = '/home/pablo/Bureau/data_project_avalanche/Danger_level_decimal_notinorder.csv';
data2 = readtable(filename);
%disp(data2)
%% 

%%% ne garde que les information sur la zone val d'annivier (secteur 4124)
data_Annivier = data2(data2.sector_id == 4124, :);
%disp(data_Annivier)

%%%Trie le tableau par date 
sorted_data_annivier = sortrows(data_Annivier, 'date');
%disp(sorted_data_annivier)
sorted_data_annivier.date = datetime(sorted_data_annivier.date, 'InputFormat', 'dd.MM.yyyy HH:mm');

%head(sorted_data_annivier)

%%
%%% combine les tableaux 
Data_danger_meteo = innerjoin(data_mottec,sorted_data_annivier, 'Keys', 'date');
%head(Data_danger_meteo)
%disp(Data_danger_meteo)

%%% simplifie le tableau final 

Data_danger_meteo(:, [11 12]) = [];
head(Data_danger_meteo)

%% enregistrer sur mon bureau
writetable(Data_danger_meteo, '/home/pablo/Bureau/data_combined.csv');
