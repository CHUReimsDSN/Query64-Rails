---
title: Définitions des colonnes
---

# Définitions des colonnes

La méthode `query64_column_builder` permet de définir les colonnes pour les intéractions 
côté client.

::: warning Important
La classe doit hériter de `ActiveRecord::Base` (ou d’une de ses sous-classes).
:::

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
