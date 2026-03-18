---
title: Export
---

# Export

Une méthode utilitaire de Query64 est mise à disposition pour exporter les données.  
Elle prend un second argument facultatif qui représente le format des données : `:csv`, `:raw`.  

```ruby
def export_all_rows_query64
  rows_csv = Query64.export(Query64.permit_row_params(params), :csv)
end
```
