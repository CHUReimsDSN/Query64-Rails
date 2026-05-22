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
  columns = []

  # Autoriser les colonnes 'id', 'prenom' et 'nom'
  # Pour les utilisateurs connectés
  if User.current != nil
    columns << {
      columns_to_include: ['id', 'prenom', 'nom'],
    }
  end

  # Autoriser toutes les colonnes
  # Sauf la colonne 'libelle'
  # Pour les utilisateurs administrateurs
  # Pour tout les profils de ce model
  if User.current&.is_admin?
    columns << {
      columns_to_include: ['*'],
      columns_to_exclude: ['libelle'],
      association_name: :profils
    }
  end

  columns
end
```
