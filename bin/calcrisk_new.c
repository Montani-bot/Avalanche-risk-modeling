#include <stdio.h>

// Fonction pour calculer l'indice de risque d'avalanche
int risk_index(double temp_A5, double Humid2j, double vit_vent,
               double precipi_j, double ensoleil_dur, double altitude) 
{
    // Coefficients de régression obtenus dans MATLAB
    double b0 = 2.4018;    // intercept
    double b1 = 0.0079;    // temp_A5
    double b2 = 0.2146;    // Humid2j
    double b3 = 0.0370;    // vit_vent
    double b4 = 0.0623;    // precipi_j
    double b5 = 0.1030;    // ensoleil_dur
    double b6 = -0.1165;   // altitude

    // Calcul de la valeur brute du modèle
    double risk_raw = b0 + b1*temp_A5 + b2*Humid2j + b3*vit_vent
                      + b4*precipi_j + b5*ensoleil_dur + b6*altitude;

    // Normalisation de l'indice sur 1 à 5
    // Ici on peut simplement limiter et arrondir
    if (risk_raw < 1.0) risk_raw = 1.0;
    if (risk_raw > 5.0) risk_raw = 5.0;

    return (int)(risk_raw + 0.5); // arrondi à l'entier le plus proche
}

// Exemple d'utilisation
int main() {
    // Exemple de valeurs normalisées
    double temp_A5 = 0.0;
    double Humid2j = 1.0;
    double vit_vent = 0.5;
    double precipi_j = 0.2;
    double ensoleil_dur = -0.3;
    double altitude = 0.1;

    int risk = risk_index(temp_A5, Humid2j, vit_vent, precipi_j, ensoleil_dur, altitude);
    printf("Indice de risque d'avalanche : %d\n", risk);

    return 0;
}
