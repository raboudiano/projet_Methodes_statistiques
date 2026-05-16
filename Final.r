############################################################
# 1. Installer les packages nécessaires (à faire une seule fois)
install.packages("tidyverse")  # Manipulation des données + visualisation (dplyr, ggplot2, tidyr, etc.)
install.packages("skimr")      # Résumé statistique clair et rapide du jeu de données
install.packages("GGally")     # Visualisation des corrélations (matrice de corrélation avancée)
install.packages("stringi")    # Traitement et manipulation de chaînes de caractères
install.packages("reshape2")   # Transformation des matrices en data frames (fonction melt)
install.packages("naniar")     # Analyse et visualisation des valeurs manquantes
install.packages("scales")     # Formatage des axes et des pourcentages dans les graphiques
install.packages("FSA")        # Tests non paramétriques post-hoc (Dunn après Kruskal-Wallis)

# 2. Charger les librairies
library(tidyverse)  # Fournit %>%, dplyr, ggplot2, tidyr pour le prétraitement et l’analyse
library(skimr)      # Fonction skim() pour l’analyse exploratoire
library(GGally)     # Fonction ggpairs() pour visualiser les relations entre variables
library(stringi)    # Fonctions avancées pour le traitement de texte (si nécessaire)
library(reshape2)   # Fonction melt() utilisée pour préparer la matrice de corrélation
library(naniar)     # Fonction vis_miss() pour visualiser les données manquantes
library(scales)     # Fonction percent_format() pour afficher des pourcentages
library(FSA)        # Fonction dunnTest() pour les comparaisons post-hoc


############################################################
# 3. IMPORTATION DU JEU DE DONNÉES
############################################################
data <- read.csv("C:/Users/OUMAIMA/Desktop/PR_Stat/patients_medical_data.csv", sep = ";", header = TRUE)


# Aperçu rapide des données
head(data)
summary(data)
str(data)

############################################################
# 4. GESTION DES VALEURS MANQUANTES
############################################################

# Total NA avant
total_na <- sum(is.na(data))
na_avant <- colSums(is.na(data))
cat("NA par colonne (avant) :\n")
print(na_avant)

# Fonction d'imputation par médiane
impute_median <- function(x) {
  x[is.na(x)] <- median(x, na.rm = TRUE)
  return(x)
}

# Colonnes numériques à traiter
numeric_cols <- c( "Poids", "Tension", "Cholesterol")
numeric_cols <- numeric_cols[numeric_cols %in% colnames(data)]
data[numeric_cols] <- lapply(data[numeric_cols], impute_median)

# NA après imputation
na_apres <- colSums(is.na(data))
cat("\nNA par colonne (après) :\n")
print(na_apres)

cat("\nTotal NA avant :", total_na, "\nTotal NA après :", sum(na_apres), "\nNA traités :", total_na - sum(na_apres), "\n")

############################################################
# 5. CONVERSION DES TYPES DE DONNÉES
############################################################
df <- data %>%
  mutate(
    Sexe = as.factor(Sexe),  # Convertir 'Sexe' en facteur
    Groupe_Traitement = as.factor(Groupe_Traitement),  # Convertir 'Groupe_Traitement' en facteur
    ID = as.integer(ID)      # Convertir 'ID' en entier (numérique)
  )

# Vérifier la structure après les changements
str(df)

############################################################
# 6. DÉTECTION DES OUTLIERS (MÉTHODE IQR)
############################################################
afficher_outliers <- function(data, var) {
  x <- data[[var]]
  Q1 <- quantile(x, 0.25, na.rm = TRUE)
  Q3 <- quantile(x, 0.75, na.rm = TRUE)
  IQRv <- Q3 - Q1
  lower <- Q1 - 1.5 * IQRv
  upper <- Q3 + 1.5 * IQRv
  outliers <- x < lower | x > upper
  cat(var, ":", sum(outliers, na.rm = TRUE), "outliers\n")
}

cat("\n=== DÉTECTION DES OUTLIERS ===\n")
for(v in numeric_cols)
  afficher_outliers(df, v)
