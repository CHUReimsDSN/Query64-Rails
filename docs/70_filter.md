---
title: Définitions des filtres
---

# Définitions des filtres

Il est également possible de filtrer les lignes selon une logique.

```ruby
def self.query64_additional_row_filters
  [
    # Si l'utilisateur courrant n'est pas administrateur
    # On ajoute un filtre automatique qui
    # Ne prends que les prénoms égale à 'Didier'
    {
      statement: -> { !User.current&.is_admin? },
      filter: {
        column: 'prenom',
        type: 'equals',
        filter: 'Didier' 
      }
    }
  ]
end
```
