---
title: Définitions des colonnes
layout: default
nav_order: 50
---

# Définitions des colonnes

La méthode `query64_column_builder` permet de définir les colonnes pour les intéractions 
côté client.

{: .important }
La classe doit hériter de `ActiveRecord::Base` (ou d’une de ses sous-classes) et doit être statique pour être appelée par Query64.

```ruby
def self.query64_column_builder
  [
    # Autoriser les colonnes 'id', 'prenom' et 'nom'
    # Pour les utilisateurs connectés
    {
      columns_to_include: ['id', 'prenom', 'nom'],
      statement: -> { User.current != nil }
    },

    # Autoriser toutes les colonnes
    # Sauf la colonne 'libelle'
    # Pour les utilisateurs administrateurs
    # Pour tout les profils de ce model
    {
      columns_to_include: ['*'],
      columns_to_exclude: ['libelle'],
      statement: -> { User.current&.is_admin? },
      association_name: :profils
    }
  ]
end
```

## Options

Les options suivantes sont disponibles : 

- `columns_to_include`: __string[] = ['*']__ -> Définit le nom des différentes colonnes à inclure (tout inclure avec : `['*']`) 
- `columns_to_exclude`: __string[] = []__ -> Définit le nom des différentes colonnes à exclure 
- `statement`: __() -> bool = () -> false__ -> Callback qui définit si les colonnes doivent être incluses ou non
- `association_name`: __Symbol = nil__ -> Définit la relation
