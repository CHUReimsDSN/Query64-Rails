---
title: Changelog
---

# Changelog

### 2.1.1

- Correction des tableaux vides pour les filtres de type `in` et `notIn` et `set`

---
### 2.1.0

- Les données des colonnes comportent désormais les informations de clé primaire et étrangère

---
# 2.0.0

__Nouveautés__ :

- Les méthodes `query64_additional_row_filters`, `query64_quick_search_columns`, `query64_column_dictionary` et `query64_column_builder` ont désormais une garde sur la structure renvoyer par ces méthodes, afin d'indiquer des définitions invalides
- La méthode `query64_column_dictionary` permet désormais de définir un dictionnaire pour les noms des colonnes des relations

__Changements__ :

- Les filtres de `query64_additional_row_filters` sont désormais toujours appliqués même si les colonnes ne sont pas démandées coté client
- Suppression des clés `statements` pour les méthodes de modèle

__Corrections__ :

- Correction des données de jointure

---
### 1.5.9

- Correction d'un crash concernant les filtres déclarés dans la méthode `query64_additional_row_filters`

---
### 1.5.8

- Les filtres de `query64_additional_row_filters` sont désormais toujours appliqués même si les colonnes ne sont pas démandées coté client

---
### 1.5.7

- Correction des filtres `equals` sur les champs de type `date`et `datetime`

---
### 1.5.6

- Prise en compte des types `date` pour PostgreSQL

---
### 1.5.5

- Ajout du `notIn` pour les filtres de `query64_additional_row_filters`

---
### 1.5.4

- Correction des dictionnaires sur les champs d'association

---
### 1.5.3

- Ajout de la recherche rapide

---
### 1.5.2

- Correction des filtres vides pour l'opérateur `equals` pour les `string` et les `date`

---
### 1.5.1

- Gestion complémentaire des `in` et des `set` pour les filtres

---
### 1.5.0

- Nouvelle doc

