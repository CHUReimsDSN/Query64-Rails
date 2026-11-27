require 'csv'

module Query64
  class Export
    
    def self.get_data(data_rows, query64_params, resource_class, opt)
      if data_rows.count == 0
        return data_rows
      end

      opt[:format] ||= :csv
      opt[:use_dictionary] ||= true

      formater_by_type = {
        date: opt[:format_date],
        datetime: opt[:format_datetime],
        boolean: opt[:format_boolean],
        string: opt[:format_string],
        number: opt[:format_number],
      }

      case opt[:format]
        when :csv
          json_key_column = {}
          header_row = []
          rows = []
          json_key_association = Set.new
          column_metadata = resource_class.query64_get_all_metadata
          columns_to_display = query64_params[:columnsToDisplay] || []
          columns_to_display.each do |column_to_display|
            if column_to_display.exclude?('.')
              next
            end
            association_name = column_to_display.split('.')[0] || ''
            json_key_association.add(association_name)
            if json_key_column[association_name.to_sym].nil?
              json_key_column[association_name.to_sym] = []
            end
            json_key_column[association_name.to_sym] << (column_to_display.split('.')[1] || '')
          end

          csv_content = CSV.generate(headers: true, col_sep: ';') do |csv|

            # Header
            data_rows.first.keys.each do |key|
              if json_key_association.exclude?(key)
                header_row << key
              else
                json_assoc = json_key_association.find do |entry_set|
                  entry_set == key
                end
                if json_assoc
                  json_key_column[json_assoc.to_sym].each do |json_col_name|
                    header_row << "#{key}.#{json_col_name}"
                  end
                end
              end
            end

            # Rows
            data_rows.each do |data_row|
              row = []
              data_row.each do |entry|
                json_assoc = json_key_association.find do |entry_set|
                  entry_set == entry[0]
                end
                if json_assoc
                  json_key_column[json_assoc.to_sym].each do |json_col_name|
                    row << JSON.parse(entry[1]).map do |json_array_entry|
                      json_array_entry[json_col_name] || ""
                    end.join(",")
                  end
                else
                  row << entry[1] || ""
                end
              end

              rows << row
            end

            # Format everything by opt
            header_row.each_with_index do |header_entry, header_index|
              if query64_params[:columnsToDisplay].exclude?(header_entry)
                header_row.delete_at(header_index)
                rows.each do |row|
                  row.delete_at(header_index)
                end
                next
              end
              metadata = column_metadata.find do |meta|
                meta[:field_name] == header_entry
              end
              if metadata.nil?
                next
              end
              formatter = formater_by_type[metadata[:field_type]]
              if formatter != nil
                rows.each do |row|
                  row[header_index] = formatter.call(row[header_index])
                end
              end
              if opt[:use_dictionary]
                header_row[header_index] = metadata[:label_name]
              end
            end

            csv << header_row
            rows.each do |row|
              csv << row
            end

          end
          return csv_content

        when :raw
          return data_rows
      end
    end

  end

end
