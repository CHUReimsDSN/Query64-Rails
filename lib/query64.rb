# frozen_string_literal: true

require_relative "query64/builder"
require_relative "query64/metadata_provider"
require_relative "query64/provider"
require_relative "query64/query64_exception"
require_relative "query64/utils"
require_relative "query64/version"

module Query64

  def self.get_metadata(params)
    safe_exec do
      resource_class = ensure_params_and_resource_are_valid(params)
      context = params[:query64Params][:context]
      if context != nil
        context = context.to_h
      end
      resource_class.query64_get_data_table_meta_data(context)
    end    
  end

  def self.get_rows(params)
    safe_exec do
      ensure_params_and_resource_are_valid(params)
      Builder.get_results(params[:query64Params])
    end
  end

  def self.ensure_params_and_resource_are_valid(params)
    if !params[:query64Params]
      raise Query64Exception.new("Invalid params", 400)
    end
    resource_name = params[:query64Params][:resourceName]
    begin
      resource_class = resource_name.constantize
    rescue Exception
      raise Query64Exception.new("This resource does not exist : #{resource_name}", 400)
    end
    if !resource_class.singleton_class.ancestors.include?(Query64::MetadataProvider)
      raise Query64Exception.new("This resource does not extend Query64 : #{resource_name}", 400)
    end
    resource_class
  end


  private
  def self.safe_exec
    begin
      yield
    rescue => e
      if e.class == Query64Exception
        http_status = e.http_status
      else
        http_status = 500
      end
      exception = Query64Exception.new_with_prefix("An error has occured : #{e}", http_status)
      exception.set_backtrace(e.backtrace)
      raise exception
    end
  end

  private_constant :Builder
  private_constant :Provider
end
