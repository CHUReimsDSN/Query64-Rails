---
title: Démarage rapide
layout: default
nav_order: 40
---
# Démarrage rapide

Activer l'exploitation des données pour un modèle :
```ruby
class MonModele < ApplicationRecord
  extend Query64::MetadataProvider

  def self.query64_column_builder
    [
      {
        columns_to_include: ['*'],
        allowed: -> { true }
      }
    ]
  end

end
```

Obtenir les résultats : 
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