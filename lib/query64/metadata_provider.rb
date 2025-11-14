require 'active_record'

module Query64
        
  module MetadataProvider
    def self.extended(base)
      unless base < ActiveRecord::Base
        raise "#{base} must inherit from ActiveRecord::Base to extend Query64::MetadataProvider"
      end
    end

    def query64_get_builder_metadata(context = nil)
      unless self < ActiveRecord::Base
        raise "Method must be called from ActiveRecord::Base inherited class"
      end

      policies = Query64.try_model_method_with_args(self, :query64_column_builder, context)
      if policies.class != Array
        policies = []
      end

      allowed_columns = []
      policy_base_resource = policies.find do |policy|
        policy[:association_name].nil?
      end
      if policy_base_resource.nil?
        policies.unshift({
          columns_to_include: ['*'],
          statement: -> { true },
        })
      end
      policies.each_with_index do |policy, policy_index|
        index_base = policy_index * 1000
        if policy[:columns_to_include].nil?
          policy[:columns_to_include] = []
        end
        if policy[:columns_to_include].include?('*')
          policy[:columns_to_include] = ['*']
        end
        if policy[:columns_to_exclude].nil?
          policy[:columns_to_exclude] = []
        end
        if policy[:statement].nil?
          policy[:statement] = -> { false }
        end

        result_policy = policy[:statement].call
        if !result_policy
          next
        end
        if !policy[:association_name].nil?
          resource_class = self.reflect_on_association(policy[:association_name])&.klass
        else
          resource_class = self
        end
        if resource_class.nil?
          next
        end
        resource_class_columns = resource_class.column_names

        if policy[:columns_to_include].include?('*')
          resource_class_columns.each_with_index do |column_name, column_index|
            existing_column = allowed_columns.find do |allowed_column|
              allowed_column[:raw_field_name] == column_name && allowed_column[:association_name] == policy[:association_name]
            end
            if existing_column.nil?
              allowed_columns << {
                index: index_base + column_index,
                raw_field_name: column_name,
                association_name: policy[:association_name]
              }
            end
          end
        else
          policy[:columns_to_include].each_with_index do |column, column_index|
            if resource_class_columns.exclude?(column)
              next
            end
            existing_column = allowed_columns.find do |allowed_column|
              allowed_column[:raw_field_name] == column && allowed_column[:association_name] == policy[:association_name]
            end
            if existing_column.nil?
              allowed_columns << {
                index: index_base + column_index,
                raw_field_name: column,
                association_name: policy[:association_name]
              }
            end
          end
        end

        policy[:columns_to_exclude].each do |column|
          index_to_delete = allowed_columns.index do |allowed_column|
            if column == self.primary_key
              next
            end
            allowed_column[:association_name] == policy[:association_name] && allowed_column[:raw_field_name] == column
          end
          if index_to_delete.nil?
            next
          end
          allowed_columns.delete_at(index_to_delete)
        end
      end

      metadata = self.query64_get_all_metadata(context)

      allowed_columns_metadata = metadata.map do |metadat|
        allowed_column_found = allowed_columns.find do |column|
          column[:raw_field_name] == metadat[:raw_field_name] && column[:association_name] == metadat[:association_name]
        end
        if allowed_column_found
          metadat[:index] = allowed_column_found[:index]
        end
        metadat
      end.filter do |metadat|
        metadat[:index] != nil
      end.sort do |metadat_a, metadat_b|
        metadat_a[:index].to_i - metadat_b[:index].to_i
      end
      allowed_columns_metadata
    end

    def query64_get_all_metadata(context = nil)
      metadata = []
      self.columns_hash.each do |key_column, value_column|
        label_name = query64_beautify_column_name(key_column, nil, context)
        field_type = query64_get_column_type_by_sql_type(value_column.type)
        metadata << {
          raw_field_name: key_column,
          field_name: key_column,
          label_name: label_name,
          field_type: field_type,
          association_name: nil,
          association_type: nil,
          association_class_name: nil,
        }
      end

      association_names_done = []
      self.reflect_on_all_associations.each do |association|
        if (association_names_done.include? association.name) || association.klass.nil?
          next
        end
        association_names_done << association.name
        association_class = association.class_name.constantize
        association_class.columns_hash.each do |key_column, value_column|
          label_name = query64_beautify_column_name(key_column, association_class, context)
          field_type = query64_get_column_type_by_sql_type(value_column.type)        
          metadata << { 
            raw_field_name: key_column,
            field_name: query64_serialize_relation_key_column(association, key_column), 
            label_name: label_name,
            field_type: field_type,
            association_name: association.name,
            association_type: association.macro,
            association_class_name: association_class,
          }
        end
      end
      metadata
    end

    def query64_serialize_relation_key_column(association, key_column)
      "#{association.name}.#{key_column}::#{association.macro}"
    end

    def query64_deserialize_relation_key_column(column_string)
      {
        raw_field_name: column_string.include?('.') ? column_string.split('.').second.split('::').first : column_string,
        association_name: column_string.include?('.') ? column_string.split('.').first.to_sym : nil,
        association_type: column_string.split('::').second&.to_sym
      }
    end

    private
    def query64_beautify_column_name(column_name, association_class = nil, context = nil)
      generic_labels = {
        created_at: 'Crée le',
        updated_at: 'Mis à jour le',
        created_by: 'Crée par',
        updated_by: 'Mis à jour par'
      }

      class_column_labels = Query64.try_model_method_with_args(self, :query64_column_dictionary, context)
      if class_column_labels.nil?
        class_column_labels = {}
      end
    
      label_hash = generic_labels.merge(class_column_labels)
      label = label_hash[column_name.to_sym]
      if label.nil?
        label = column_name.capitalize.gsub('_', ' ')
      end
      if !association_class.nil?
        beauty_association_class = association_class
        label = "#{beauty_association_class.to_s} : #{label}"
      end
      label
    end

    def query64_get_column_type_by_sql_type(sql_type)
      field_type = 'string'
      case sql_type
        when :integer
          field_type = 'number'
        when :datetime
          field_type = 'date'
        when :boolean
          field_type = 'boolean'
        when :jsonb
          field_type = 'object'
      end
      field_type.to_sym
    end
  end

end
