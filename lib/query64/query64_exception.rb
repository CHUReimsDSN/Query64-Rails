module Query64
  
  class Query64Exception < StandardError
    attr_accessor :http_status

    def initialize(message, http_status)
      super("Query64Exception -> #{message}")
      self.http_status = http_status
    end

  end

end