df_long <- data %>%
  select(Age, Poids, Tension, Cholesterol, Suivi_Jours, Symptom_Score) %>% 
  pivot_longer(cols = everything(), names_to = "Variable", values_to = "Valeur")

# Afficher tous les boxplots dans un seul graphique
ggplot(df_long, aes(x = Variable, y = Valeur, fill = Variable)) +
  geom_boxplot() +
  labs(title = "Boxplots de toutes les variables", x = "Variable", y = "Valeur") +
  scale_fill_manual(values = c("lightpink", "lightyellow", "lightcoral", "lightcyan", "lightseagreen", "lightsteelblue")) + 
  theme_minimal()  # Style minimal pour un graphique plus propre



############################################################
# 8. detection DES DOUBLONS
############################################################
cat("\n=== DOUBLONS ===\n")
cat("Nombre de doublons :", sum(duplicated(df)), "\n")
df <- df[!duplicated(df), ]

############################################################
# 9. TRANSFORMATION DES DONNÉES
############################################################
num_data <- data %>% select(where(is.numeric)) 
df_long <- num_data %>%
  pivot_longer(cols = everything(), names_to = "Variable", values_to = "Valeur")

# 5. Ajouter les courbes de densité
ggplot(df_long, aes(x = Valeur, fill = Variable)) +
  geom_density(alpha = 0.7) +
  facet_wrap(~ Variable, scales = "free") +
  labs(title = "Courbes de densité des variables (avant transformation)", x = "Valeur", y = "Densité") +
  theme_minimal() +
  theme(legend.position = "none")  # Masquer la légende
vars_transform <- c("Age", "Poids", "Tension", "Cholesterol")
vars_transform <- vars_transform[vars_transform %in% names(df)]

for(v in vars_transform) {
  df[[paste0(v,"_Norm")]] <- (df[[v]] - min(df[[v]])) / (max(df[[v]]) - min(df[[v]]))
}
df <- df[, !grepl("_Norm", names(df))]
############################################################
# 10. ANALYSE UNIVARIÉE
############################################################
for(v in vars_transform) {
  hist(df[[v]], col="lightblue", main=paste("Distribution de",v))
}

############################################################
# 11. ANALYSE BIVARIÉE (CORRÉLATION)
############################################################
num_data <- df %>% select(where(is.numeric))
corr <- cor(num_data, use = "complete.obs")
print(round(corr, 2))

corr_df <- melt(corr)

ggplot(corr_df, aes(Var1, Var2, fill = value)) +
  geom_tile(color = "white") +
  geom_text(aes(label = round(value, 2)), color = "black", size = 3) +
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", midpoint = 0, limit = c(-1, 1), name="Corr") +
  theme_minimal() +
  labs(title = "Matrice de corrélation", x = "", y = "") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

############################################################
# HYPOTHÈSE A : Test de normalité et Kruskal-Wallis pour Symptom_Score
############################################################
cat("\n=== HYPOTHÈSE A : Test de normalité et Kruskal-Wallis pour Symptom_Score ===\n")

data_A <- df[, c("Symptom_Score", "Groupe_Traitement")]
data_A <- na.omit(data_A)

# Test de normalité avec Shapiro-Wilk pour Symptom_Score
normalite_symptom <- shapiro.test(data_A$Symptom_Score)
cat("Test de normalité pour Symptom_Score :\n")
cat("p-value =", normalite_symptom$p.value, "\n")

# QQ-plot pour visualiser la normalité de Symptom_Score
qqnorm(data_A$Symptom_Score)
qqline(data_A$Symptom_Score, col = "red")
title("QQ-plot pour Symptom_Score")

