<div align="center">
  <img src="./assets/logo.png" alt="Query64 Rails Logo" width="200" />
</div>


# Query64 - Rails

Query64 donne accès à l'exploitation des données des modèles Active Record par les filtres de l'AgGrid.  
L'outil met à disposition : 
- possibilité de gérer les colonnes d'un modèle (et de ses relations) dans l'exploitation
- système de politique de sécurité par colonne 
- système de politique de sécurité par ligne
- système de dictionnaire pour l'affichage des libellés 
- système de génération SQL optimisé 

Cette bibliothèque complémente et est destinée à être utilisée avec Query64 - Vue.

- [Installation](#installation)
- [Utilisation](#utilisation)  
- [Définitions des colonnes](#définitions-des-colonnes)  
- [Définitions des dictionnaires](#définitions-des-dictionnaires)  
- [Définitions de filtre supplémentaire](#définitions-de-filtre-supplémentaire)  
- [Accés propriétés de contexte](#accés-propriétés-de-contexte)  
- [Utilitaire](#utilitaire)
- [Spécificités comportementales](#spécificités-comportementales)
- [Contribuer](#contribuer)

<br /><br />


## Installation

L'installation de la gemme nécessite l'accès au Gitlab.  
**Note :** nécessite les prérequis suivants :    
- PostgreSQL


``` ruby
# Gemfile
gem 'query64', git: 'https://github.com/CHUReimsDSN/Query64-Rails.git'
```

```sh
bundle install
```

<br /><br />

## Utilisation

Activer l'exploitation des données pour un modèle :

``` ruby
# La classe doit hériter de ActiveRecord::Base (ou enfant)

class MonModele < ActiveRecord::Base
  extend Query64::MetaDataProvider

  def self.query64_column_builder
    [
      {
        columns_to_include: ['id', 'nom', 'prenom'],
        allowed: -> (_current_user) { true }
      }
    ]
  end

  def self.query64_column_dictionary
    {
      id: 'Identifiant'
    }
  end
end
```

Définir l'accès à l'utilisateur courrant :
```ruby
class ApplicationController
  before_action do
    Query64.current_user = my_user_current_method
  end
end
```

Obtenir les résultats : 
```ruby
# Dans le contexte où l'on reçoit les paramètres AgGrid dans un controller
class MyController < ApplicationController

  # POST /my-api/get-metadata
  def get_resource_metadata
    render json: Query64.get_metadata(Query64.permit_metadata_params(params))
  end

  # POST /my-api/get-rows
  def get_rows
    render json: Query64.get_rows(Query64.permit_row_params(params))
  end

end
```
<br /><br />


## Définitions des colonnes
Propriétés des hashs :

- `columns_to_include` indique le nom des différentes colonnes à inclure (tout inclure avec : '*') 
- `columns_to_exclude` indique le nom des différentes colonnes à exclure 
- `allowed` callback executer pour définir l'accessibilité aux colonnes incluses 
- `association_name` définition des colones sur une relation 

Exemple : 
```ruby
def self.query64_column_builder
  [
    # Autoriser les colonnes 'id', 'prenom' et 'nom'
    # Pour les utilisateurs connectés
    {
      columns_to_include: ['id', 'prenom', 'nom'],
      allowed: -> (current_user) { current_user != nil }
    },

    # Autoriser toutes les colonnes
    # Sauf la colonne 'libelle'
    # Pour les utilisateurs administrateurs
    # Pour tout les profils de ce model
    {
      columns_to_include: ['*'],
      columns_to_exclude: ['libelle'],
      allowed: -> (current_user) { current_user.is_admin },
      association_name: :profils
    }
  ]
end
```
<br /><br />

## Définitions des dictionnaires
Propriété du hash :

- La clé est le nom de la colonne à renommer
- La valeur est le nom d'affichage de la colonne

Exemple : 
```ruby
# La colonne 'colonne_truc_test' se nommera 'Colonne de test'
def self.query64_column_dictionary
  {
    colonne_truc_test: 'Colonne de test'
  }
end
```

<br /><br />

## Définitions de filtre supplémentaire
Il est possible d'également filtrer les lignes selon des politiques de sécurité.

```ruby
# models/mon_modele.rb

def self.query64_additional_row_filters
  [
    # Si l'utilisateur courrant n'est pas administrateur
    # On ajouter un filtre automatique qui
    # Ne prends que les prénoms égale à 'Didier'
    {
      statement: -> (current_user) { !current_user&.is_admin },
      filter: {
        column: 'prenom',
        type: 'equals',
        filter: 'Didier' 
      }
    }
  ]
end
```

<br /><br />

## Accés propriétés de contexte
Les méthodes définies dans les modeles peuvent reçevoir un argument contenant des informations de contexte transmise depuis l'appel
des méthodes de Query64.  

Exemple de définitions de colonne par template :
```ruby
class MyController < ApplicationController
  # Ici, 'params[:query64Params]' contient une propriété 'context', envoyé par le client
  # On suppose la définition suivante pour cet exemple : 
  #  context: {
  #    template: 'Template1'
  #  }

  # POST /my-api/get-metadata
  def get_resource_metadata
    render json: Query64.get_metadata(Query64.permit_metadata_params(params))
  end

  # POST /my-api/get-rows
  def get_rows
    render json: Query64.get_rows(Query64.permit_row_params(params))
  end

end
```

```ruby
# models/mon_modele.rb

def self.query64_column_builder(context)
  if context[:template] == 'Template1'
    return [
      {
        columns_to_include: ['id', 'prenom', 'nom'],
        allowed: -> (current_user) { current_user != nil }
      }
    ]
  else
    return [
      {
        columns_to_include: ['id', 'age', 'adresse'],
        allowed: -> (current_user) { current_user != nil }
      }
    ]
  end
end
```

Les méthodes `query64_column_builder`, `query64_column_dictionary` et `query64_additional_row_filters` peuvent reçevoir cet argument.

<br /><br />

## Utilitaire

```ruby
# Exemple exception Query64

begin
  results = Query64.get_metadata(params)
rescue Query64::Query64Exception => exception
  render json: { message: exception.message }, status: exception.http_status
end

begin
  results = Query64.get_rows(params)
rescue Query64::Query64Exception => exception
  render json: { message: exception.message }, status: exception.http_status
end
```

```ruby
# Autoriser des paramètres de controller pour avoir les matadata
query64_params = Query64.permit_metadata_params(params)
metadata = Query64.get_metadata(query64_params)

# Autoriser des paramètres de controller pour avoir les résultats
query64_params = Query64.permit_row_params(params)
results = Query64.get_rows(query64_params)
```

<br /><br />

## Spécificités comportementales

- Si au moins une colonne est autorisé à être vu, la clé primaire de la ressource sera automatiquement incluse  

<br /><br />

## Contribuer

Tout signalement de bugs, d'améliorations, et d'actions vertueuses pour Query64 sont les bienvenues.  
L'utilisation des fonctionnalités de Gitlab (branches, issues, etc..) sont fortement recommandées.  

N'oubliez pas de signaler vos breaking-changes (s'il y en a) à l'équipe lors de vos modifications sur la branche principale.    
