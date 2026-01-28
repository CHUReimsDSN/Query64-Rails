require 'csv'

module Query64
  class Export
    
    def self.get_data(data_rows, query64_params, format)
      if data_rows.count == 0
        return data_rows
      end

      case format
        when :csv
          json_key_column = {}
          json_key_association = Set.new
          columns_to_display = query64_params[:columnsToDisplay] || []
          columns_to_display.each do |column_to_display|
            if column_to_display.exclude?('.')
              next
            end
            association_name = column_to_display.split('.')[0] || ''
            json_key_association.add(association_name)
            if (json_key_column[association_name.to_sym].nil?)
              json_key_column[association_name.to_sym] = []
            end
            json_key_column[association_name.to_sym] << (column_to_display.split('.')[1].split('::')[0] || '')
          end

          csv_content = CSV.generate(headers: true, col_sep: ';') do |csv|
            header_row = data_rows.first.keys.filter do |key|
              json_key_association.exclude?(key)
            end
            json_key_column.entries.each do |entry|
              entry[1].each do |json_col_name|
                header_row << "#{entry[0]} : #{json_col_name}"
              end
            end
            csv << header_row

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