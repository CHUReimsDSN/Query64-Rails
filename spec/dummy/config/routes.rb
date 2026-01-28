Rails.application.routes.draw do
      scope :api do
        post 'get-metadata-query64', to: 'generic#get_metadata_query64'
        post 'get-rows-query64', to: 'generic#get_rows_query64'
        post 'export-rows-query64', to: 'generic#export_rows_query64'
      end
end
