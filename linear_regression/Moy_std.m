%% Chargement des données
T = readtable('/home/pablo/Bureau/data_project_avalanche/data_combined.csv');

%% Sélection des variables d'intérêt
vars = {'temp_A5', 'Humid2j', 'vit_vent', 'precipi_j', 'ensol_dur', 'altitude'};

%% Initialisation
means = zeros(1, numel(vars));
stds  = zeros(1, numel(vars));

%% Calcul des moyennes et écarts-types
for i = 1:numel(vars)
    data = T.(vars{i});        % extraire la colonne
    data = data(~isnan(data)); % ignorer les NaN
    means(i) = mean(data);
    stds(i)  = std(data);
end

%% Affichage
fprintf('Variable\tMean\t\tStd\n');
for i = 1:numel(vars)
    fprintf('%s\t%.4f\t%.4f\n', vars{i}, means(i), stds(i));
end
