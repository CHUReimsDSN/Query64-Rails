class Comment < ApplicationRecord
    extend Query64::MetadataProvider

    belongs_to :user
    belongs_to :article

end
