class Article < ApplicationRecord
    extend Query64::MetadataProvider

    has_many :comments
    belongs_to :user

    def self.query64_column_builder
    [
      {
        columns_to_include: ['*'],
        statement: -> { true }
      }
    ]
    end

end