# Si les données ne sont pas normales, utiliser le test de Kruskal-Wallis
if(normalite_symptom$p.value < 0.05) {
  cat("\nDonnées non normales, utilisation du test de Kruskal-Wallis\n")
  
  # Test de Kruskal-Wallis pour comparer Symptom_Score entre les groupes
  test_kruskal <- kruskal.test(Symptom_Score ~ Groupe_Traitement, data = data_A)
  cat("Résultat du test de Kruskal-Wallis :\n")
  print(test_kruskal)
  
  # Visualisation des résultats avec Boxplot
  ggplot(data_A, aes(x = Groupe_Traitement, y = Symptom_Score, fill = Groupe_Traitement)) +
    geom_boxplot() +
    labs(title = "Symptom Score par groupe de traitement", x = "Groupe de traitement", y = "Symptom Score") +
    theme_minimal()
  
  # Interprétation des résultats du test Kruskal-Wallis
  if(test_kruskal$p.value < 0.05) {
    cat("Conclusion : Il y a une différence significative dans le Symptom Score entre les groupes de traitement.\n")
  } else {
    cat("Conclusion : Aucune différence significative dans le Symptom Score entre les groupes de traitement.\n")
  }
  
} else {
  cat("\nDonnées normales, le test de normalité est validé.\n")
  
  # Si les données sont normales, on pourrait utiliser un test paramétrique comme l'ANOVA (si nécessaire)
  cat("Les données sont normales, une analyse paramétrique peut être utilisée si nécessaire.\n")
}

############################################################
# HYPOTHÈSE B :
# Effet du groupe de traitement sur le cholestérol
############################################################

cat("\n=== HYPOTHÈSE B : Cholestérol selon le groupe de traitement ===\n")

#CRÉATION DU SOUS-JEU DE DONNÉES
data_B <- data[, c("Cholesterol", "Groupe_Traitement")]
data_B <- na.omit(data_B)

data_B$Groupe_Traitement <- as.factor(data_B$Groupe_Traitement)
data_B$Cholesterol <- as.numeric(data_B$Cholesterol)

#EFFECTIFS PAR GROUPE
cat("\n=== Effectifs par groupe ===\n")
print(table(data_B$Groupe_Traitement))

#STATISTIQUES DESCRIPTIVES
cat("\n=== Statistiques descriptives du cholestérol ===\n")

stats_B <- aggregate(
  Cholesterol ~ Groupe_Traitement,
  data = data_B,
  FUN = function(x)
    c(
      mediane = median(x),
      Q1 = quantile(x, 0.25),
      Q3 = quantile(x, 0.75),
      min = min(x),
      max = max(x)
    )
)

print(stats_B)

#VISUALISATION (BOXPLOT)
library(ggplot2)

ggplot(data_B, aes(x = Groupe_Traitement,
                   y = Cholesterol,
                   fill = Groupe_Traitement)) +
  geom_boxplot() +
  labs(
    title = "Distribution du cholestérol selon le groupe de traitement",
    x = "Groupe de traitement",
    y = "Cholestérol"
  ) +
  theme_minimal()

#CHOIX DU TEST STATISTIQUE
# Données quantitatives
# Plusieurs groupes indépendants
# Normalité non garantie
# → Test non paramétrique de Kruskal-Wallis

#TEST DE KRUSKAL-WALLIS
test_res <- kruskal.test(
  Cholesterol ~ Groupe_Traitement,
  data = data_B
)

cat("\n=== Résultat du test de Kruskal-Wallis ===\n")
print(test_res)

#DÉCISION STATISTIQUE
p <- test_res$p.value

cat("\n=== Interprétation ===\n")

if (p < 0.01) {
  cat("→ p < 0.01 : différence hautement significative.\n")
  cat("Conclusion : le taux de cholestérol diffère fortement selon les groupes de traitement.\n")
} else if (p < 0.05) {
  cat("→ 0.01 ≤ p < 0.05 : différence significative.\n")
  cat("Conclusion : le taux de cholestérol dépend du groupe de traitement.\n")
} else {
  cat("→ p ≥ 0.05 : pas de preuve pour rejeter H0.\n")
  cat("Conclusion : aucune différence significative du cholestérol entre les groupes de traitement.\n")
}


