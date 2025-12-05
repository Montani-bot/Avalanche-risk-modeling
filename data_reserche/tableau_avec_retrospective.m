filename='/home/pablo/avalanche_projet/Avalanche-risk-modeling/data_reserche/Data_combine_mottec.csv';
data = readtable(filename);
% Display the first few rows of the data table
head(data);
data.snow_10j_cumul = movsum(data.precipi_j, [9 0], 'omitnan');
