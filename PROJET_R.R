############################################################
# PROJET STATISTIQUE MÉDICAL
# Version corrigée :
# - Analyse descriptive
# - Valeurs manquantes
# - Outliers
# - Corrélations
# - Comparaison des moyennes
# - Comparaison des variances
# - Comparaison des proportions
############################################################


############################################################
# 1. INSTALLATION ET CHARGEMENT DES PACKAGES
############################################################

packages <- c(
  "tidyverse",
  "skimr",
  "GGally",
  "stringi",
  "reshape2",
  "naniar",
  "scales",
  "FSA"
)

install_if_missing <- function(pkg) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
    library(pkg, character.only = TRUE)
  }
}

invisible(lapply(packages, install_if_missing))


############################################################
# 2. IMPORTATION DU JEU DE DONNÉES
############################################################

data <- read.csv(
  "C:/Users/boub0/Desktop/stat/patients_medical_data.csv",
  sep = ";",
  header = TRUE
)

cat("\n=== APERÇU DES DONNÉES ===\n")
print(head(data))

cat("\n=== STRUCTURE DES DONNÉES ===\n")
str(data)

cat("\n=== RÉSUMÉ STATISTIQUE ===\n")
summary(data)


############################################################
# 3. GESTION DES VALEURS MANQUANTES
############################################################

cat("\n=== VALEURS MANQUANTES AVANT TRAITEMENT ===\n")
na_avant <- colSums(is.na(data))
print(na_avant)

total_na_avant <- sum(is.na(data))

impute_median <- function(x) {
  x[is.na(x)] <- median(x, na.rm = TRUE)
  return(x)
}

numeric_cols <- c(
  "Age",
  "Poids",
  "Tension",
  "Cholesterol",
  "Suivi_Jours",
  "Symptom_Score"
)

numeric_cols <- numeric_cols[numeric_cols %in% colnames(data)]

data[numeric_cols] <- lapply(data[numeric_cols], impute_median)

cat("\n=== VALEURS MANQUANTES APRÈS TRAITEMENT ===\n")
na_apres <- colSums(is.na(data))
print(na_apres)

cat("\nTotal NA avant :", total_na_avant, "\n")
cat("Total NA après :", sum(na_apres), "\n")
cat("Nombre de NA traités :", total_na_avant - sum(na_apres), "\n")


############################################################
# 4. CONVERSION DES TYPES DE DONNÉES
############################################################

df <- data %>%
  mutate(
    Sexe = as.factor(Sexe),
    Groupe_Traitement = as.factor(Groupe_Traitement),
    ID = as.integer(ID)
  )

cat("\n=== STRUCTURE APRÈS CONVERSION ===\n")
str(df)


############################################################
# 5. DÉTECTION ET SUPPRESSION DES DOUBLONS
############################################################

cat("\n=== DOUBLONS ===\n")
cat("Nombre de doublons avant suppression :", sum(duplicated(df)), "\n")

df <- df[!duplicated(df), ]

cat("Nombre de doublons après suppression :", sum(duplicated(df)), "\n")


############################################################
# 6. DÉTECTION DES OUTLIERS PAR LA MÉTHODE IQR
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

for (v in numeric_cols) {
  if (v %in% names(df)) {
    afficher_outliers(df, v)
  }
}


############################################################
# 7. VISUALISATION DES OUTLIERS
############################################################

df_long_boxplot <- df %>%
  select(any_of(numeric_cols)) %>%
  pivot_longer(
    cols = everything(),
    names_to = "Variable",
    values_to = "Valeur"
  )

ggplot(df_long_boxplot, aes(x = Variable, y = Valeur, fill = Variable)) +
  geom_boxplot() +
  labs(
    title = "Boxplots des variables numériques",
    x = "Variable",
    y = "Valeur"
  ) +
  theme_minimal() +
  theme(legend.position = "none")


############################################################
# 8. ANALYSE UNIVARIÉE
############################################################

cat("\n=== ANALYSE UNIVARIÉE ===\n")

for (v in numeric_cols) {
  if (v %in% names(df)) {
    hist(
      df[[v]],
      col = "lightblue",
      main = paste("Distribution de", v),
      xlab = v
    )
  }
}


