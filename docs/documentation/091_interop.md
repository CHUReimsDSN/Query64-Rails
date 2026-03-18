---
title: Interopérabilité
---

# Interopérabilité

Query64 repose sur la communication entre deux entités.
Dans cette version et pour la pertinance de cette page, nous supposerons qu'un client communique via des appels HTTP,
et que ces appels sont traités dans les contrôleurs de Rails.

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
    render json: Query64.get_rows(Query64.permit_row_params(params), :csv)
  end

  # POST /my-api/export-rows-query64
  def export_rows_query64
    send_data(Query64.export(Query64.permit_row_params(params)),
              filename: "export_#{DateTime.now}.csv", 
              type: "text/csv; charset=utf-8"           
    )
  end

end
```
 
::: warning Important
Les routes doivent toutes utiliser la méthode POST pour recevoir les paramètres du client.
:::

Query64 met également à disposition deux méthodes utilitaires pour assurer la validité
des données reçues :
- `permit_metadata_params`
- `permit_row_params`
