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

{: .warning }
Ne pas se baser sur le contexte pour définir des politiques de sécurité, 
car celui-ci provient entièrement du client.

{: .important }
Consulter les [Définitions]({% link 800_definitions.md %}) pour savoir quelles méthodes reçoivent le contexte