############################################################
# 9. COURBES DE DENSITÉ
############################################################

num_data <- df %>%
  select(where(is.numeric))

df_long_density <- num_data %>%
  pivot_longer(
    cols = everything(),
    names_to = "Variable",
    values_to = "Valeur"
  )

ggplot(df_long_density, aes(x = Valeur, fill = Variable)) +
  geom_density(alpha = 0.7) +
  facet_wrap(~ Variable, scales = "free") +
  labs(
    title = "Courbes de densité des variables numériques",
    x = "Valeur",
    y = "Densité"
  ) +
  theme_minimal() +
  theme(legend.position = "none")


############################################################
# 10. ANALYSE BIVARIÉE : MATRICE DE CORRÉLATION
############################################################

num_data <- df %>%
  select(where(is.numeric))

corr <- cor(num_data, use = "complete.obs")

cat("\n=== MATRICE DE CORRÉLATION ===\n")
print(round(corr, 2))

corr_df <- melt(corr)

ggplot(corr_df, aes(Var1, Var2, fill = value)) +
  geom_tile(color = "white") +
  geom_text(aes(label = round(value, 2)), color = "black", size = 3) +
  scale_fill_gradient2(
    low = "blue",
    high = "red",
    mid = "white",
    midpoint = 0,
    limit = c(-1, 1),
    name = "Corr"
  ) +
  theme_minimal() +
  labs(
    title = "Matrice de corrélation",
    x = "",
    y = ""
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


############################################################
# 11. PARAMÈTRE GÉNÉRAL DES TESTS
############################################################

alpha <- 0.05

interpret_pvalue <- function(p) {
  if (p < alpha) {
    cat("Décision : p-value <", alpha, "=> on rejette H0.\n")
    cat("Conclusion : différence statistiquement significative.\n")
  } else {
    cat("Décision : p-value >=", alpha, "=> on ne rejette pas H0.\n")
    cat("Conclusion : aucune différence statistiquement significative.\n")
  }
}


############################################################
# 12. FONCTION : COMPARAISON DES MOYENNES
############################################################

test_moyenne <- function(df, variable, groupe = "Groupe_Traitement") {
  
  cat("\n====================================================\n")
  cat("COMPARAISON DES MOYENNES :", variable, "selon", groupe, "\n")
  cat("====================================================\n")
  
  d <- df[, c(variable, groupe)]
  d <- na.omit(d)
  
  d[[groupe]] <- as.factor(d[[groupe]])
  d[[variable]] <- as.numeric(d[[variable]])
  
  formule <- as.formula(paste(variable, "~", groupe))
  nb_groupes <- length(levels(d[[groupe]]))
  
  ############################################################
  # Statistiques descriptives
  ############################################################
  
  stats_desc <- d %>%
    group_by(.data[[groupe]]) %>%
    summarise(
      n = n(),
      moyenne = mean(.data[[variable]], na.rm = TRUE),
      variance = var(.data[[variable]], na.rm = TRUE),
      ecart_type = sd(.data[[variable]], na.rm = TRUE),
      mediane = median(.data[[variable]], na.rm = TRUE),
      min = min(.data[[variable]], na.rm = TRUE),
      max = max(.data[[variable]], na.rm = TRUE),
      .groups = "drop"
    )
  
  cat("\n--- Statistiques descriptives par groupe ---\n")
  print(stats_desc)
  
  ############################################################
  # Test de normalité par groupe
  ############################################################
  
  normalite <- d %>%
    group_by(.data[[groupe]]) %>%
    summarise(
      n = n(),
      p_shapiro = ifelse(
        n() >= 3 & n() <= 5000,
        shapiro.test(.data[[variable]])$p.value,
        NA
      ),
      .groups = "drop"
    )
  
  cat("\n--- Test de normalité Shapiro-Wilk par groupe ---\n")
  print(normalite)
  
  normalite_ok <- all(normalite$p_shapiro > alpha, na.rm = TRUE)
  
  ############################################################
  # Test d’égalité des variances
  ############################################################
  
  test_var <- fligner.test(formule, data = d)
  
  cat("\n--- Test d’égalité des variances : Fligner-Killeen ---\n")
  print(test_var)
  
  variances_egales <- test_var$p.value > alpha
  
  ############################################################
  # Choix automatique du test
  ############################################################
  
  if (nb_groupes == 2) {
    
    if (normalite_ok && variances_egales) {
      
      cat("\nTest choisi : t-test de Student\n")
      cat("Raison : 2 groupes, normalité respectée, variances égales.\n")
      
      res <- t.test(formule, data = d, var.equal = TRUE)
      print(res)
      interpret_pvalue(res$p.value)
      
    } else if (normalite_ok && !variances_egales) {
      
      cat("\nTest choisi : Welch t-test\n")
      cat("Raison : 2 groupes, normalité respectée, variances différentes.\n")
      
      res <- t.test(formule, data = d, var.equal = FALSE)
      print(res)
      interpret_pvalue(res$p.value)
      
    } else {
      
      cat("\nTest choisi : Wilcoxon-Mann-Whitney\n")
      cat("Raison : normalité non respectée.\n")
      cat("Attention : ce test compare les distributions/rangs, pas directement les moyennes.\n")
      
      res <- wilcox.test(formule, data = d)
      print(res)
      interpret_pvalue(res$p.value)
    }
    
  } else {
    
    if (normalite_ok && variances_egales) {
      
      cat("\nTest choisi : ANOVA classique\n")
      cat("Raison : plus de 2 groupes, normalité respectée, variances égales.\n")
      
      res <- aov(formule, data = d)
      print(summary(res))
      
      p_anova <- summary(res)[[1]][["Pr(>F)"]][1]
      interpret_pvalue(p_anova)
      
    } else if (normalite_ok && !variances_egales) {
      
      cat("\nTest choisi : Welch ANOVA\n")
      cat("Raison : plus de 2 groupes, normalité respectée, variances différentes.\n")
      
      res <- oneway.test(formule, data = d, var.equal = FALSE)
      print(res)
      interpret_pvalue(res$p.value)
      
    } else {
      
      cat("\nTest choisi : Kruskal-Wallis\n")
      cat("Raison : normalité non respectée.\n")
      cat("Attention : Kruskal-Wallis compare les rangs/distributions, pas directement les moyennes.\n")
      
      res <- kruskal.test(formule, data = d)
      print(res)
      interpret_pvalue(res$p.value)
      
      if (res$p.value < alpha) {
        cat("\nPost-hoc recommandé : test de Dunn\n")
        print(FSA::dunnTest(formule, data = d, method = "bonferroni"))
      }
    }
  }
  
  ############################################################
  # Graphique
  ############################################################
  
  p <- ggplot(d, aes(x = .data[[groupe]], y = .data[[variable]], fill = .data[[groupe]])) +
    geom_boxplot(alpha = 0.7) +
    stat_summary(
      fun = mean,
      geom = "point",
      shape = 20,
      size = 4,
      color = "red"
    ) +
    labs(
      title = paste("Comparaison de la moyenne de", variable, "selon", groupe),
      subtitle = "Point rouge = moyenne",
      x = groupe,
      y = variable
    ) +
    theme_minimal()
  
  print(p)
}


############################################################
# 13. FONCTION : COMPARAISON DES VARIANCES
############################################################

test_variance <- function(df, variable, groupe = "Groupe_Traitement") {
  
  cat("\n====================================================\n")
  cat("COMPARAISON DES VARIANCES :", variable, "selon", groupe, "\n")
  cat("====================================================\n")
  
  d <- df[, c(variable, groupe)]
  d <- na.omit(d)
  
  d[[groupe]] <- as.factor(d[[groupe]])
  d[[variable]] <- as.numeric(d[[variable]])
  
  formule <- as.formula(paste(variable, "~", groupe))
  nb_groupes <- length(levels(d[[groupe]]))
  
  ############################################################
  # Variance par groupe
  ############################################################
  
  stats_var <- d %>%
    group_by(.data[[groupe]]) %>%
    summarise(
      n = n(),
      variance = var(.data[[variable]], na.rm = TRUE),
      ecart_type = sd(.data[[variable]], na.rm = TRUE),
      .groups = "drop"
    )
  
  cat("\n--- Variance et écart-type par groupe ---\n")
  print(stats_var)
  
  ############################################################
  # Test robuste des variances
  ############################################################
  
  cat("\nTest choisi : Fligner-Killeen\n")
  cat("Raison : test robuste pour comparer les variances entre plusieurs groupes.\n")
  
  res <- fligner.test(formule, data = d)
  
  cat("\n--- Résultat du test de variance ---\n")
  print(res)
  
  cat("\n--- Interprétation ---\n")
  
  if (res$p.value < alpha) {
    cat("Conclusion : les variances sont significativement différentes entre les groupes.\n")
  } else {
    cat("Conclusion : aucune différence significative des variances entre les groupes.\n")
  }
  
  ############################################################
  # Cas particulier : seulement 2 groupes
  ############################################################
  
  if (nb_groupes == 2) {
    cat("\nInformation complémentaire : comme il y a 2 groupes, on peut aussi afficher var.test.\n")
    cat("Attention : var.test suppose une normalité des données.\n")
    
    res_var_test <- var.test(formule, data = d)
    print(res_var_test)
  }
  
  ############################################################
  # Graphique
  ############################################################
  
  p <- ggplot(d, aes(x = .data[[groupe]], y = .data[[variable]], fill = .data[[groupe]])) +
    geom_boxplot(alpha = 0.7) +
    labs(
      title = paste("Comparaison des variances de", variable, "selon", groupe),
      x = groupe,
      y = variable
    ) +
    theme_minimal()
  
  print(p)
}


############################################################
# 14. FONCTION : COMPARAISON DES PROPORTIONS
############################################################

test_proportion <- function(df, variable_cat, groupe = "Groupe_Traitement") {
  
  cat("\n====================================================\n")
  cat("COMPARAISON DES PROPORTIONS :", variable_cat, "selon", groupe, "\n")
  cat("====================================================\n")
  
  d <- df[, c(variable_cat, groupe)]
  d <- na.omit(d)
  
  d[[variable_cat]] <- as.factor(d[[variable_cat]])
  d[[groupe]] <- as.factor(d[[groupe]])
  
  ############################################################
  # Tableau de contingence
  ############################################################
  
  tab <- table(d[[variable_cat]], d[[groupe]])
  
  cat("\n--- Tableau de contingence ---\n")
  print(tab)
  
  ############################################################
  # Proportions
  ############################################################
  
  prop_tab <- prop.table(tab, margin = 2)
  
  cat("\n--- Proportions par groupe ---\n")
  print(round(prop_tab, 3))
  
  ############################################################
  # Choix du test : Chi-deux ou Fisher
  ############################################################
  
  chi <- suppressWarnings(chisq.test(tab, correct = FALSE))
  
  cat("\n--- Effectifs attendus ---\n")
  print(round(chi$expected, 2))
  
  if (any(chi$expected < 5)) {
    
    cat("\nTest choisi : Test exact de Fisher\n")
    cat("Raison : certains effectifs attendus sont inférieurs à 5.\n")
    
    res <- fisher.test(tab)
    
  } else {
    
    cat("\nTest choisi : Test du Chi-deux d’indépendance\n")
    cat("Raison : les effectifs attendus sont suffisants.\n")
    
    res <- chisq.test(tab, correct = FALSE)
  }
  
  cat("\n--- Résultat du test de proportion ---\n")
  print(res)
  
  cat("\n--- Interprétation ---\n")
  
  if (res$p.value < alpha) {
    cat("Conclusion : les proportions sont significativement différentes selon les groupes.\n")
  } else {
    cat("Conclusion : aucune différence significative des proportions selon les groupes.\n")
  }
  
  ############################################################
  # Graphique
  ############################################################
  
  prop_df <- as.data.frame(prop_tab)
  colnames(prop_df) <- c(variable_cat, groupe, "Proportion")
  
  p <- ggplot(prop_df, aes(x = .data[[groupe]], y = Proportion, fill = .data[[variable_cat]])) +
    geom_bar(stat = "identity", position = "dodge") +
    scale_y_continuous(labels = scales::percent_format()) +
    labs(
      title = paste("Comparaison des proportions de", variable_cat, "selon", groupe),
      x = groupe,
      y = "Proportion"
    ) +
    theme_minimal()
  
  print(p)
}


############################################################
# 15. FONCTION : TEST DE CORRÉLATION
############################################################

test_correlation <- function(df, var1, var2) {
  
  cat("\n====================================================\n")
  cat("TEST DE CORRÉLATION :", var1, "et", var2, "\n")
  cat("====================================================\n")
  
  d <- df[, c(var1, var2)]
  d <- na.omit(d)
  
  d[[var1]] <- as.numeric(d[[var1]])
  d[[var2]] <- as.numeric(d[[var2]])
  
  ############################################################
  # Normalité
  ############################################################
  
  shapiro_var1 <- shapiro.test(d[[var1]])
  shapiro_var2 <- shapiro.test(d[[var2]])
  
  cat("\n--- Test de normalité ---\n")
  cat(var1, ": p-value =", shapiro_var1$p.value, "\n")
  cat(var2, ": p-value =", shapiro_var2$p.value, "\n")
  
  ############################################################
  # Choix Pearson ou Spearman
  ############################################################
  
  if (shapiro_var1$p.value > alpha && shapiro_var2$p.value > alpha) {
    methode <- "pearson"
    cat("\nMéthode choisie : Pearson\n")
    cat("Raison : les deux variables suivent approximativement une loi normale.\n")
  } else {
    methode <- "spearman"
    cat("\nMéthode choisie : Spearman\n")
    cat("Raison : au moins une variable ne suit pas une loi normale.\n")
  }
  
  res <- cor.test(d[[var1]], d[[var2]], method = methode)
  
  cat("\n--- Résultat du test de corrélation ---\n")
  print(res)
  
  cat("\n--- Interprétation ---\n")
  
  if (res$p.value < alpha) {
    cat("Conclusion : il existe une relation significative entre", var1, "et", var2, ".\n")
  } else {
    cat("Conclusion : aucune relation significative entre", var1, "et", var2, ".\n")
  }
  
  ############################################################
  # Graphique
  ############################################################
  
  p <- ggplot(d, aes(x = .data[[var1]], y = .data[[var2]])) +
    geom_point(alpha = 0.7) +
    geom_smooth(method = "lm", se = FALSE, color = "red") +
    labs(
      title = paste("Relation entre", var1, "et", var2),
      x = var1,
      y = var2
    ) +
    theme_minimal()
  
  print(p)
}


############################################################
# 16. APPLICATION DES TESTS SUR LE PROJET
############################################################

############################################################
# HYPOTHÈSE A :
# Symptom_Score selon le groupe de traitement
############################################################

cat("\n\n############################################################\n")
cat("HYPOTHÈSE A : Symptom_Score selon le groupe de traitement\n")
cat("############################################################\n")

test_moyenne(df, "Symptom_Score", "Groupe_Traitement")
test_variance(df, "Symptom_Score", "Groupe_Traitement")


############################################################
# HYPOTHÈSE B :
# Cholesterol selon le groupe de traitement
############################################################

cat("\n\n############################################################\n")
cat("HYPOTHÈSE B : Cholesterol selon le groupe de traitement\n")
cat("############################################################\n")

test_moyenne(df, "Cholesterol", "Groupe_Traitement")
test_variance(df, "Cholesterol", "Groupe_Traitement")


############################################################
# HYPOTHÈSE C :
# Corrélation entre Age et Tension
############################################################

cat("\n\n############################################################\n")
cat("HYPOTHÈSE C : Corrélation entre Age et Tension\n")
cat("############################################################\n")

test_correlation(df, "Age", "Tension")


############################################################
# HYPOTHÈSE D :
# Proportion du Sexe selon le groupe de traitement
############################################################

cat("\n\n############################################################\n")
cat("HYPOTHÈSE D : Proportion du Sexe selon le groupe de traitement\n")
cat("############################################################\n")

test_proportion(df, "Sexe", "Groupe_Traitement")


############################################################
# 17. CONCLUSION AUTOMATIQUE GÉNÉRALE
############################################################

cat("\n\n====================================================\n")
cat("CONCLUSION GÉNÉRALE\n")
cat("====================================================\n")

