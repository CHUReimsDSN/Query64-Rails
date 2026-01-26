---
title: Export
---

# Export

Une méthode utilitaire de Query64 est mise à disposition pour exporter les données.  
Elle prend un second argument facultatif qui représente le format des données : `:csv`, `:raw`.  

```ruby
class MyController < ApplicationController

  # POST /my-api/export-all-rows-query64
  def export_all_rows_query64
    render json: Query64.export(Query64.permit_row_params(params))
  end

end
```
