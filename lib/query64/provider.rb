module Query64
  class Provider
    attr_accessor :resource_class,
                  :alias_start_table,
                  :alias_start_table_sub_request,
                  :columns_to_select_meta_data,
                  :limit,
                  :offset,
                  :filters,
                  :filters_quick_search,
                  :groups,
                  :sorts,
                  :joins_data,
                  :group_mode_data,
                  :sub_request_mode,
                  :filters_must_apply,
                  :export_mode,
                  :context

    def initialize(request_params)
      resource_class_name = request_params[:resourceName]
      aggrid_params = request_params[:agGridServerParams] || {}
      columns_to_select_params = request_params[:columnsToDisplay] || []
      quick_search = request_params[:quickSearch] || nil
      context = request_params[:context]

      self.resource_class = resource_class_name.constantize
      self.alias_start_table = "start_table_final"
      self.alias_start_table_sub_request = "start_table_sub_request"
      self.columns_to_select_meta_data = []
      self.filters = []
      self.filters_quick_search = []
      self.groups = []
      self.sorts = []
      self.group_mode_data = nil
      self.joins_data = {}
      self.sub_request_mode = false
      self.filters_must_apply = {}
      self.export_mode = request_params[:export_mode] == true || false
      self.context = context.nil? ? nil : context.to_h
      sanitize_params(aggrid_params, columns_to_select_params)
      add_additional_row_filters(aggrid_params)
      sanitize_limit_and_offset(aggrid_params)
      sanitize_columns(columns_to_select_params)
      sanitize_conditions(aggrid_params)
      sanitize_row_group_cols(aggrid_params)
      sanitize_group_keys(aggrid_params)
      sanitize_sorts(aggrid_params)
      fill_joins_data(columns_to_select_params)
      fill_joins_data_for_count_and_group
      fill_group_mode_data(aggrid_params)
      fill_sub_request_mode
      fill_quick_search_condition(quick_search)
    end

    private
    def sanitize_params(aggrid_params, columns_to_select_params)
      if aggrid_params.nil?
        aggrid_params = {}
      end
      if columns_to_select_params.nil?
        columns_to_select_params = []
      end
    end

    def sanitize_limit_and_offset(aggrid_params)
      if self.export_mode
        self.limit = "NULL"
        self.offset = 0
        return
      end
      limit = aggrid_params[:endRow].to_i - aggrid_params[:startRow].to_i
      if limit > 100 || limit < 0
        limit = 100
      end
      self.limit = limit
      offset = aggrid_params[:startRow].to_i
      if offset < 0
        limit = 0 
      end
      self.offset = offset
    end

    def sanitize_columns(columns_to_select_params)
      self.columns_to_select_meta_data = self.resource_class.query64_get_builder_metadata(self.context).filter do |meta_data|
        columns_to_select_params.find { |column_to_select| column_to_select == meta_data[:field_name] } != nil
      end

      # Ensure primary key of resource is included
      primary_key_column_name = self.resource_class.primary_key
      resource_column_primary_key = self.columns_to_select_meta_data.find do |column_meta_data|
        column_meta_data[:raw_field_name] == primary_key_column_name &&
        column_meta_data[:association_name] == nil
      end
      if resource_column_primary_key.nil?
        resource_column_primary_key = self.resource_class.query64_get_all_metadata(self.context).find do |resource_column_meta_data|
          resource_column_meta_data[:raw_field_name] == primary_key_column_name &&
          resource_column_meta_data[:association_name] == nil
        end
        if resource_column_primary_key.nil?
          raise Query64Exception.new("Column #{self.resource_class.table_name}.#{primary_key_column_name} cannot be found", 404)
        end
        self.columns_to_select_meta_data.unshift(resource_column_primary_key)
      end

      # Ensure joins keys are included
      association_done_names = {}
      self.columns_to_select_meta_data.each do |column_metadata|
        association_name = column_metadata[:association_name]
        if !association_name.nil? && association_done_names[association_name] != true
          find_entries = []
          reflection = self.resource_class.reflect_on_association(association_name)
          if reflection.nil?
            next
          end
          case column_metadata[:association_type]
            when :belongs_to
              find_entries << {
                raw_field_name_to_find: reflection.foreign_key,
                association_name_to_find: nil
              }

            when :has_one, :has_many
              find_entries << {
                raw_field_name_to_find: reflection.association_primary_key,
                association_name_to_find: association_name
              }

            when :has_and_belongs_to_many
              find_entries << {
                raw_field_name_to_find: reflection.foreign_key,
                association_name_to_find: nil
              }
              find_entries << {
                raw_field_name_to_find: reflection.association_primary_key,
                association_name_to_find: association_name
              }
          end

          find_entries.each do |find_entry|
            foreign_column_find = self.columns_to_select_meta_data.find do |column_metadata_find|
              column_metadata_find[:association_name] == find_entry[:association_name_to_find] && 
              column_metadata_find[:raw_field_name] == find_entry[:raw_field_name_to_find]
            end
            
            if foreign_column_find.nil?
              missing_foreing_key = self.resource_class.query64_get_all_metadata(self.context).find do |missing_find|
                missing_find[:association_name] == find_entry[:association_name_to_find] && 
                missing_find[:raw_field_name] == find_entry[:raw_field_name_to_find]
              end
              if !missing_foreing_key.nil?
                self.columns_to_select_meta_data << missing_foreing_key
              end
            end
          end
          association_done_names[association_name] = true
        end
      end
      
      if self.columns_to_select_meta_data.empty?
        raise Query64Exception.new('No column available', 422)
      end
    end

    def sanitize_conditions(aggrid_params)
      filters = aggrid_params[:filterModel] || {}
      filters.each do |column_filter_name, filter_params|
        
        if self.filters_must_apply[column_filter_name] == true
          column_metadata = find_column_metadata_in_select(column_filter_name)
          if column_metadata.nil?
            next
          end
        else
          column_metadata = find_column_metadata(self.resource_class, column_filter_name)
          if column_metadata.nil?
            next
          end
        end
        
        if filter_params[:conditions].nil?
          sanitized_filter_params = {}
          sanitized_filter_params[:operator] = 'AND'
          sanitized_filter_params[:conditions] = [filter_params]
        else
          sanitized_filter_params = filter_params.deep_dup
        end
        sanitized_filter_params[:conditions] = sanitized_filter_params[:conditions].map do |condition|
          if condition[:filterType] == 'set'
            condition[:type] = 'set'
          end
          condition[:type] = ActiveRecord::Base.connection.quote_string(condition[:type].to_s)
          condition[:filter] = ActiveRecord::Base.connection.quote_string(condition[:filter].to_s)
          condition[:filterTo] = ActiveRecord::Base.connection.quote_string(condition[:filterTo].to_s)
          condition[:dateFrom] = ActiveRecord::Base.connection.quote_string(condition[:dateFrom].to_s)
          condition[:dateTo] = ActiveRecord::Base.connection.quote_string(condition[:dateTo].to_s)
          condition[:filters] = (condition[:filters] || []).map { |filter| ActiveRecord::Base.connection.quote_string(filter).to_s }
          condition[:values] = (condition[:values] || []).map { |filter| ActiveRecord::Base.connection.quote_string(filter).to_s }
          condition
        end
        
        sanitized_filter_params[:column_meta_data] = column_metadata
        sanitized_filter_params[:column_filter_name] = column_filter_name
        self.filters << sanitized_filter_params
      end
    end

    def sanitize_row_group_cols(aggrid_params)
      row_group_cols = aggrid_params[:rowGroupCols] || []
      row_group_cols.each do |row_group_col|
        column_metadata = find_column_metadata_in_select(row_group_col[:id])
        next if column_metadata.nil?
        row_group_col[:column_meta_data] = column_metadata
        row_group_col[:id] = ActiveRecord::Base.connection.quote_string(row_group_col[:id]&.to_s)
        self.groups << row_group_col
      end
    end

    def sanitize_group_keys(aggrid_params)
      if self.groups.empty?
        return
      end
      groups_keys = aggrid_params[:groupKeys] || []
      groups_keys.each_with_index do |group_key, index_group_key|
        column_metadata = find_column_metadata_in_select(self.groups[index_group_key][:id])
        next if column_metadata.nil?
        self.filters << {
          conditions: [
            {
              filter: ActiveRecord::Base.connection.quote_string(group_key.to_s),
              filterType: "keyword",
              type: "equals"
            }
          ],
          operator: "AND",
          column_filter_name: self.groups[index_group_key][:id],
          column_meta_data: column_metadata
        }
      end
    end

    def sanitize_sorts(aggrid_params)
      sorts = aggrid_params[:sortModel] || []
      sorts.each do |sort|
        column_meta_data = find_column_metadata_in_select(sort[:colId])
        next if column_meta_data.nil?
        sort[:column_meta_data] = column_meta_data
        if sort[:sort] == 'asc'
          sort[:sort] = 'ASC'
          self.sorts << sort
          next
        end
        if sort[:sort] == 'desc'
          sort[:sort] = 'DESC'
          self.sorts << sort
          next
        end
        raise Query64Exception.new("Sort value #{sort[:colId]} -> '#{sort[:sort]}' incorrect", 400)
      end
    end

    def fill_joins_data(columns_to_select_params)
      self.columns_to_select_meta_data.each do |meta_data|

        next if meta_data[:association_name].nil?
        
        metadata_join_key = self.joins_data.keys.find do |join_data_key|
          join_data_key == meta_data[:association_name]
        end

        if metadata_join_key
          self.joins_data[metadata_join_key][:columns_to_select] << meta_data[:raw_field_name]
          next
        end
        
        association_data = {
          name: meta_data[:association_name],
          target_table_name: meta_data[:association_class_name].table_name,
          target_class_name: meta_data[:association_class_name],
        }
        paths_to_join = get_join_data_recur(self.resource_class, meta_data[:association_name], association_data)

        columns_to_select = [meta_data[:raw_field_name]]

        self.joins_data[meta_data[:association_name]] = {
          alias_label: paths_to_join.last[:foreign_table_alias],
          paths_to_join: paths_to_join,
          paths_to_join_count: Marshal.load(Marshal.dump(paths_to_join)), # TODO deep clone ? should try .deep_dup
          paths_to_join_group: Marshal.load(Marshal.dump(paths_to_join)), # TODO deep clone ? should try .deep_dup
          columns_to_select: columns_to_select,
          enabled_for_count: false,
          enabled_for_group: false,
          enabled_for_sub_request: false
        }
      end
    end

    def get_join_data_recur(klass, association_name, target_association_data)
      paths_to_join = []
      table_name = klass.table_name
      suffix_target_is = "__target_is_#{target_association_data[:name]}"
      suffix_target = "__target"
      if klass.table_name == self.resource_class.table_name
        table_alias = self.alias_start_table
      else
        table_alias = "#{table_name}#{suffix_target_is}"
      end
      reflection = klass.reflect_on_association(association_name)
      base_association_name = association_name
      if reflection.nil?
        association_name = ActiveSupport::Inflector.singularize(association_name)
        reflection = klass.reflect_on_association(association_name)
      end
      if reflection.nil?
        association_name = ActiveSupport::Inflector.plurialize(association_name)
        reflection = klass.reflect_on_association(association_name)
      end
      if reflection.nil?
        # TODO find in klass with reflect on all association
      end
      if reflection.nil?
        raise Query64Exception.new("Association #{table_name}.#{base_association_name} cannot be found", 500)
      end

      case reflection.macro
        when :belongs_to
          foreign_table_name = reflection.klass.table_name
          if foreign_table_name == target_association_data[:target_table_name]
            foreign_table_alias = "#{foreign_table_name}#{suffix_target}"
          else
            foreign_table_alias = "#{foreign_table_name}#{suffix_target_is}"
          end
          foreign_key = reflection.association_primary_key # TODO maybe join_primary_key ?
          primary_key = reflection.join_foreign_key
          paths_to_join << {
            primary_table_name: table_name,
            primary_table_alias: table_alias,
            foreign_table_name: foreign_table_name,
            foreign_table_alias: foreign_table_alias,
            primary_table_key: primary_key,
            foreign_table_key: foreign_key,
          }

        when :has_one, :has_many
          if reflection.options[:through]
            through = reflection.options[:through]
            paths_to_join += get_join_data_recur(klass, through, target_association_data)
            paths_to_join += get_join_data_recur(klass.reflect_on_association(through).klass, association_name, target_association_data)
          else
            foreign_table_name = reflection.klass.table_name
            if foreign_table_name == target_association_data[:target_table_name]
              foreign_table_alias = "#{foreign_table_name}#{suffix_target}"
            else
              foreign_table_alias = "#{foreign_table_name}#{suffix_target_is}"
            end
            primary_key = reflection.association_primary_key  # TODO maybe join_primary_key ?
            foreign_key = reflection.join_foreign_key
            paths_to_join << {
              primary_table_name: table_name,
              primary_table_alias: table_alias,
              foreign_table_name: foreign_table_name,
              foreign_table_alias: foreign_table_alias,
              primary_table_key: primary_key,
              foreign_table_key: foreign_key,
            }
          end

        when :has_and_belongs_to_many
          join_table_name = reflection.join_table
          join_table_alias = "#{join_table_name}#{suffix_target_is}"

          foreign_table_name = reflection.klass.table_name
          foreign_table_alias = "#{foreign_table_name}#{suffix_target}"
          foreign_key_source = reflection.foreign_key  # TODO maybe join_foreign_key ?
          foreign_key_target = reflection.join_foreign_key
          primary_key = reflection.association_primary_key  # TODO maybe join_primary_key ?
          
          paths_to_join << {
            primary_table_name: table_name,
            primary_table_alias: table_alias,
            foreign_table_name: join_table_name,
            foreign_table_alias: join_table_alias,
            primary_table_key: primary_key,
            foreign_table_key: foreign_key_source,
          }
          paths_to_join << {
            primary_table_name: join_table_name,
            primary_table_alias: join_table_alias,
            foreign_table_name: foreign_table_name,
            foreign_table_alias: foreign_table_alias,
            primary_table_key: foreign_key_target,
            foreign_table_key: primary_key,
          }

      end

      paths_to_join
    end
    
    def fill_joins_data_for_count_and_group
      self.filters.each do |filter|
        association_name = filter[:column_meta_data][:association_name]
        if !association_name.nil? && self.joins_data[association_name]
          self.joins_data[association_name][:enabled_for_count] = true
          self.joins_data[association_name][:enabled_for_group] = true
        end
      end
      self.groups.each do |group|
        association_name = group["column_meta_data"]["association_name"]
        if !association_name.nil? && self.joins_data[association_name]
          self.joins_data[association_name][:enabled_for_count] = true
          self.joins_data[association_name][:enabled_for_group] = true
        end
      end
    end

    def fill_group_mode_data(aggrid_params)
      group_keys = aggrid_params[:groupKeys] || []
      if self.groups.empty? || group_keys.count == groups.count
        return
      end

      group_index = group_keys.count
      group = self.groups[group_index]

      column_meta_data = group[:column_meta_data]
      if !column_meta_data[:association_class_name].nil?
        resource_table_name = column_meta_data[:association_class_name].table_name
        join_data = self.joins_data[column_meta_data[:association_name]]
        if !join_data.nil?
          resource_table_alias = join_data[:alias_label]
        else
          raise Query64Exception.new("Join data not found", 500)
        end
      else
        resource_table_name = self.resource_class.table_name
        resource_table_alias = self.alias_start_table
      end

      group_segment_string = []
      self.groups.each_with_index do |entry, entry_index|
        group_segment_string << entry[:id]
        if entry_index == group_index
          break
        end
        group_segment_string << group_keys[entry_index]
      end
      group_segment_string = group_segment_string.join("/")

      self.group_mode_data = {
        group_index: group_index,
        group_column_metadata: column_meta_data,
        group_column_table_name: resource_table_name,
        group_column_table_alias: resource_table_alias,
        group_segment_string: group_segment_string
      }
    end

    def fill_sub_request_mode
      # TODO avoid side effect on joins_data and delay the fill_joins_data
      self.filters.each do |filter|
        association_name = filter[:column_meta_data][:association_name]
        if association_name.nil?
          next
        end
        self.joins_data[association_name][:enabled_for_sub_request] = true
      end
      self.sorts.each do |sort|
        association_name = sort[:column_meta_data][:association_name]
        if association_name.nil?
          next
        end
        self.joins_data[association_name][:enabled_for_sub_request] = true
      end
      if !self.joins_data.empty? && self.group_mode_data.nil?
        self.sub_request_mode = true
      end
      self.joins_data.each do |join_key, join_value|
        if join_value[:enabled_for_sub_request] == true
          join_value[:paths_to_join].first[:primary_table_alias] = self.alias_start_table_sub_request
        end
      end
    end

    def fill_quick_search_condition(quick_search)
      if quick_search.nil?
        return
      end
      sanitized_quick_search = ActiveRecord::Base.connection.quote_string(quick_search.to_s)
      map_model_options = {}
      self.columns_to_select_meta_data.each do |column_to_select_metadata|
        model_name = column_to_select_metadata.association_class_name.to_s
        options = map_model_options[model_name]
        if options.nil?
          options = Query64.try_model_method_with_args(column_to_select_metadata.association_class_name, :query64_quick_search_options, self.context)
          if options.nil?
            options = get_default_quick_search_options
          end
        end
        shall_skip = false
        case column_to_select_metadata.field_type
        when :string
          shall_skip = options[:include_string_column]
        when :date
          shall_skip = options[:include_datetime_column]
        when :boolean
          shall_skip = options[:include_boolean_column]
        when :object
          shall_skip = options[:include_jsonb_column]
        end
        if shall_skip
          next
        end
        filters_quick_search << {
          filter: sanitized_quick_search,
          column_meta_data: column_to_select_metadata,
        }
      end
    end

    def find_column_metadata_in_select(column_serialized_name)
      deserialized_column_filter = self.resource_class.query64_deserialize_relation_key_column(column_serialized_name)
      self.columns_to_select_meta_data.find do |column_to_select|
        deserialized_column_filter[:raw_field_name] == column_to_select[:raw_field_name] &&
          deserialized_column_filter[:association_name] == column_to_select[:association_name]
      end
    end

    def find_column_metadata(resource_class, column_serialized_name)
      deserialized_column_filter = self.resource_class.query64_deserialize_relation_key_column(column_serialized_name)
      resource_class.query64_get_all_metadata(self.context).find do |column_to_select|
        deserialized_column_filter[:raw_field_name] == column_to_select[:raw_field_name] &&
          deserialized_column_filter[:association_name] == column_to_select[:association_name]
      end
    end

    def add_additional_row_filters(aggrid_params)
      if aggrid_params[:filterModel].nil?
        aggrid_params[:filterModel] = {}
      end

      entries_filter = Query64.try_model_method_with_args(self.resource_class, :query64_additional_row_filters, self.context)
      if entries_filter.class != Array
        entries_filter = []
      end
      entries_filter.each do |entry|
        result_statement = entry[:statement].call
        if !result_statement
          next
        end
        column_name = ""
        if entry[:filter][:association_name].nil?
          column_name = entry[:filter][:column]
        else
          association = self.resource_class.reflect_on_association(entry[:filter][:association_name])&.klass
          if association.nil?
            next
          end
          column_name = self.resource_class.query64_serialize_relation_key_column(association, entry[:filter][:column])
        end
        self.filters_must_apply[:column_name] = true
        if entry[:filter][:filterType] == 'set'
          entry[:filter][:filter] = 'set'
        end
        aggrid_params[:filterModel][column_name] = {
          filter: entry[:filter][:filter],
          filterTo: entry[:filter][:filterTo],
          dateFrom: entry[:filter][:dateFrom],
          dateTo: entry[:filter][:dateTo],
          filters: entry[:filter][:filters],
          values: entry[:filter][:values],
          type: entry[:filter][:type],
        }
      end
    end

    def get_default_quick_search_options
      {
        include_string_column: true,
        include_text_column: true,
        include_datetime_column: false,
        include_boolean_column: false,
        include_jsonb_column: false,
      }
    end

  end
end
