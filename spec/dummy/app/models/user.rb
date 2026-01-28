class User < ApplicationRecord
    extend Query64::MetadataProvider

    has_many :articles
    has_many :comments

end
