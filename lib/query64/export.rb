module Query64
  class Export
    
    def self.get_data(data_rows, query64_params, format = :grid_like)
      case format
        when :grid_like
          json_keys_to_parse = Set.new
          query64_params[:columnsToDisplay].each do |column_to_display|
            if column_to_display.include?('.')
              next
            end
            json_keys_to_parse.add(column_to_display.split('.')[0] || '')
          end
          return data_rows.map do |data_row|
            json_keys_to_parse.each do |json_key|
              data_row[json_key] = JSON.parse(data_row[json_key])
            end
            data_row
          end

        when :json
          return data_rows
      end
    end

  end

end