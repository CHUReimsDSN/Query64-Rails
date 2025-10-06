---
title: Définitions des dictionnaires
---

# Définitions des dictionnaires

La méthode `query64_column_dictionary` permet de définir en amont un libellé pour renommer
les colonnes.

Propriété du hash :

- La clé est le nom de la colonne à renommer
- La valeur est le nom d'affichage de la colonne

```ruby
# La colonne 'colonne_truc_test' se nommera 'Colonne de test' côté client
def self.query64_column_dictionary
  {
    colonne_truc_test: 'Colonne de test'
  }
end
```