%% 

T=readtable('/home/pablo/Bureau/data_project_avalanche/data_combined.csv');
head(T)
%% 

X = [T.temp_A5, T.Humid2j, T.vit_vent, T.precipi_j, T.ensol_dur, T.altitude,];
y = T.level_detail_numeric;
Xn = normalize(X);
summary(Xn)
%marche pas pour l'instant 
%mdl = fitlm(Xn, y);

%supprime les nan 
valid_idx = all(~isnan(X),2) & ~isnan(y);
X = X(valid_idx, :);
y = y(valid_idx);


% Matrice Xn : tes variables normalisées
% Vecteur y : ta variable cible

% Ajouter la constante pour l'intercept
X_design = [ones(size(Xn,1),1) Xn];
head(X_design)

% Coefficients (méthode des moindres carrés)
b = X_design \ y;

% Prédictions
y_pred = X_design * b;

% R²
R2 = 1 - sum((y - y_pred).^2) / sum((y - mean(y)).^2);

% Erreur quadratique moyenne
MSE = mean((y - y_pred).^2);

disp('Coefficients (b) :');
disp(b);
fprintf('R² = %.4f\nMSE = %.4f\n', R2, MSE);

% Visualisation
figure;
plot(y, y_pred, 'o');
xlabel('Valeurs réelles');
ylabel('Valeurs prédites');
title('Régression linéaire multiple');
grid on;


