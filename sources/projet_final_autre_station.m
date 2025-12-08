clear; clc; close all;

%% Ce modèle se base sur plusieurs set de données SLF publiques et disponibles sur le site envidat.ch 

%% Upload des donnée météorologique sur la région souhaitée
% Les tableaux sont téléchargeables pour un grand nombre de stations au format csv depuis le site www.admin.ch 
% quelque set avec lequels j'ai travaillé pour ce model 
% (le modèle fonctionne avec n'importe quel set de data meteo tiré du site de meteo suisse)
meteo_davos = '/home/pablo/Bureau/CMT/data_project_avalanche/Data_meteo_davos.csv';
meteo_mottec = '/home/pablo/Bureau/CMT/data_project_avalanche/data_meteo_mottec_brut.csv';
meteo_zermatt = '/home/pablo/Bureau/CMT/data_project_avalanche/data_meteo_zermatt.csv';
meteo_evolene = '/home/pablo/Bureau/CMT/data_project_avalanche/data_meteo_evolene.csv';
meteo_pilatus = '/home/pablo/Bureau/CMT/data_project_avalanche/data_meteo_pilatus.csv';
meteo_Arosa = '/home/pablo/Bureau/CMT/data_project_avalanche/meteo_arosa_grison.csv';
meteo_jungfrau_3571m = '/home/pablo/Bureau/CMT/data_project_avalanche/data_meteo_jungfrau.csv';
meteo_santis = '/home/pablo/Bureau/CMT/data_project_avalanche/meteo_santis.csv';
meteo_weisfluhjoch = '/home/pablo/Bureau/CMT/data_project_avalanche/meteo_weissfluhjoch.csv'; %davos

%% ===selection du dataset meteo de la station d'intérêt=== %%
station_of_interest = meteo_evolene;
data_meteo = readtable(station_of_interest);

%% convertit la collone des date au format matlab
data_meteo.date = datetime(data_meteo.reference_timestamp, 'InputFormat', 'dd.MM.yyyy HH:mm');

%% selectionne et renomme les variables du tableau (les tableau de donnée meteoswiss suivent tous les memes abbréviation ce qui permet de généralier mon code pour toute les station meteo de suisse)
data_meteo = renamevars(data_meteo, {'fkl010d0','gre000d0','htoautd0','rka150d0' ,'sre000d0','tre005d0','tso020d0','ure200d0'},...
    {'wind_speed','radiation','snow_depth_6UTC','precipitation_daily_sum_0UTC','sunshine_duration','temperature_5cm','temperature_20cm_sol','humidity'});

%% selectionne les variables d'intérêt dans le tableau de mesure meteoswiss et supprimme les colonnes des autres variables 
vars_to_keep = {'date','wind_speed','radiation','snow_depth_6UTC','precipitation_daily_sum_0UTC','sunshine_duration','temperature_5cm','temperature_20cm_sol','humidity'};
data_meteo = data_meteo(:, vars_to_keep);

%% upload d'un set de donnée SLF sur les risque d'avalanche en fonction du jour dans chaque regionsde suisse 2022-2024 (envidat.ch)
%les risques d'avalanche sont ceux indiqués par SLF. Toutes les information necessaires sur le calcul du risque par SLF sont disponible ici: https://www.slf.ch/fileadmin/user_upload/SLF/Lawinenbulletin_Schneesituation/Wissen_zum_Lawinenbulletin/Interpretationshilfe/Interpretationshilfe_EN.pdf
filename = '/home/pablo/Bureau/CMT/data_project_avalanche/Danger_level_decimal_notinorder.csv';
data_risk_swiss = readtable(filename);

%% Ne garde que les information sur la zone d'intérêt 
%Les numéros de secteur permette de selectionner la région de suisse pour laquelle on souhaite obtenir les prédiction de risque 
%La numérotation des secteurs selon SLF est disponible sur ce site: https://www.slf.ch/fr/bulletin-davalanches-et-situation-nivologique/en-savoir-plus-sur-le-bulletin-davalanches/termes-geographiques/
%numéros de secteur de stations dont j'ai utilisé les données pour construire et perfectionner mon modèle:
davos = 5123; %0.3664 weissfluhjoch 0.5541
annivier = 4124; %0.4219
zermatt = 4222; % 0.4482
val_herens = 4122; %evolene 0.4728
Pilatus = 2111; %0.4974
arosa = 5221; %0.3649
jungfrau = 1234; %0.2999
alpstein = 3222; %santis 0.4208

%% ===choisis le secteur d'intérêt=== (permet de ne garder que les information sur le risque d'avalanche d'un secteur en particulier) 
sector_of_interest = val_herens;
data_station_risk = data_risk_swiss(data_risk_swiss.sector_id == sector_of_interest, :);


%% Trie et formate le tableau contenant les prédictions de risque SLF
%Trie le tableau par date 
sorted_data_risk = sortrows(data_station_risk, 'date');

%convertit les dates en format de date matlab 
sorted_data_risk.date = datetime(sorted_data_risk.date, 'InputFormat', 'dd.MM.yyyy HH:mm');

%renomme la variable du risque: 
sorted_data_risk = renamevars(sorted_data_risk, 'level_detail_numeric', 'risk_index');

%enlève les collone superflue (ne garde que la collone des dates et celle des indexes de risque
vars_to_keep2 = {'date', 'risk_index'};
sorted_data_risk = sorted_data_risk(:,vars_to_keep2);

%% Combine les Tableaux data_mottec_meteo et sorted_data_annivier pour obtenir un tableau avec les variables d'interêt et un vecteur risque 
T = innerjoin(data_meteo,sorted_data_risk, 'Keys', 'date');
summary(T)

%% Cette section à pour but d'ajouter des variables à notre tableau T pour mieux capturer les variation de risque d'avalanche. 
% Le choix des variables ajoutées se base sur des réflexion et recherchesur les combinaison de variables les plus pertinente pour le calcul de risque d'avalanche mais aussi simplement sur des tests de l'effet de l'ajout d'une variable sur les performances du model 
% Utilisation du language c pour ajout de variables qui somment plusieurs jours et rendent le modèle plus pertinent et précis

%% sommes (pour prévoir le risque d'avalanche, il est néssessaire de se baser sur les jours qui précède et leur impacte sur l'état du manteau neigeux)
%J'ai choisis de sommer les précipitation, l'ensoleillement et l'humidité qui sont trois paramètres important dans le risque d'avalanche et dont l'effet sur les jours qui précèdent le jour cible est crucial 
%pour effectuer cette succession de sommes j'ai eu recours au language c à travers la fonction movsum_c 
%la fonction movsum_c retourne un nan si il n'existe pas suffisemment de jours précédents pour calculer la sommes demandée donc dans ce cas les 35 premiers jours du tableau seront supprimmé 
precip_35j_sum = movsum_c(T.precipitation_daily_sum_0UTC, 35);
precip_20j_sum = movsum_c(T.precipitation_daily_sum_0UTC, 20);
precip_5j_sum = movsum_c(T.precipitation_daily_sum_0UTC, 5);
precip_2j_sum = movsum_c(T.precipitation_daily_sum_0UTC, 2);

sunshine_10j_sum = movsum_c(T.sunshine_duration, 10);
sunshine_2j_sum = movsum_c(T.sunshine_duration, 2);

humidity_40j_sum = movsum_c(T.humidity, 40);
humidity_15j_sum = movsum_c(T.humidity, 15);

%% Variation (un des paramètre souvent cité dans le risque d'avalanche est la variation de température)
% Utilisation du language c pour calculer la variations de température à travers la fonction diff_c
temp_delta_1j = diff_c(T.temperature_5cm, 1);

%% dans le domaine du risque d'avalanche il est important de detecter les extremes en termes de parametre meteo 
%la fonction movquantil prends en parametre une des variables d'intérêt, lenombre de jours précédents que l'on souhaite considérer et le quantil ciblé. Elle retourne la valeur du quantil en parametre ce qui permet de detecter les extrèmes 
precip_extreme_5j = movquantil_c(T.precipitation_daily_sum_0UTC, 15, 0.90);


%% liaison de variables similaires %%%%%%% Zone-à-expliquer %%%%%%%%%%
precip_sum_sum = 10 .* precip_2j_sum + precip_20j_sum;


%% relations non linéaires (introduction de relation non linéaire entre les variables pour tenter d'augmenter la précision du model)
%ces relation non linéaire sont tirée de reflexion sur le comportement à priori non-linéaire du risque d'avalanche en fonction de certain des param,ètre 
precip_product = precip_2j_sum.*precip_35j_sum; % 0.0002
precip_2j_square = precip_2j_sum .^ 2; %negatif 
temperature_square = T.temperature_5cm.^ 2; % la température 0 degré est une température critique qui est liée à beaucoup de changement de structure dans la neige. On essaye ici de capturer l'effet de la température autour de ce point  0.003
temperature_radiation_product = T.temperature_5cm .* T.radiation; %negatif
sunshine_duration_square = sunshine_2j_sum .^2; % 0.003 %explique pourquoi !!!
sunshine_humidity_product = sunshine_10j_sum .* humidity_40j_sum; %negatif 
windspeed_square = T.wind_speed .^2; % negatif
precip_recent_proportion = precip_5j_sum./precip_35j_sum; %negatif 



%% Matrice des paramètres 
X = [T.temperature_5cm, T.snow_depth_6UTC, precip_35j_sum, precip_sum_sum, sunshine_10j_sum,...
    humidity_40j_sum, temp_delta_1j, temperature_square, sunshine_duration_square,...
    windspeed_square, precip_extreme_5j, precip_recent_proportion];


%% Noms des variables (dans l'ordre où X est construit)
var_names = {'temperature_5cm', ...
             'snow_depth_6UTC', ...
             'precip_35j_sum','precip_sum_sum', ...
             'sunshine_10j_sum','humidity_40j_sum', ...
             'temp_delta_1j','temperature_square','sunshine_duration_square',...
             'windspeed_square','precip_extreme_5j','precip_recent_proportion'};

%% Identification des colonnes entièrement NaN
cols_nan = all(isnan(X),1);

%% Nettoyage des colonnes non exploitables
if any(cols_nan)
    removed_vars = var_names(cols_nan);  % récupère les noms des variables supprimées
    fprintf("⚠️ Suppression de %d variable(s) météo absente(s) pour cette station : %s\n", ...
            sum(cols_nan), strjoin(removed_vars, ', '));
    X(:, cols_nan) = [];                  % enlève ces variables
    var_names(cols_nan) = [];             % met à jour var_names pour rester cohérent
end

%% creation du vecteur des risques mesurés par SLF 
y = T.risk_index;

%% Supprimer les lignes contenant des NaN
valid_idx = all(~isnan(X),2) & ~isnan(y);
X = X(valid_idx, :);
y = y(valid_idx);

%% Séparation du set de donnée en une partie entrainement (80%) et une partie test (20%) de 20 manière différente (20split) et test des 20 modèle de regression issus des split 
n = size(X,1);
train_ratio = 0.8;
num_tests = 20;
% lste pour stocker les R² et les MSE obtenu 
R2_train_list = zeros(num_tests,1);
R2_test_list  = zeros(num_tests,1);
MSE_train_list = zeros(num_tests,1);
MSE_test_list  = zeros(num_tests,1);

%%Vecteur pour stocker les coefficients (intercept + variables) (il est
%interessant d'avoir le detail des coefficient pour interpreter l'incidence de chaque variables sur le risque final 
%coeffs_all = zeros(length(var_names)+1, num_tests);
coeffs_all = zeros(size(X,2)+1, num_tests); % +1 pour l'intercept


for k = 1:num_tests

    rng(k);
    idx = randperm(n);
    train_idx = idx(1:round(train_ratio*n));
    test_idx  = idx(round(train_ratio*n)+1:end);

    Xt = X(train_idx,:);   yt = y(train_idx);
    Xv = X(test_idx,:);    yv = y(test_idx);

    % Normalisation basée sur le train set
    mu = mean(Xt);
    sigma = std(Xt);

    Xt = (Xt - mu) ./ sigma;
    Xv = (Xv - mu) ./ sigma;

    Xt_d = [ones(size(Xt,1),1) Xt];
    Xv_d = [ones(size(Xv,1),1) Xv];

    b = Xt_d \ yt;
    coeffs_all(:,k) = b; %stock les coefficients relatifs au 20 différents split dans une matrice

    y_pred_t = Xt_d * b;
    y_pred_v = Xv_d * b;

    R2_train_list(k) = 1 - sum((yt - y_pred_t).^2)/sum((yt - mean(yt)).^2);
    R2_test_list(k)  = 1 - sum((yv - y_pred_v).^2)/sum((yv - mean(yv)).^2);

    MSE_train_list(k) = mean((yt - y_pred_t).^2);
    MSE_test_list(k)  = mean((yv - y_pred_v).^2);

end

%% == affichage des résultats du model == %%
%% retourne les moyennes des 20 différents écarts type et MSE obtenu avec regressions linéaires sur les 20 disposition différentes 
fprintf("\n===== Model results over 20 splits =====\n");
fprintf("R² train : %.4f (± %.4f)\n", mean(R2_train_list), std(R2_train_list));
fprintf("R² test  : %.4f (± %.4f)\n", mean(R2_test_list), std(R2_test_list));
fprintf("MSE train : %.4f\n", mean(MSE_train_list));
fprintf("MSE test  : %.4f\n\n", mean(MSE_test_list));


%% === AFFICHAGE DES COEFFICIENTS MOYENS ===  
mean_coeffs = mean(coeffs_all,2);

fprintf("\n===== Coefficients moyens de la régression =====\n");
fprintf("Intercept : %.4f\n", mean_coeffs(1));

%relie chaque parametre au coefficient associé 
for i = 1:length(var_names)
    fprintf("%s : %.4f\n", var_names{i}, mean_coeffs(i+1));
end



%% figure pour illustrer la variabilité du modèle sur 20 séparations  
figure;
plot(R2_train_list, '-o'); hold on;
plot(R2_test_list, '-o');
xlabel('Split number #'); ylabel('R² (coefficient of determination)');
title('Variability of the model over 20 splits');
legend('Train','Test');
grid on;

%% === BARPLOT DES IMPORTANCES DES VARIABLES ===
figure;
bar(mean_coeffs(2:end));  % On exclut l'intercept

set(gca, 'XTickLabel', var_names, ...
    'XTickLabelRotation', 45, ...
    'FontSize', 14, ...
    'FontWeight', 'bold', ...
    'TickLabelInterpreter', 'none');  % <--- LIGNE MAGIQUE

title('Importance of weather parameters in avalanche risk prediction in a particular swiss region/ski resort', ...
    'FontSize', 18, 'FontWeight', 'bold', 'Interpreter', 'none');
ylabel('Average linear regression coefficient', 'FontSize', 16, 'Interpreter', 'none');
xlabel('Meteorological Variables', 'FontSize', 16, 'Interpreter', 'none');
grid on;


%% === BARPLOT TRIÉ PAR IMPORTANCE ABSOLUE ===
[~, idx_sorted] = sort(abs(mean_coeffs(2:end)), 'descend');
figure;
bar(abs(mean_coeffs(1+idx_sorted)));

set(gca, 'XTickLabel', var_names(idx_sorted), ...
    'XTickLabelRotation', 45, ...
    'FontSize', 14, ...
    'FontWeight', 'bold', ...
    'TickLabelInterpreter', 'none');  % <--- ICI AUSSI

title('Absolute importance of parameters (sorted)', ...
    'FontSize', 18, 'FontWeight', 'bold', 'Interpreter', 'none');
ylabel('|Coefficient| mean', 'FontSize', 16, 'Interpreter', 'none');
xlabel('Variables sorted by importance', 'FontSize', 16, 'Interpreter', 'none');
grid on; 
%% fonction finale de calcul de risque pour un jour particulier calcrisk.c
%variables simple d'entrée 

% temperature_5cm = 10
% temperature_yesterday = 20
% snow_depth_6UTC = 
% precip_35j_sum = 
% precipitation_five_days 
% sunshine_duration 
% humidity_30j_sum = 
% windspeed = 

% %% === Validation interne : 20 splits sur le train set ===
% % ce passage est chelou psk tu sous-divide ton train en 20 split test-train et tu le test a chaque fois 
% num_splits = 20;
% R2_train_list = zeros(num_splits,1);
% coeffs_all = zeros(size(X_train,2)+1, num_splits); % +1 pour intercept










%%
% %% === Calibration de alpha pour la WLS avec nouveau critère ===
% alphas = 0:2:20;  % valeurs de alpha à tester
% num_alphas = length(alphas);
% 
% % Matrices pour stocker les performances
% MSE_test_alpha = zeros(num_alphas,1);
% R2_test_alpha = zeros(num_alphas,1);
% R2_high_alpha = zeros(num_alphas,1);
% MSE_high_alpha = zeros(num_alphas,1);
% MAE_high_alpha = zeros(num_alphas,1);
% recall_high_alpha = zeros(num_alphas,1);
% 
% % Seuil pour définir les hauts risques
% high_risk_threshold = 2;
% 
% for i = 1:num_alphas
%     alpha = alphas(i);
% 
%     % Définition des poids WLS
%     weights_train = 1 + alpha * (y_train >= 3);
% 
%     % ---- Régression WLS sur train set complet ----
%     mu = mean(X_train);
%     sigma = std(X_train);
%     X_train_norm = (X_train - mu) ./ sigma;
%     X_train_d = [ones(size(X_train_norm,1),1) X_train_norm];
% 
%     W = diag(weights_train);
%     b = (X_train_d' * W * X_train_d) \ (X_train_d' * W * y_train);
% 
%     % Normalisation test set
%     X_test_norm = (X_test - mu) ./ sigma;
%     X_test_d = [ones(size(X_test_norm,1),1) X_test_norm];
% 
%     % Prédiction
%     y_pred_test = X_test_d * b;
% 
%     % ==== Performance globale ====
%     R2_test_alpha(i) = 1 - sum((y_test - y_pred_test).^2) / sum((y_test - mean(y_test)).^2);
%     MSE_test_alpha(i) = mean((y_test - y_pred_test).^2);
% 
%     % ==== Performance hauts risques ====
%     high_idx = y_test > high_risk_threshold;
%     y_test_high = y_test(high_idx);
%     y_pred_high = y_pred_test(high_idx);
% 
%     R2_high_alpha(i) = 1 - sum((y_test_high - y_pred_high).^2) / sum((y_test_high - mean(y_test_high)).^2);
%     MSE_high_alpha(i) = mean((y_test_high - y_pred_high).^2);
%     MAE_high_alpha(i) = mean(abs(y_test_high - y_pred_high));
% 
%     TP = sum(y_pred_high >= high_risk_threshold);
%     recall_high_alpha(i) = TP / length(y_test_high);
% end

% %% === Sélection du meilleur alpha selon critère combiné ===
% candidates = find((recall_high_alpha >= 0.85) & (MSE_high_alpha < 0.2) & (R2_high_alpha > 0.25));
% 
% if isempty(candidates)
%     warning('Aucun alpha ne satisfait les critères combinés. Choix par défaut alpha = 0.');
%     best_alpha = 0;
%     best_idx = 1;
% else
%     % Parmi les candidats, choisir celui avec R² global maximum
%     [~, rel_idx] = max(R2_test_alpha(candidates));
%     best_idx = candidates(rel_idx);
%     best_alpha = alphas(best_idx);
% end
% 
% fprintf('Meilleur alpha sélectionné : %.2f\n', best_alpha);
% fprintf('R² global : %.3f, R² hauts risques : %.3f, Recall hauts risques : %.3f, MSE hauts risques : %.4f\n', ...
%     R2_test_alpha(best_idx), R2_high_alpha(best_idx), recall_high_alpha(best_idx), MSE_high_alpha(best_idx));
% 


% %% version pondérée (meilleure pour capter les risques elevés) 
% alpha = best_alpha;  % intensité de pondération
% weights_train = 1 + alpha * (y_train >= 3);
% 
% for k = 1:num_splits
%     rng(k);
%     idx_split = randperm(n_train);
% 
%     n_sub_train = round(0.8 * n_train);
%     sub_train_idx = idx_split(1:n_sub_train);
%     val_idx       = idx_split(n_sub_train+1:end);
% 
%     Xt = X_train(sub_train_idx,:);
%     yt = y_train(sub_train_idx);
%     Xv = X_train(val_idx,:);
%     yv = y_train(val_idx);
% 
%     % -- Normalisation --
%     mu = mean(Xt);
%     sigma = std(Xt);
%     Xt = (Xt - mu) ./ sigma;
%     Xv = (Xv - mu) ./ sigma;
% 
%     Xt_d = [ones(size(Xt,1),1) Xt];
%     Xv_d = [ones(size(Xv,1),1) Xv];
% 
%     % ---- WLS ----
%     w_sub = weights_train(sub_train_idx);
%     W = diag(w_sub);
% 
%     b = (Xt_d' * W * Xt_d) \ (Xt_d' * W * yt);
% 
%     coeffs_all(:,k) = b;
% 
%     % Validation interne
%     y_pred_v = Xv_d * b;
%     R2_train_list(k) = 1 - sum((yv - y_pred_v).^2)/sum((yv - mean(yv)).^2);
% end
% 
% 
% %% === Calcul des coefficients moyens et test final ===
% mean_coeffs = mean(coeffs_all,2);
% 
% % Normalisation du test set avec les mu et sigma du train set complet pour éviter la fuite de data
% mu_train = mean(X_train);
% sigma_train = std(X_train);
% X_test_norm = (X_test - mu_train) ./ sigma_train;
% X_test_d = [ones(size(X_test_norm,1),1) X_test_norm];
% 
% % Prédiction sur le test set fixe
% y_pred_test = X_test_d * mean_coeffs;
% 
% R2_test = 1 - sum((y_test - y_pred_test).^2)/sum((y_test - mean(y_test)).^2);
% MSE_test = mean((y_test - y_pred_test).^2);
% 
% %% performances pour les risques élevés 
% high_risk_idx = y_test > 2;
% y_test_high = y_test(high_risk_idx);
% y_pred_high = y_pred_test(high_risk_idx);
% 
% 
% R2_high = 1 - sum((y_test_high - y_pred_high).^2) / sum((y_test_high - mean(y_test_high)).^2);
% MSE_high = mean((y_test_high - y_pred_high).^2);
% MAE_high = mean(abs(y_test_high - y_pred_high));
% 
% %% pourcentage de journée ou le risque était supérieur à 2.5 et mon model a dit que c'était le cas 
% pred_high = y_pred_test >= 2.5;
% real_high = y_test >= 2.5;
% 
% TP = sum(pred_high & real_high);
% FN = sum(~pred_high & real_high);
% 
% recall_high = TP / (TP + FN);



%% =========graphiques========== %%

% %% Variabilité du model sur 20 splits graph 
% figure; hold on;
% plot(R2_train_list, '-o');
% yline(mean(R2_train_list), '--r', 'Mean');
% xlabel('Split #'); ylabel('R²');
% title('Variability of train R² across 20 random splits');
% grid on;