module Query64
  @current_user = nil

  class << self
    attr_accessor :current_user
  end
end
