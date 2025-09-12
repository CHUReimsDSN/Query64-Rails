---
title: Interopérabilité
layout: default
nav_order: 90
---
# Interopérabilité

Query64 repose sur la communication entre un client et un serveur.
Dans cette version Rails, on suppose que le client communique via des appels HTTP,
et que ces appels sont traités dans les contrôleurs.

## Controllers

Query64 définit trois méthodes pour interagir avec le client : 
- `get_metadata`
- `get_rows`

```ruby
class MyController < ApplicationController

  # POST /my-api/get-metadata-query64
  def get_metadata_query64
    render json: Query64.get_metadata(Query64.permit_metadata_params(params))
  end

  # POST /my-api/get-rows-query64
  def get_rows_query64
    render json: Query64.get_rows(Query64.permit_row_params(params))
  end

end
```

{: .important }
Les routes doivent utiliser les méthodes POST / PUT / PATCH pour recevoir les données du client.

Query64 met également à disposition deux méthodes utilitaires pour assurer la validité
des données reçues :
- `permit_metadata_params`
- `permit_row_params`
