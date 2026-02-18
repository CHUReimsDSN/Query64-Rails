---
title: Recherche rapide
---

# Recherche rapide

La recherche rapide est une fonctionnalité de filtrage global déclenchable depuis l'interface.

## Options

Les options de la recherche rapide permettent de sélectionner les colonnes sur lesquelles le filtre sera appliqué.

```ruby
# default
def self.query64_quick_search_options
  {
    include_string_column: true,
    include_datetime_column: false,
    include_boolean_column: false,
    include_jsonb_column: false,
  }
end
```

::: warning Important 
La recherche rapide applique un filtre sur toutes les colonnes visibles, y compris les associations. 
Chaque association incluse sera donc à configuré si un comportement spécifique est nécessaire.
:::

::: warning Important 
Consulter la [Définition API](/api-definition/models.md#query64_quick_search_options) pour connaitre quelles méthodes reçoivent le contexte.
:::
