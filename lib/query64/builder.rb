module Query64

  class Builder
    attr_accessor :provider,
                  :shall_return_count,
                  :sql_string_hash

    def self.get_results(params)
      instance = self.new(params)
      instance.build_select_sql
      instance.build_joins_sql
      instance.build_where_filters_sql
      instance.build_sort_sql
      instance.build_limit_and_offset_sql
      instance.build_groups_sql
      instance.get_results
    end

    def build_select_sql
      column_select_array = []
      column_select_sub_request_array = []
      column_select_on_array = ["#{self.provider.alias_start_table}.#{self.provider.resource_class.primary_key}"]
      column_select_on_sub_request_array = ["#{self.provider.alias_start_table_sub_request}.#{self.provider.resource_class.primary_key}"]
      if self.provider.group_mode_data
        self.sql_string_hash[:select_clause_count] = "SELECT"
        self.sql_string_hash[:select_count] = "COUNT(DISTINCT COALESCE(#{self.provider.group_mode_data[:group_column_table_alias]}.#{self.provider.group_mode_data[:group_column_metadata][:raw_field_name]}::text, '<<NULL>>'))"  
        self.sql_string_hash[:from_count] = "FROM #{self.provider.resource_class.table_name} AS #{self.provider.alias_start_table}"
        self.sql_string_hash[:select_group_clause] = "SELECT"
        group_columns = []
        group_columns << "COUNT (#{self.provider.alias_start_table}.#{self.provider.resource_class.primary_key})"
        group_columns << "#{self.provider.group_mode_data[:group_column_table_alias]}.#{self.provider.group_mode_data[:group_column_metadata][:raw_field_name]}"
        self.sql_string_hash[:select_group_columns] = group_columns.join(', ')
        self.sql_string_hash[:from_group] ="FROM #{self.provider.resource_class.table_name} AS #{self.provider.alias_start_table}"
        return
      end
      self.sql_string_hash[:select_clause_count] = "SELECT"
      self.sql_string_hash[:select_count] = "COUNT(DISTINCT #{self.provider.alias_start_table}.#{self.provider.resource_class.primary_key})"
      select_association_name_already_done = []
      self.provider.columns_to_select_meta_data.each do |column_meta_data|
        is_column_sorted = !self.provider.sorts.find { |sort| sort[:column_meta_data][:field_name] == column_meta_data[:field_name] }.nil?

        if column_meta_data[:association_name] != nil
          join_data = self.provider.joins_data[column_meta_data[:association_name]]
          if join_data.nil?
            next
          end

          if is_column_sorted
            sql_column_on = "#{join_data[:alias_label]}.#{column_meta_data[:raw_field_name]}"
            if join_data[:enabled_for_sub_request]
              column_select_on_sub_request_array << sql_column_on
            else
              column_select_on_array << sql_column_on
            end
          end
          
          if select_association_name_already_done.include?(column_meta_data[:association_name])
            next
          end

          mapped_columns = join_data[:columns_to_select].map do |column_to_select|
            "'#{column_to_select}', #{join_data[:alias_label]}.#{column_to_select}"
          end
          column_sql = """
            COALESCE(
              json_agg(
                DISTINCT jsonb_build_object(
                  #{mapped_columns.join(', ')}
                )
              )
            )::text as #{column_meta_data[:association_name]}
          """
          if join_data[:enabled_for_sub_request]
            column_select_sub_request_array << column_sql
          else
            column_select_array << column_sql
          end
          select_association_name_already_done << column_meta_data[:association_name]
        else
          if self.provider.sub_request_mode
            column_select_sub_request_array << "#{self.provider.alias_start_table_sub_request}.#{column_meta_data[:raw_field_name]}"
          else
            column_select_array << "#{self.provider.alias_start_table}.#{column_meta_data[:raw_field_name]}"
          end

          if is_column_sorted
            if self.provider.sub_request_mode
              column_select_on_sub_request_array << "#{self.provider.alias_start_table_sub_request}.#{column_meta_data[:raw_field_name]}"
            end
            column_select_on_array << "#{self.provider.alias_start_table}.#{column_meta_data[:raw_field_name]}"
          end

        end

      end
      if self.provider.sub_request_mode
        column_select_array.unshift "#{self.provider.alias_start_table}.*"
        if column_select_on_sub_request_array.empty?
          self.sql_string_hash[:sub_request_select_clause] = "SELECT"
        else
          self.sql_string_hash[:sub_request_select_clause] = "SELECT DISTINCT ON"
          self.sql_string_hash[:sub_request_select_on_columns] = "(#{column_select_on_sub_request_array.join(', ')})"
        end
        self.sql_string_hash[:sub_request_select_columns] = column_select_sub_request_array.join(', ')
        self.sql_string_hash[:sub_request_from] = "FROM #{self.provider.resource_class.table_name} AS #{self.provider.alias_start_table_sub_request}"
        self.sql_string_hash[:from] = "FROM ("
        self.sql_string_hash[:from_sub_request_as] = ") AS #{self.provider.alias_start_table}"
      else
        self.sql_string_hash[:from] = "FROM #{self.provider.resource_class.table_name} AS #{self.provider.alias_start_table}"
      end
      if column_select_on_array.empty?
        self.sql_string_hash[:select_clause] = "SELECT"
      else
        self.sql_string_hash[:select_clause] = "SELECT DISTINCT ON"
        self.sql_string_hash[:select_on_columns] = "(#{column_select_on_array.join(', ')})"
      end
      self.sql_string_hash[:select_columns] = column_select_array.join(', ')
      self.sql_string_hash[:from_count] = "FROM #{self.provider.resource_class.table_name} AS #{self.provider.alias_start_table}"
    end

    def build_joins_sql
      if self.provider.joins_data.empty?
        return
      end
      join_array = []
      join_sub_request_array = []
      join_count_array = []
      join_group_array = []
      self.provider.joins_data.each do |_join_key, join_value|
        join_value[:paths_to_join].each do |path_to_join|
          join_sql = """
            LEFT OUTER JOIN #{path_to_join[:foreign_table_name]}
            AS #{path_to_join[:foreign_table_alias]}
            ON #{path_to_join[:foreign_table_alias]}.#{path_to_join[:foreign_table_key]} = #{path_to_join[:primary_table_alias]}.#{path_to_join[:primary_table_key]}
          """
          if join_value[:enabled_for_sub_request]
            join_sub_request_array << join_sql
          else
            join_array << join_sql
          end
        end

        if join_value[:enabled_for_count] == true
          join_value[:paths_to_join_count].each do |path_to_join_count|
            join_sql = """
              LEFT OUTER JOIN #{path_to_join_count[:foreign_table_name]}
              AS #{path_to_join_count[:foreign_table_alias]}
              ON #{path_to_join_count[:foreign_table_alias]}.#{path_to_join_count[:foreign_table_key]} = #{path_to_join_count[:primary_table_alias]}.#{path_to_join_count[:primary_table_key]}
            """
            join_count_array << join_sql
          end
        end

        if join_value[:enabled_for_group] == true
          join_value[:paths_to_join_group].each do |path_to_join_count|
            join_sql = """
              LEFT OUTER JOIN #{path_to_join_count[:foreign_table_name]}
              AS #{path_to_join_count[:foreign_table_alias]}
              ON #{path_to_join_count[:foreign_table_alias]}.#{path_to_join_count[:foreign_table_key]} = #{path_to_join_count[:primary_table_alias]}.#{path_to_join_count[:primary_table_key]}
            """
            join_group_array << join_sql
          end
        end

      end
      self.sql_string_hash[:joins] = join_array.join(' ')
      self.sql_string_hash[:sub_request_joins] = join_sub_request_array.join(' ')
      self.sql_string_hash[:joins_count] = join_count_array.join(' ')
      self.sql_string_hash[:joins_group] = join_group_array.join(' ')
    end

    def build_where_filters_sql
      2.times do |index_time|
        where_fragments = []
        self.provider.filters.each do |filter_params|

          column_meta_data = filter_params[:column_meta_data]

          if !column_meta_data[:association_name].nil?
            join_data = self.provider.joins_data[column_meta_data[:association_name]]
            if join_data.nil?
              next
            end
            table_alias = join_data[:alias_label]
          else
            if index_time == 0
              if self.provider.sub_request_mode
                table_alias = self.provider.alias_start_table_sub_request
              else
                table_alias = self.provider.alias_start_table
              end
            else
              table_alias = self.provider.alias_start_table
            end
          end

          column_name = column_meta_data[:raw_field_name]
          fragments = []
          filter_params[:conditions].each do |condition|
            case condition[:type]

            when 'in'
                if condition[:filters].empty?
                  next
                end
                case column_meta_data[:field_type]
                  when :number
                    fragments << "#{table_alias}.#{column_name} IN (#{condition[:filters].join(', ')})"
                  else
                    fragments << "#{table_alias}.#{column_name} IN (#{condition[:filters].map{|filter| "'#{filter}'"}.join(', ')})"
                end

            when 'set'
                if condition[:values].empty?
                  next
                end
                case column_meta_data[:field_type]
                  when :number
                    fragments << "#{table_alias}.#{column_name} IN (#{condition[:values].join(', ')})"
                  else
                    fragments << "#{table_alias}.#{column_name} IN (#{condition[:values].map{|filter| "'#{filter}'"}.join(', ')})"
                end

            when 'contains'
                fragments << "#{table_alias}.#{column_name} ILIKE '%#{condition[:filter]}%'"

            when 'equals'
                case column_meta_data[:field_type]
                  when :number
                    if condition[:filter] == ""
                      fragments << "#{table_alias}.#{column_name} IS NULL"
                    else
                      fragments << "#{table_alias}.#{column_name} = #{condition[:filter]}"
                    end
                  when :date
                    fragments << "#{table_alias}.#{column_name}::date = '#{condition[:dateFrom]}'"
                  else
                    fragments << "#{table_alias}.#{column_name} = '#{condition[:filter]}'"
                end


            when 'notEqual'
                case column_meta_data[:field_type]
                  when :number
                    if condition[:filter] == ""
                      fragments << "#{table_alias}.#{column_name} IS NOT NULL"
                    else
                      fragments << "#{table_alias}.#{column_name} != #{condition[:filter]}"
                    end
                  when :date
                    fragments << "#{table_alias}.#{column_name}::date != '#{condition[:dateFrom]}'"
                  else
                    fragments << "#{table_alias}.#{column_name} != '#{condition[:filter]}'"
                end


            when 'notContains'
                fragments << "#{table_alias}.#{column_name} NOT ILIKE '%#{condition[:filter]}%'"

            when 'empty'
                fragments << "#{table_alias}.#{column_name} IS NULL"

            when 'blank'
                fragments << "#{table_alias}.#{column_name} IS NULL"

            when 'notEmpty'
                fragments << "#{table_alias}.#{column_name} IS NOT NULL"

            when 'greaterThan'
                case column_meta_data[:field_type]
                  when :number
                    fragments << "#{table_alias}.#{column_name} > #{condition[:filter]}"
                  when :date
                    fragments << "#{table_alias}.#{column_name} > '#{condition[:dateFrom]}'"
                else
                  nil
                end

            when 'lessThan'
                case column_meta_data[:field_type]
                  when :number
                    fragments << "#{table_alias}.#{column_name} < #{condition[:filter]}"
                  when :date
                    fragments << "#{table_alias}.#{column_name} < '#{condition[:dateFrom]}'"
                else
                  nil
                end


            when 'inRange'
              case column_meta_data[:field_type]
              when :number
                    fragments << "#{table_alias}.#{column_name} BETWEEN #{condition[:filter]} AND #{condition[:filterTo]}"
              when :date
                    fragments << "#{table_alias}.#{column_name} BETWEEN '#{condition[:dateFrom]}' AND '#{condition[:dateTo]}'"
              else
                nil
              end
            else
              nil
            end
          end
          if filter_params[:operator] == 'OR'
            where_fragments << fragments.join(' OR ')
          end
          if filter_params[:operator] == 'AND'
            where_fragments << fragments.join(' AND ')
          end
        end

        where_sql = where_fragments.each_with_index.reduce("") do |acc, (where_fragment, index)|
          if index == 0
            acc += "(#{where_fragment})"
          else
            acc += "AND (#{where_fragment})"
          end
        end
        if where_sql.empty?
          return
        end
        where_sql = "WHERE #{where_sql}"
        if index_time == 0
          if self.provider.sub_request_mode
            self.sql_string_hash[:sub_request_where] = where_sql
          else
            if self.provider.group_mode_data.nil?
              self.sql_string_hash[:where] = where_sql
            else
              self.sql_string_hash[:where_group] = where_sql
            end
          end
        else
          self.sql_string_hash[:where_count] = where_sql
        end
      end
    end

    def build_groups_sql
      if self.provider.group_mode_data
        self.sql_string_hash[:groups_group] = "GROUP BY #{self.provider.group_mode_data[:group_column_table_alias]}.#{self.provider.group_mode_data[:group_column_metadata][:raw_field_name]}"
        return
      end
      group_columns = []
      group_columns_sub_request = []
      select_association_name_already_done = []
      request_has_join = false
      sub_request_has_join = false
      self.provider.columns_to_select_meta_data.each do |column_meta_data|

        if column_meta_data[:association_name] != nil
          join_data = self.provider.joins_data[column_meta_data[:association_name]]
          if join_data.nil?
            next
          end

          if !join_data[:enabled_for_sub_request]
            request_has_join = true
            next
          end

          column_is_sorted = !self.provider.sorts.find { |sort| sort[:column_meta_data][:field_name] == column_meta_data[:field_name]}.nil?
          if column_is_sorted
            group_columns_sub_request << "#{join_data[:alias_label]}.#{column_meta_data[:raw_field_name]}"
          end

          if select_association_name_already_done.include?(column_meta_data[:association_name])
            next
          end

          sub_request_has_join = true
          group_columns << "#{self.provider.alias_start_table}.#{column_meta_data[:association_name]}"
          select_association_name_already_done << column_meta_data[:association_name]
        else
          if self.provider.sub_request_mode
            group_columns_sub_request << "#{self.provider.alias_start_table_sub_request}.#{column_meta_data[:raw_field_name]}"
          end
          group_columns << "#{self.provider.alias_start_table}.#{column_meta_data[:raw_field_name]}"
        end

      end
      sql_group_columns = group_columns.join(', ')
      sql_group_columns_sub_request = group_columns_sub_request.join(', ')
      if self.provider.sub_request_mode
        if !sql_group_columns_sub_request.empty? && sub_request_has_join
          self.sql_string_hash[:sub_request_groups] = "GROUP BY #{sql_group_columns_sub_request}"
        end
      end
      if !sql_group_columns.empty? && (request_has_join || sub_request_has_join)
        self.sql_string_hash[:groups] = "GROUP BY #{sql_group_columns}"
      end
    end

    def build_sort_sql
      sort_clauses_array = []
      sort_clauses_sub_request_array = []
      self.provider.sorts.each do |sort|
        column_meta_data = sort[:column_meta_data]
        column_name = column_meta_data[:raw_field_name]

        if column_meta_data[:association_name] != nil
          join_data = self.provider.joins_data[column_meta_data[:association_name]]
          if join_data.nil?
            next
          end
          table_alias_sub_request = join_data[:alias_label]
          sort_clauses_sub_request_array << "#{table_alias_sub_request}.#{column_name} #{sort[:sort]}"
          if !join_data[:enabled_for_sub_request]
            sort_clauses_array << "#{table_alias_sub_request}.#{column_name} #{sort[:sort]}" # ???
          end
        else
          if self.provider.sub_request_mode
            table_alias_sub_request = self.provider.alias_start_table_sub_request
            sort_clauses_sub_request_array << "#{table_alias_sub_request}.#{column_name} #{sort[:sort]}"
          end
          table_alias = self.provider.alias_start_table
          sort_clauses_array << "#{table_alias}.#{column_name} #{sort[:sort]}"
        end
        
      end

      sort_sql = sort_clauses_array.join(', ')
      if sort_sql.length > 0
        sort_sql = "ORDER BY #{sort_sql}"
      end
      sort_sub_request_sql = sort_clauses_sub_request_array.join(', ')
      if sort_sub_request_sql.length > 0
        sort_sub_request_sql = "ORDER BY #{sort_sub_request_sql}"
      end
      if self.provider.sub_request_mode
        self.sql_string_hash[:sub_request_sorts] = sort_sub_request_sql
      end
      if self.provider.group_mode_data.nil?
        self.sql_string_hash[:sorts] = sort_sql
      else
        self.sql_string_hash[:sorts_group] = sort_sql
      end
    end

    def build_limit_and_offset_sql
      limit_offset_sql = "LIMIT #{self.provider.limit} OFFSET #{self.provider.offset}"
      if self.provider.sub_request_mode
        self.sql_string_hash[:sub_request_limit_offset] = limit_offset_sql
      else
        self.sql_string_hash[:limit_offset] = limit_offset_sql
      end
    end

    def get_results
      length = 0

      if self.shall_return_count
        length_sql = """
          #{self.sql_string_hash[:select_clause_count]}
          #{self.sql_string_hash[:select_count]}
          #{self.sql_string_hash[:from_count]}
          #{self.sql_string_hash[:joins_count]}
          #{self.sql_string_hash[:where_count]}
          #{self.sql_string_hash[:additional_clause]}
        """
        length = self.provider.resource_class.connection.execute(length_sql).to_a.first["count"]
      end

      if self.provider.group_mode_data
        items_sql = """
        #{self.sql_string_hash[:select_group_clause]}
        #{self.sql_string_hash[:select_group_columns]}
        #{self.sql_string_hash[:from_group]}
        #{self.sql_string_hash[:joins_group]}
        #{self.sql_string_hash[:where_group]}
        #{self.sql_string_hash[:groups_group]}
        #{self.sql_string_hash[:sorts_group]}
        #{self.sql_string_hash[:limit_offset]}
        #{self.sql_string_hash[:additional_clause]}
      """
      items = self.provider.resource_class.connection.execute(items_sql).to_a
        resource_name = self.provider.group_mode_data[:group_column_table_name]
        column_name = self.provider.group_mode_data[:group_column_metadata][:raw_field_name]
        group_segment_string = self.provider.group_mode_data[:group_segment_string]
        items = items.map.with_index do |row, row_index|
          value = row[column_name].to_s
          {
            id: -1,
            __id: "#{resource_name}/#{group_segment_string}/#{value}/#{self.provider.offset + row_index}",
            __group_key: value,
            __label: value,
            __childCount: row["count"],
            column_name => value,
          }
        end
        return { items: items, length: length }
      end
      items_sql = """
        #{self.sql_string_hash[:select_clause]}
        #{self.sql_string_hash[:select_on_columns]}
        #{self.sql_string_hash[:select_columns]}
        #{self.sql_string_hash[:from]}
        #{self.sql_string_hash[:sub_request_select_clause]}
        #{self.sql_string_hash[:sub_request_select_on_columns]}
        #{self.sql_string_hash[:sub_request_select_columns]}
        #{self.sql_string_hash[:sub_request_from]}
        #{self.sql_string_hash[:sub_request_joins]}
        #{self.sql_string_hash[:sub_request_where]}
        #{self.sql_string_hash[:sub_request_groups]}
        #{self.sql_string_hash[:sub_request_sorts]}
        #{self.sql_string_hash[:sub_request_limit_offset]}
        #{self.sql_string_hash[:from_sub_request_as]}
        #{self.sql_string_hash[:joins]}
        #{self.sql_string_hash[:where]}
        #{self.sql_string_hash[:groups]}
        #{self.sql_string_hash[:sorts]}
        #{self.sql_string_hash[:limit_offset]}
        #{self.sql_string_hash[:additional_clause]}
      """
      items = self.provider.resource_class.connection.execute(items_sql).to_a
      { items: items, length: length }
    end

    private
    def initialize(query64_params)
      params = params.to_h
      self.sql_string_hash = {
        additional_clause: ";"
      }
      self.shall_return_count = query64_params[:shallReturnCount] || false
      self.provider = Provider.new(query64_params)
    end

  end
end
