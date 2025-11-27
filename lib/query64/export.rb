require 'csv'

module Query64
  class Export
    
    def self.get_data(data_rows, query64_params, format = :csv)
      case format
        when :csv
          if data_rows.count == 0
            return ""
          end

          csv_content = CSV.generate(headers: true, col_sep: ';') do |csv|
            header_row = data_rows.first.keys
            csv << header_row

            data_rows.each do |data_row|
              row = data_row.values
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