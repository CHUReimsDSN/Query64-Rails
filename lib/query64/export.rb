require 'csv'

module Query64
  class Export
    
    def self.get_data(data_rows, query64_params, format = :csv)
      case format
        when :csv
          if data_rows.count == 0
            return ""
          end

          json_key_column = {}
          json_key_association = Set.new
          query64_params[:columnsToDisplay].each do |column_to_display|
            if column_to_display.exclude?('.')
              next
            end
            association_name = column_to_display.split('.')[0] || ''
            json_key_association.add(association_name)
            if (json_key_column[association_name.to_sym].nil?)
              json_key_column[association_name.to_sym] = []
            end
            json_key_column[association_name.to_sym] << (column_to_display.split('.')[1] || '')
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
                json_assoc = json_key_association.find(entry[0])
                if json_assoc
                  json_key_column[json_assoc.to_sym].each do |json_col_name|
                    row << entry[1][json_col_name]
                  end
                else
                  row << entry[1]
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