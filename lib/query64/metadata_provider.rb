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
        raise Query64Exception.new("Method must be called from ActiveRecord::Base inherited class", 500)
      end

      if !self.respond_to? (:query64_column_builder)
        raise Query64Exception.new("No method 'query64_column_builder' is defined in the #{self.to_s} model", 500)
      end

      entries = Query64.try_model_method_with_args(self, :query64_column_builder, context)
      verify_column_builder_method_return(entries)
      allowed_columns = []
      policy_base_resource = entries.find do |entry|
        entry[:association_name].nil?
      end
      entries.each_with_index do |entry, policy_index|
        index_base = policy_index * 1000
        if entry[:columns_to_include].include?('*')
          entry[:columns_to_include] = ['*']
        end
        if entry[:columns_to_exclude].nil?
          entry[:columns_to_exclude] = []
        end

        if !entry[:association_name].nil?
          resource_class = self.reflect_on_association(entry[:association_name])&.klass
        else
          resource_class = self
        end
        if resource_class.nil?
          next
        end
        resource_class_columns = resource_class.column_names

        if entry[:columns_to_include].include?('*')
          resource_class_columns.each_with_index do |column_name, column_index|
            existing_column = allowed_columns.find do |allowed_column|
              allowed_column[:raw_field_name] == column_name && allowed_column[:association_name] == entry[:association_name]
            end
            if existing_column.nil?
              allowed_columns << {
                index: index_base + column_index,
                raw_field_name: column_name,
                association_name: entry[:association_name]
              }
            end
          end
        else
          entry[:columns_to_include].each_with_index do |column, column_index|
            if resource_class_columns.exclude?(column)
              next
            end
            existing_column = allowed_columns.find do |allowed_column|
              allowed_column[:raw_field_name] == column && allowed_column[:association_name] == entry[:association_name]
            end
            if existing_column.nil?
              allowed_columns << {
                index: index_base + column_index,
                raw_field_name: column,
                association_name: entry[:association_name]
              }
            end
          end
        end

        entry[:columns_to_exclude].each do |column|
          index_to_delete = allowed_columns.index do |allowed_column|
            if column == self.primary_key
              next
            end
            allowed_column[:association_name] == entry[:association_name] && allowed_column[:raw_field_name] == column
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
      beautify_name = -> (name) { name.capitalize.gsub('_', ' ') }
      default_columns_dictionary = query64_get_column_dictionary_pool(self, context)
      self.columns_hash.each do |key_column, value_column|
        label_name = default_columns_dictionary[key_column.to_sym]
        label_name ||= beautify_name.call(key_column)
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
        association_columns_dictionary = query64_get_column_dictionary_pool(association_class, context)
        association_class.columns_hash.each do |key_column, value_column|
          relation_key_name = query64_serialize_relation_key_column(association, key_column)
          label_name = default_columns_dictionary[relation_key_name.to_sym]
          label_name ||= association_columns_dictionary[key_column]
          label_name ||= "#{beautify_name.call(association.name.to_s)} : #{beautify_name.call(key_column)}"
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
      "#{association.name}.#{key_column}"
    end

    def query64_deserialize_relation_key_column(column_string)
      {
        raw_field_name: column_string.include?('.') ? column_string.split('.').second : column_string,
        association_name: column_string.include?('.') ? column_string.split('.').first.to_sym : nil,
      }
    end

    private
    def query64_get_column_dictionary_pool(model_class, context)
      class_column_labels = Query64.try_model_method_with_args(model_class, :query64_column_dictionary, context)
      verify_column_dictionary_method_return(class_column_labels)
      class_column_labels ||= {}
      generic_labels = {
        created_at: 'Créé le',
        updated_at: 'Mis à jour le',
        created_by: 'Créé par',
        updated_by: 'Mis à jour par'
      }
      labels_hash = generic_labels.merge(class_column_labels)
      labels_hash
    end

    def query64_get_column_type_by_sql_type(sql_type)
      field_type = :string
      case sql_type
        when :integer
          field_type = :number
        when :decimal
          field_type = :number
        when :datetime
          field_type = :datetime
        when :date
          field_type = :date
        when :boolean
          field_type = :boolean
        when :jsonb
          field_type = :object
      end
      field_type
    end

    def verify_column_builder_method_return(returned_data)
      return_data_class = returned_data.class
      raise_with_prefix = -> (message) {
        raise Query64Exception.new("Method 'query64_column_builder' from model #{self.to_s} returned an invalid structure. #{message}", 500)
      }
      if return_data_class != Array
        raise_with_prefix.call("Returned type #{return_data_class} instead of Array")
      end
      returned_data.each_with_index do |entry, index_entry|
        if entry[:columns_to_include].nil?
          raise_with_prefix.call("Key 'columns_to_include' cannot be nil (index #{index_entry})")
        end
        if entry[:columns_to_include].class != Array
          raise_with_prefix.call("Key 'columns_to_include' is not an Array (index #{index_entry})")
        end
        if entry[:columns_to_exclude] != nil && entry[:columns_to_exclude].class != Array
          raise_with_prefix.call("Key 'columns_to_exclude' is not an Array or nil (index #{index_entry})")
        end
        if entry[:association_name] != nil && entry[:association_name].class != Symbol
          raise_with_prefix.call("Key 'association_name' is not a Symbol or nil (index #{index_entry})")
        end
      end
    end

    def verify_column_dictionary_method_return(returned_data)
      return_data_class = returned_data.class
      raise_with_prefix = -> (message) {
        raise Query64Exception.new("Method 'query64_column_dictionary' from model #{self.to_s} returned an invalid structure. #{message}", 500)
      }
      if return_data_class != NilClass && return_data_class != Hash 
        raise_with_prefix.call("Returned type #{return_data_class} instead of Hash")
      end
    end

  end

end
