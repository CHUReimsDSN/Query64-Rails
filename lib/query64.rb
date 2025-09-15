# frozen_string_literal: true

require_relative "query64/builder"
require_relative "query64/metadata_provider"
require_relative "query64/provider"
require_relative "query64/query64_exception"
require_relative "query64/utils"
require_relative "query64/version"

module Query64
  def self.get_rows(params)
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
    Builder.get_results(params[:query64Params])
  end

  def self.get_metadata(params)
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
    context = params[:query64Params][:context]
    if context != nil
      context = context.to_h
    end
    resource_class.query64_get_data_table_meta_data(context)
  end

  private_constant :Builder
  private_constant :Provider
end
