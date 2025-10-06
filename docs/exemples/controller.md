---
layout: default
title: Utilisation simple dans un controller
---

# Utilisation simple dans un controller

```ruby
# generic_controller.rb
class GenericController < ApplicationController

  # POST /generic/get-metadata-query64
  def get_metadata_query64
    begin
      resource_class = Query64.ensure_params_and_resource_are_valid(params)
      authorize(resource_class, policy_class: GenericPolicy)
      render json: Query64.get_metadata(Query64.permit_metadata_params(params))
    rescue Query64::Query64Exception => exception
      render json: { message: exception.message }, status: exception.http_status
    end
  end

  # POST /generic/get-rows-query64
  def get_rows_query64
    begin
      resource_class = Query64.ensure_params_and_resource_are_valid(params)
      authorize(resource_class, policy_class: GenericPolicy)
      render json: Query64.get_rows(Query64.permit_row_params(params))
    rescue Query64::Query64Exception => exception
      render json: { message: exception.message }, status: exception.http_status
    end
  end

end
```


```ruby
# routes.rb
Rails.application.routes.draw do
  
  scope :api do
    scope :generic do 
      post 'get-metadata-query64', to: 'generic#get_metadata_query64'
      post 'get-rows-query64', to: 'generic#get_rows_query64'
    end
  end

end
```

```ruby
class Article < ApplicationRecord
  extend Query64::MetadataProvider

	def self.query64_column_builder
		[
			{
				columns_to_include: [
					'id', 
					'titre',
					'description',
					'contenu',
					'type_publication'
				],
				statement: -> { true },
			}
		]
	end

	def self.query64_column_dictionary
		{
			type_publication: 'Type de publication',
		}
	end

end
```
