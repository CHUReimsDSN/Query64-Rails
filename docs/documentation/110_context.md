---
title: Contexte
---

# Contexte

Certaines méthodes appelées par Query64 peuvent prendre un paramètre de contexte provenant du client.  
Cet argument permet de définir une logique supplémentaire quant au données générées.
Dans l'exemple suivant, le contexte est défini arbitrairement côté client et injecté dans la méthode.
```ruby 
# context = {
#   name: String
# }
def self.query64_column_builder(context)
  if context[:name] == 'Custom'
    return [
      {
        columns_to_include: ['id', 'prenom', 'nom'],
        statement: -> { User.current != nil }
      }
    ]
  else
    return [
      {
        columns_to_include: ['id', 'age', 'adresse'],
        statement: -> { User.current != nil }
      }
    ]
  end
end
```

::: danger Attention
Le context provient de l'interface, il est donc nécessaire de passer par une étape de purge avant d'effectuer une logique métier.
:::

::: warning Important 
Consulter la [Définition API](/api-definition/models.md) pour connaitre quelles méthodes reçoivent le contexte.
:::

