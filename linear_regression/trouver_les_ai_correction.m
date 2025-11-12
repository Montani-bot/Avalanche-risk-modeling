%% Chargement des données
T = readtable('/home/pablo/Bureau/data_project_avalanche/data_combined.csv');
%summary(T)
%head(T)

%% Préparation des variables
% Supprimer les colonnes dupliquées et sélectionner les variables
X = [T.temp_A5, T.Humid2j, T.vit_vent, T.precipi_j, T.ensol_dur, T.altitude];
y = T.level_detail_numeric;

% Supprimer les lignes contenant des NaN
valid_idx = all(~isnan(X),2) & ~isnan(y);
X = X(valid_idx, :);
y = y(valid_idx);
disp(X)
disp(y)
%summary(X)
%summary(y)




%% Suppose que X et y sont déjà préparés et nettoyés

% Définir la proportion pour l'entraînement (80 %)
train_ratio = 0.8;

% Nombre total de lignes
n = size(X,1);

% Créer un index aléatoire
rng(42); % Pour reproductibilité
idx = randperm(n);

% Indices pour le training set et le test set
train_idx = idx(1:round(train_ratio*n));
test_idx  = idx(round(train_ratio*n)+1:end);

% Diviser X et y
X_train = X(train_idx, :);
y_train = y(train_idx);

X_test  = X(test_idx, :);
y_test  = y(test_idx);

%% Normalisation basée sur le training set
mu = mean(X_train);
sigma = std(X_train);

X_train_n = (X_train - mu) ./ sigma;
X_test_n  = (X_test - mu) ./ sigma;
% le training set et le test set sont Normalisés avec les mêmes mu et sigma
% pour éviter de donné des data supplémentaire irrealistes au model 

%% % Ajouter la constante pour l'intercept
X_design_train = [ones(size(X_train_n,1),1) X_train_n];

% Calcul des coefficients
b = X_design_train \ y_train;
disp(b)

% Prédiction sur le training set
y_train_pred = X_design_train * b;

% Évaluation sur le training set
R2_train = 1 - sum((y_train - y_train_pred).^2) / sum((y_train - mean(y_train)).^2);
MSE_train = mean((y_train - y_train_pred).^2);

fprintf('Training set -> R² = %.4f, MSE = %.4f\n', R2_train, MSE_train);

%% evaluation sur le TEST set 
% Ajouter la constante pour l'intercept
X_design_test = [ones(size(X_test_n,1),1) X_test_n];

% Prédiction sur le test set
y_test_pred = X_design_test * b;

% Évaluation
R2_test = 1 - sum((y_test - y_test_pred).^2) / sum((y_test - mean(y_test)).^2);
MSE_test = mean((y_test - y_test_pred).^2);

fprintf('Test set -> R² = %.4f, MSE = %.4f\n', R2_test, MSE_test);

%% 






%% 
% %% 
% % Normalisation après nettoyage
% Xn = normalize(X);
% summary(Xn)

%% Ajouter la constante pour l'intercept
% X_design = [ones(size(Xn,1),1) Xn];
% head(X_design)

% %% Calcul des coefficients (moindres carrés)
% b = X_design \ y;
% 
% %% Prédictions
% y_pred = X_design * b;
% 
% %% Calcul du R² et de l'erreur quadratique moyenne
% R2 = 1 - sum((y - y_pred).^2) / sum((y - mean(y)).^2);
% MSE = mean((y - y_pred).^2);
% 
% %% Affichage des résultats
% disp('Coefficients (b) :');
% disp(b);
% fprintf('R² = %.4f\nMSE = %.4f\n', R2, MSE);
% 
% %% Visualisation
% figure;
% plot(y, y_pred, 'o');
% xlabel('Valeurs réelles');
% ylabel('Valeurs prédites');
% title('Régression linéaire multiple');
% grid on;
