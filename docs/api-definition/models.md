---
title: Définition API
---

# Définition API

## query64_column_builder

```ruby
def query64_column_builder: (Context?) -> ColumnBuilder[]
```

```ruby
type Context = Hash[String, untyped]
type ColumnBuilder = {

  # Définit le nom des différentes colonnes à inclure (tout inclure avec : `['#']`) 
  columns_to_include: String[] = []

  # Définit le nom des différentes colonnes à exclure
  columns_to_exclude: String[] = []

  # Callback qui définit si les colonnes doivent être incluses ou non
  statement: () -> Boolean = () -> false

  # Défini la relation
  association_name: Symbol = nil
}
```

<br /><br />

## query64_column_dictionary

```ruby
def query64_column_dictionary: (Context?) -> ColumnDictionary
```

```ruby
type Context = Hash[String, untyped]
type ColumnDictionary = Hash[Symbol, String]
```

<br /><br />

## query64_additional_row_filters

```ruby
def query64_additional_row_filters: (Context?) -> RowFilter
```

```ruby
type Context = Hash[String, untyped]
type RowFilter = {

  # Callback qui définit si les colonnes doivent être incluses ou non
  statement: () -> Boolean = () -> false

  # Filtre défini de la même manière que dans l'AgGrid
  filter: {
    column: String
    type: 'in' | 'contains' | 'equals' | 'notEqual' | 'notContains' | 'empty' | 'blank' | 'notEmpty' | 'greaterThan' | 'lessThan' | 'inRange'
    filter: String
  }
}
```

<br /><br />

## query64_quick_search_options

```ruby
def query64_quick_search_options: (Context?) -> QuickSearchOption
```

```ruby
type Context = Hash[String, untyped]
type QuickSearchOption = {
    include_string_column: Boolean,
    include_number_column: Boolean,
    include_datetime_column: Boolean,
    include_boolean_column: Boolean,
    include_jsonb_column: Boolean,
}
```

<br /><br />