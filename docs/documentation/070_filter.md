---
title: Définitions des filtres
---

# Définitions des filtres

Il est également possible de filtrer les lignes selon une logique.

```ruby
def self.query64_additional_row_filters
  filters = []

  if !User.current&.is_admin?
    # Si l'utilisateur courrant n'est pas administrateur
    # On ajoute un filtre automatique qui
    # Ne prends que les prénoms égale à 'Didier'
    filters << {
        column: 'prenom',
        type: 'equals',
        filter: 'Didier' 
    }
  end

  filters
end
```
