class GenericController < ApplicationController

  # POST /api/get-metadata-query64
  def get_metadata_query64
    render json: Query64.get_metadata(Query64.permit_metadata_params(params))
  end

  # POST /api/get-rows-query64
  def get_rows_query64  
    render json: Query64.get_rows(Query64.permit_row_params(params))
  end

  # POST /api/export-rows-query64
  def export_rows_query64
    render json: Query64.export(Query64.permit_row_params(params))
  end

end