############################################################
# HYPOTHÈSE C : Test de corrélation entre Âge et Tension
############################################################
cat("\n=== HYPOTHÈSE C : Test de corrélation entre l'âge et la tension ===\n")

# Créer un dataset pour l'Hypothèse C
data_C <- df[, c("Age", "Tension")]
data_C <- na.omit(data_C)

# Tester la normalité avec Shapiro-Wilk pour Age et Tension
normalite_age <- shapiro.test(data_C$Age)
normalite_tension <- shapiro.test(data_C$Tension)
cat("Test de normalité pour Âge : p-value =", normalite_age$p.value, "\n")
cat("Test de normalité pour Tension : p-value =", normalite_tension$p.value, "\n")

# Choisir la méthode de corrélation selon la normalité
if (normalite_age$p.value > 0.05 & normalite_tension$p.value > 0.05) {
  method <- "pearson"  # Si les deux variables sont normales, utiliser Pearson
} else {
  method <- "kendall"  # Sinon utiliser Kendall
}

# Calcul de la corrélation
res_cor <- cor.test(data_C$Age, data_C$Tension, method = method)
cat("Méthode choisie :", method, "\n")
cat("Résultat du test de corrélation : rho =", res_cor$estimate, "p-value =", res_cor$p.value, "\n")

# Visualisation de la relation entre Âge et Tension avec un nuage de points et une droite de régression
ggplot(data_C, aes(x = Age, y = Tension)) +
  geom_point(alpha = 0.7) +  # Nuage de points
  geom_smooth(method = "lm", se = FALSE, color = "red") +  # Droite de régression
  labs(title = "Relation entre Âge et Tension", x = "Âge", y = "Tension") +
  theme_minimal()

# Interprétation des résultats de la corrélation
if (res_cor$p.value < 0.05) {
  cat("Conclusion : Il existe une relation significative entre l'âge et la tension.\n")
} else {
  cat("Conclusion : Aucune relation significative entre l'âge et la tension.\n")
}

############################################################
# HYPOTHÈSE D : Test du Chi-deux pour sexe et groupe de traitement
############################################################
cat("\n=== HYPOTHÈSE D : Test du Chi-deux pour sexe et groupe de traitement ===\n")

# Créer le tableau de contingence
tab <- table(df$Sexe, df$Groupe_Traitement)
cat("\n=== Tableau de contingence ===\n")
print(tab)

# Choisir le test selon les données (Chi-deux ou Fisher)
if (any(tab < 5)) {
  test_res <- fisher.test(tab)
  test_used <- "Test exact de Fisher"
} else {
  test_res <- chisq.test(tab, correct = TRUE)
  test_used <- "Test du Chi-deux d'indépendance"
}

# Résultats du test
p <- test_res$p.value
cat("\n=== Résultat ===\n")
cat("Test utilisé :", test_used, "\n")
cat("p-value =", format.pval(p, digits = 4), "\n")

# Proportions
prop_tab <- prop.table(tab, margin = 2)
cat("\n=== Proportions par groupe ===\n")
print(round(prop_tab, 3))

# Décision statistique pour Hypothèse D
cat("\n=== Interprétation ===\n")
if (p < 0.01) {
  cat("→ p < 0.01 : différence hautement significative.\n")
  cat("Conclusion : la répartition des sexes diffère fortement selon les traitements.\n")
} else if (p < 0.05) {
  cat("→ 0.01 ≤ p < 0.05 : différence significative.\n")
  cat("Conclusion : la répartition des sexes dépend du traitement.\n")
} else {
  cat("→ p ≥ 0.05 : pas de preuve pour rejeter H0.\n")
  cat("Conclusion : équilibre des sexes entre les groupes.\n")
}

# Visualisation des proportions par groupe
ggplot(as.data.frame(prop_tab), aes(x = Var2, y = Freq, fill = Var1)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_y_continuous(labels = scales::percent_format()) +
  labs(title = "Proportion du sexe selon le groupe de traitement", x = "Groupe de traitement", y = "Proportion") +
  theme_minimal()

